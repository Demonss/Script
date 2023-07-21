#!/bin/bash

#保存备份个数，备份31天数据
number=31
#备份保存路径
backup_dir=/root/mysql_backup
#日期
dd=`date +%Y-%m-%d-%H-%M-%S`
dumpdate=$(date '+%Y%m%d-%H%M%S')
#备份工具
tool=mysqldump
#用户名
username=root
#密码
password=$1
#将要备份的数据库
database_name=$2

if  [  $#  -lt 2 ];then
  echo "too few params"
  exit 1
fi

#如果文件夹不存在则创建
if [ ! -d $backup_dir ]; 
then     
  mkdir -p $backup_dir; 
fi

#简单写法  mysqldump -u root -p123456 users > /root/mysqlbackup/users-$filename.sql
$tool -u $username -p${password} -e "${database_name}" > $backup_dir/${database_name}_${dumpdate}.sql
#sshpass -p "passwd" scp -P port  $backup_dir/${database_name}_${dumpdate}.sql  root@IP:/root/backup/
    
#mysqldump -uroot -p${PASSWDROOT} -e "${database_name}">~/${database_name}_${dumpdate}.sql

#写创建备份日志
echo "create $backup_dir/$database_name-$dd.dupm" >> $backup_dir/log.txt

#找出需要删除的备份
delfile=`ls -l -crt  $backup_dir/*.sql | awk '{print $9 }' | head -1`

#判断现在的备份数量是否大于$number
count=`ls -l -crt  $backup_dir/*.sql | awk '{print $9 }' | wc -l`

if [ $count -gt $number ]
then
  #删除最早生成的备份，只保留number数量的备份
  rm $delfile
  #写删除文件日志
  echo "delete $delfile" >> $backup_dir/log.txt
fi
