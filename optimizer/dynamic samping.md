# Goal

The goal of a query optimizer is to generate the best execution plan for a SQL statement. The best execution plan is defined as the plan with the lowest cost among all considered candidate
plans. The cost computation accounts for factors of the query execution such as IO, CPU, and communication. 

The cost model consists of several cost functions one for each access path, join method, etc. 
One of the common inputs to all cost functions is the number of rows processed by a given operation. 
The number of rows processed can either be the number of rows from the table statistics as collected by DBMS_STATS or 
derived after accounting for effects from predicates (filter, join, etc), distinct or group-by operations, etc.

# Estimating Cardinality

Deriving or estimating the number of rows is one of thorniest subjects in query optimization. It is the Achilles heel of every query optimizer. The formula used to estimate the number of rows based on predicates easily breaks when the predicates involve skewed columns, expressions on columns, or complex predicates connected using AND/OR operations. 

Over time, sophisticated statistics were added to account for skew (histograms) and correlation (extended statistics). 

However, using pre-computed statistics have limitations that cannot be ignored. For example, extended statistics are limited to predicates where only an equality operator is used. Furthermore there will always be query expressions that cannot be represented
as first class statistics and that will be available during the optimization of the SQL statement.


An alternative solution to using pre-computed statistics is dynamic statistics. This technique consists in computing the statistics ( selectivity , cardinality, or first class statistics) during the optimization of the SQL statement. The statistics are computed by executing a SQL statement (let’s call it a statistics query) against the table with and without query predicates. 

Some implementations limit the application of the technique to single tables only while others apply it for joins and group by. To limit the overhead on the compilation time of the SQL statement data sampling is used to fetch a few rows from the table(s) involved in the statistics query, hence the commonly used name of dynamic sampling. 

The sample size or percent can be computed based on a given count of the blocks relative to the table block count or based on a time limit.The technique has been discussed in several research papers. The dynamic sampling was first introduced in Oracle 9i Release 2 , and is used to estimate the selectivity of filter table predicates and the number of distinct values of join columns if the table does not have statistics. 

A second implementation of dynamic sampling was introduced in Oracle 10g Release 1 to support SQL Profiling, a technique used in SQL Tune . The latter is more generic, e.g., it supports joins. 

The choice was deliberate to design a newer version of dynamic sampling because of the complexity and quality issues known in the older implementation. Another justification was also that the old version will become obsolete after we switch to using the newer version.


# Stale Statistics

Even when all the statistics including histograms and extended statistics are available they may lead the optimizer to generate a bad execution plan because the statistics are stale, i.e. the statistics on a table do not accurately reflect the table data. The auto statistics job was introduced

in Oracle 10g Release 1  to run daily and gather statistics of tables that do not have statistics or whose statistics are stale. The auto statistics is very effective for what it has been designed: it is acceptable to wait 24 hours to refresh statistics. However, we have seen situations where statistics become stale in a very short time period after they have been gathering to the point that using the execution plan built on stale statistics is very inefficient. For example, consider a table used to store a company’s sales data including the sales date. After new rows are inserted the maximum statistics on the sales date column becomes stale since all new rows have a higher sales date than the maximum value seen during the last statistics gathering. For any query that fetches the most recently added sales data the query optimizer will think that there are very few or no rows returned by the access to the sales table leading to the selection of a bad access path to the sales table (typically the index on the sales date column), a bad join method (typically a cartesian product) or join orders (sales table is a leading table). This is commonly known as the “out-of-range” condition: the value specified in the predicate on the sales date column is outside the column statistics value domain.


# Density of Frequency Histograms

A frequency histogram is built during statistics gathering when the number of distinct values is less than the supported maximum number of buckets (254). The selectivity estimate of equality predicates using frequency histograms is usually of very good quality except when the value specified in the predicate is not found in the histogram. This can happen for two reasons: the value appears in very few rows (low frequency) or the histogram is stale. For both cases the optimizer uses density as selectivity for equality predicates involving theses values. The density is computed as half the lowest frequency in the histogram.


