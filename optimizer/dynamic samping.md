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
