
# Read Consistency: Key Terms 
* Some key definitions are required to understand the internals of read consistency.
* Current Block: Most recent version of a block in buffer cache. 
* CR Block: Consistent version of a block that contains only committed changes at a particular SCN.
* Snap_SCN: Snapshot SCN. This is the SCN of the reference block or SCN from a particular point in time which is needed to build a read consistent snapshot of a block. 
* Snap_UBA: UBA appearing in the ITL of the snapshot block.
* Env_SCN: Environment SCN. The current SCN on the database. Sometimes this is simply called the current SCN.
* Env_UBA: Environment UBA. UBA of the current transaction.


