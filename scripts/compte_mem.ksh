#!/bin/ksh
# AC 13/06/27

# Whole Server
#+-+-+-+-+-+-+

print "\n** overall **"
# Total Real memory & Free memory
echo "Free Mem: $(vmstat -v | grep free | awk '{ print $1*4096/1024/1024 }') MB out of Total Memory: $(vmstat -v | grep 'memory pages' | awk '{ print $1*4096/1024/1024 }') MB"

print "\n** Applications Programs **"
# Shared Segments ( ipc )
S1=$( ipcs -am|awk '$1 !~ /^#/ && $1 ~ "m" { S +=$10 }; END { print S/1024/1024 }' )
print "Shared Segments ${S1} MB"

# Binaries
S2=$( for i in $( ps -ef | egrep -v "grep|UID" | awk '{ print $2 }' ) ; do ps v ${i} | tail -1 | grep -v SIZE | awk '{ print $9 }'; done | sort -n | uniq | awk 'BEGIN { S=0 } { S+=$1 }; END { print S/1024 }' )
print "Shared Code binaries ${S2} MB"

# Private Data
#for i in $( ps -ef | egrep -v "grep|UID" | awk '{ print $2 }' ) ; do svmon -P ${i} | grep 'work text data BSS heap' | awk '{ print $9 }'; done | awk 'BEGIN { S=0 } { S+=$1 }; END { print "Private Mem "S*4/1024" MB" }'
P=$( for i in $( ps -ef | egrep -v "grep|UID" | awk '{ print $2 }' ) ; do ps v ${i} | grep -v PID | awk '{ print $7" "$10 }'; done | awk 'BEGIN { S=0 } { S+=$1-$2 }; END { print S/1024 }' )
print "Private Mem ${P} MB"

print "\n** System : Kernel + FS Cache **"
# KERNEL + APPLICATION PROGRAMS
KA=$(svmon -G | grep 'in use' | awk '{ print ($3)*4096/1024/1024 }')
(( K = KA-S1-S2-P ))
echo "Kernel = ${K} MB"

# FILESYSTEM CACHE
echo "Cache FS: $(svmon -G | grep 'in use' | awk '{ print ($4+$5)*4096/1024/1024 }') MB"

print "\n** overall again **"
# Total Real memory & Free memory
echo "Free Mem: $(vmstat -v | grep free | awk '{ print $1*4096/1024/1024 }') MB out of Total Memory: $(vmstat -v | grep 'memory pages' | awk '{ print $1*4096/1024/1024 }') MB"
