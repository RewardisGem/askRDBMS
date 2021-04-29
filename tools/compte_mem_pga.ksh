#!/bin/ksh

for i in INSTORA1 INSTORA2 INSTORA3 INSTORA4 ; do

echo $i
cnt_ps=$( ps -ef | grep -v grep | grep -ic $i ) ; pv_mm=$( for i in $( ps -ef | grep -i $i |egrep -v "grep|UID" | awk '{ print $2 }' ) ; do ps v ${i} | grep -v PID | awk '{ print $7" "$10 }'; done | awk 'BEGIN { S=0 } { S+=$1-$2 }; END { print S/1024 }' ) ; (( pv_ps=pv_mm/cnt_ps )) ; print "${cnt_ps} processes ; Private Mem = ${pv_mm} MB ; ${pv_ps} MB per process"

cnt_ps=$( ps -ef | grep -v grep | grep -ic "$i (LOCAL=NO)" ) ; pv_mm=$( for i in $( ps -ef | grep -i "$i (LOCAL=NO)" |egrep -v "grep|UID" | awk '{ print $2 }' ) ; do ps v ${i} | grep -v PID | awk '{ print $7" "$10 }'; done | awk 'BEGIN { S=0 } { S+=$1-$2 }; END { print S/1024 }' )
if (( cnt_ps != 0 )) ; then
(( pv_ps=pv_mm/cnt_ps )) ; print "${cnt_ps} Dedicated processes ; Private Mem Dedicated = ${pv_mm} MB ; ${pv_ps} MB per process"
else print "${cnt_ps} Dedicated processes"
fi

cnt_ps=$( ps -ef | grep -v grep | grep -ic "ora_.*_$i" ) ; pv_mm=$( for i in $( ps -ef | grep -i "ora_.*_$i" |egrep -v "grep|UID" | awk '{ print $2 }' ) ; do ps v ${i} | grep -v PID | awk '{ print $7" "$10 }'; done | awk 'BEGIN { S=0 } { S+=$1-$2 }; END { print S/1024 }' )
if (( cnt_ps != 0 )) ; then
(( pv_ps=pv_mm/cnt_ps )) ; print "${cnt_ps} Background processes ; Private Mem Background = ${pv_mm} MB ; ${pv_ps} MB per process"
else print "${cnt_ps} Background processes"
fi

done
