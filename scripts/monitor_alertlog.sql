set linesize 300 pagesize 2000
col message_text for a200
select originating_timestamp ,message_text 
    from X$DBGALERTEXT
	where originating_timestamp between to_date('2020-03-01 00:00:00','YYYY-MM-DD hh24:mi:ss') and to_date('2020-04-01 00:00:00','YYYY-MM-DD hh24:mi:ss')
	and message_text like '%ORA-%'
	and message_text not like '%ORA-16055%'
	and message_text not like '%ORA-16038%'
	and  message_text not like '%ORA-01555%'
    and message_text not like '%ORA-12609%';