## Non popular value

Histograms are gathered based on a smallsample (usually 5500 rows) therefore values that have a low frequency are unlikely to be seen in the sample. Using density in this case is likely to cause an over-estimate in the selectivity and leads to a bad execution plan. The project “New Histogram Types” (31794) [NHT_12gR1_DS] planned for Oracle 12g Release 1 will mostly resolve this issue by building frequency histograms during the same pass we gather basic statistics and where we use all the table rows.

## Stale Histogram

Even when a frequency histogram is built on all the table rows the histogram can become stale following DMLs on the table. This can either cause the histogram frequencies to be out of sync with the actual frequencies or a new value not being captured in the histogram.


# Dynamic Sampling in the Optimizer
## Overview

Dynamic sampling (DS) was introduced in Oracle 9i Release 2 to improve the optimizer's ability to generate good execution plans. 

The most common misconception is that DS can be used as a substitute for optimizer statistics. 

The goal of DS is to augment the optimizer statistics; it is used when regular statistics are not sufficient to get good quality cardinality estimates. During the compilation of a SQL statement, the optimizer decides whether and how to use DS by considering whether the available statistics are sufficient to generate a good execution plan. If the available statistics are not sufficient, dynamic sampling will be used. It is typically used to compensate for missing or insufficient statistics that would otherwise lead to a very bad plan.

For the case where one or more of the tables in the query does not have statistics, DS is used by the optimizer to gather basic statistics on these tables before optimizing the statement. The statistics gathered in this case are not as high a quality or as complete as the statistics gathered using the DBMS_STATS package. This trade off is made to limit the impact on the parse time of the SQL statement. The statistics gathered by DS include the number of blocks and the number of rows of the table, and the number of nulls and the number of distinct values of the columns used in the join predicates. It is also used to estimate the selectivity of the filter predicates.


Another scenario where DS is used is when the statement contains a complex predicate expression and extended statistics are not available. Extended statistics were introduced in Oracle Database 11g Release 1 with the goal to help the optimizer get good quality cardinality estimates for complex predicate expressions. Extended statistics allows optimizer statistics to capture correlation between columns and deal with expressions on columns. 

```sql
SELECT *
FROM customers
WHERE cust_city='Los Angeles'
AND cust_state_province='CA'
-----------------------------------------------
|Id |Operation |Name |Rows |
-----------------------------------------------
| 0|SELECTSTATEMENT | | 1|
| 1| TABLEACCESSFULL|CUSTOMERS| 1|
-----------------------------------------------
PredicateInformation(identified byoperationid):
---------------------------------------------------
1- filter("CUST_CITY"='LosAngeles'AND"CUST_STATE_PROVINCE"='CA')
```



In the above execution plan the optimizer estimates the number of rows as 1 but the actual number of rows returned by the scan of the CUSTOMERS table is 13. The execution plan when dynamic sampling is used (see below) shows that the number of rows changed to 13, the correct number:


```sql
-----------------------------------------------
|Id |Operation |Name |Rows |
-----------------------------------------------
| 0|SELECTSTATEMENT | | 13|
| 1| TABLEACCESSFULL|CUSTOMERS| 13|
-----------------------------------------------
PredicateInformation(identified byoperationid):
---------------------------------------------------
1- filter("CUST_CITY"='LosAngeles'AND"CUST_STATE_PROVINCE"='CA')
Note
-----The shape of predicates in the SQL statement
-dynamicsamplingusedforthisstatement(level=4)
```sql



During the compilation of a SQL statement, the optimizer decides whether to use DS and how by considering the following factors


* Availability of optimizer statistics on the tables referenced in the SQL statement
* The shape of predicates in the SQL statement
* The value of the DYNAMIC_SAMPLING hint, if any
* The value of the OPTIMIZER_DYNAMIC_SAMPLING parameter







