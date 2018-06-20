#!/bin/bash

source /pgenv.sh

#echo "Running with these environment options" >> /var/log/cron.log
#set | grep PG >> /var/log/cron.log

MYDATE=`date +%Y-%B-%d-%H`
MONTH=$(date +%B)
YEAR=$(date +%Y)
MYBASEDIR=/var/backup
MYBACKUPDIR=${MYBASEDIR}/${YEAR}/${MONTH}
mkdir -p ${MYBACKUPDIR}
cd ${MYBACKUPDIR}

echo "Backup running to $MYBACKUPDIR"

#
# Loop through each pg database backing it up
#

DBLIST=`psql -l | awk '{print $1}' | grep -v "+" | grep -v "Name" | grep -v "List" | grep -v "(" | grep -v "template" | grep -v "postgres" | grep -v "|" | grep -v ":"`
# echo "Databases to backup: ${DBLIST}" >> /var/log/cron.log
for DB in ${DBLIST}
do
  echo "Backing up $DB"
  FILENAME=${MYBACKUPDIR}/${DUMPPREFIX}_${DB}.${MYDATE}.tar
  ACTION="Create $FILENAME in /backup"
  pg_dump -Ft -C -f ${FILENAME} -O ${DB} && gzip -f ${FILENAME}
  if [ $? -eq 0 ]; then
     echo "OK: " $ACTION " - " $(date)
  else
     echo "FAIL: " $ACTION " - " $(date)
  fi
  if [ -n "${DRIVE_DESTINATION}" ]; then
    ACTION="Copy $FILENAME to destination"
    /go/bin/rclone $RCLONE_OPTS copy $FILENAME.gz $DRIVE_DESTINATION --retries 100 --retries-sleep 60s --user-agent "ISV|rclone.org|rclone/v1.42"
    if [ $? -eq 0 ]; then
      echo "OK: " $ACTION " - " $(date)
    else
      echo "FAIL: " $ACTION " - " $(date)
    fi
  else 
    echo "DRIVE UPLOAD DISABLED"
  fi
done
