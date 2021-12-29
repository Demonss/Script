#!/bin/sh
unset PID_IOtest
PID_IOtest=$(ps -ef |grep IOTest|grep -v "grep"|awk '{ print $2 }'|tr '\n' ' ')
echo "Shell PID is $$"
for curpid in $PID_IOtest
do
  vvlue=$[ $curpid - $$ ] 
  if [[ $vvlue -ne 1 ]] && [[ $vvlue -ne 0 ]]; then
    echo "Find Pre PID: $curpid try to  kill......"
    kill $curpid
    brun=1
  fi
done
if [[ -z $brun ]];then
  echo "Starting IO test ..........."
  for (( ; ; ))
  do   
    ffff=$((LANG=C dd if=/dev/zero of=/root/benchtest bs=4k count=512 conv=fdatasync && rm -f /root/benchtest ) 2>&1 | awk -F, 'END { print $NF }')  
    echo $(date '+%Y/%m/%d %H:%M:%S') $ffff >>/root/io_test
    sleep 10s
  done
fi