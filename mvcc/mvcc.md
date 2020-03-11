
# Read Consistency: Key Terms 
* Some key definitions are required to understand the internals of read consistency.
* Current Block: Most recent version of a block in buffer cache. 
* CR Block: Consistent version of a block that contains only committed changes at a particular SCN.
* Snap_SCN: Snapshot SCN. This is the SCN of the reference block or SCN from a particular point in time which is needed to build a read consistent snapshot of a block. 
* Snap_UBA: UBA appearing in the ITL of the snapshot block.
* Env_SCN: Environment SCN. The current SCN on the database. Sometimes this is simply called the current SCN.
* Env_UBA: Environment UBA. UBA of the current transaction.


The following fields belong to the kcbcr structure that is associated with each buffer in cache. They can be accessed via X$BH.

* CR_SCN:	SCN for the block in the buffer
* CR_XID: 	ID of the transaction that constructed this CR 			version of the block
* CR_UBA: 	UBA associated with the transaction indicated by 		CR_XID
* CR_SFL: 	snapshot flag


* Provides the “Read Committed” isolation level
* Two possible levels for read consistency:
  * Statement: The data returned by a query is consistent with respect to the start of the query (Snap_SCN = Current SCN at the time the query started its execute phase). 
  * Transaction: Data returned by a query is consistent with respect to the beginning of the transaction (Snap_SCN = Current SCN at the time the transaction started).


A block is accessed in CR (consistent read) mode when the transaction does not intend to change the block.
For a session S, only transactions committed by other sessions before Snap_SCN are visible. 
S can also see uncommitted changes done by itself.
To ensure read consistency, the Oracle server uses:
* A multiversion consistency model (at block level)
* Undo segments to generate consistent blocks (snapshots)




# Consistency Read Example

T1 commits at SCN 30.

T2 commits at SCN 31.

T3 executes a select that requires seeing the data before or equal to SCN 30 and its own changes done before the SELECT.
It is assumed, in the example, that the best version of block B1 in the cache is the current version of B1. All the changes not visible to T3 need to be rolled back. This is a matter of rolling back the two updates performed by T2 because at the time the T3 started, T2 had not committed yet.

