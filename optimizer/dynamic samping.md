The goal of a query optimizer is to generate the best execution plan for a SQL statement. The best execution plan is defined as the plan with the lowest cost among all considered candidate
plans. The cost computation accounts for factors of the query execution such as IO, CPU, and communication. 

The cost model consists of several cost functions one for each access path, join method, etc. 
One of the common inputs to all cost functions is the number of rows processed by a given operation. 
The number of rows processed can either be the number of rows from the table statistics as collected by DBMS_STATS or 
derived after accounting for effects from predicates (filter, join, etc), distinct or group-by operations, etc.
