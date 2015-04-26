#!/bin/bash
startStamp=`date +%s`
url="http://www.pse.cz/On-Line/Kontinual/"
appRootDir=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

dbFile=$appRootDir"/data.db"

isinsConfFile=$appRootDir"/etc/included_isins.csv"
closedDaysFile=$appRootDir"/etc/closed_days.csv"

scriptName=`basename $0 | cut -d"." -f1`
logFile=$appRootDir"/log/"$scriptName".log"
rawFile=$appRootDir"/tmp/"$scriptName"-raw.html"
tableFile=$appRootDir"/tmp/"$scriptName"-table.csv"
isinsFile=$appRootDir"/tmp/"$scriptName"-isins.csv"
completeFile=$appRootDir"/tmp/"$scriptName"-complete.csv"
sqlFile=$appRootDir"/tmp/"$scriptName".sql"

#quit if exchange closed today
today=`date +%Y-%m-%d`

if  grep -q $today $closedDaysFile; then
    now=`date +"%Y-%m-%d %H:%M:%S"`
    echo "$now skipping run - stock exchange closed today" >> $logFile
    exit 0;
fi

#download the raw html file
curl -o $rawFile $url
#curl $url > $rawFile

#extract the timestamp of the data included
timeStr=`grep "Online data:" $rawFile | sed 's|<[^>]*>||g' | awk '{ print $3 $4 $5 " " $7; }' | sed 's/\x0d//g'`
year=`echo $timeStr | tr '|' '/' | cut -d'/' -f 3`
month=`echo $timeStr | cut -d'/' -f 1`
day=`echo $timeStr | cut -d'/' -f 2`
time=`echo $timeStr | cut -d'|' -f 2`
hour=`echo $timeStr | tr ':' '|' | cut -d'|' -f 2`
minute=`echo $timeStr | tr ':' '|' | cut -d'|' -f 3`

echo "time string "$timeStr
echo "year "$year
echo "month "$month
echo "day "$day
echo "time "$time
echo "hour "$hour
echo "minute "$minute

if [ "$hour" -lt 8 ]; then
  hour=$((hour+12))
fi
echo "hour "$hour

stamp=`TZ="Europe/Prague" date -d "$year-$month-$day $hour:$minute" +%s`"000"
echo $stamp

# take rows with securities listings, strip them from html and leading whitespaces
grep "<td class=\"nowrap\">" $rawFile | sed 's|<[^>]*>|;|g' | sed 's/^\s*//' > $tableFile

#extract ISINs
grep "<td class=\"nowrap\">" $rawFile | awk '{\
  isinBeg=index($0, "?isin=") + 6;
  isinEnd=index($0, "#OL\">");
  isinLen=isinEnd-isinBeg;
  print substr($0, isinBeg, isinLen);
}' > $isinsFile

#join the files
paste -d";" $isinsFile $tableFile > $completeFile

error=0

echo "begin transaction;" > $sqlFile
echo "delete from current_quote;" >> $sqlFile

#extract data only for securities included in the config file
#store the data into the db
for isin in `grep "^[^#;]" $isinsConfFile | cut -d";" -f1`
do
  dataRow=`grep $isin $completeFile`
  stockName=`echo $dataRow | cut -d";" -f4`
  stockPrice=`echo $dataRow | cut -d";" -f9  | tr -d "," | sed 's/\xc2\xa0//g'`
  stockDelta=`echo $dataRow | cut -d";" -f11 | tr -d "," | sed 's/\xc2\xa0//g'`

  if [ -z "$stockPrice" ]; then
    error=1
  fi

    if [ -z "$stockDelta" ]; then
    error=1
  fi

  echo "insert into current_quote (isin, price, delta, timeStr, stamp) \
  values ('$isin', '$stockPrice', '$stockDelta', '$timeStr', '$stamp');" >> $sqlFile
done

echo "commit;" >> $sqlFile

now=`date +"%Y-%m-%d %H:%M:%S"`
if [ "$error" -eq 0 ]; then
  sqlite3 $dbFile < $sqlFile
  echo "$now complete data - db updated" >> $logFile
else
  echo "$now incomplete data - db update skipped" >> $logFile
fi

rm $rawFile $isinsFile $tableFile $completeFile $sqlFile

endStamp=`date +%s`
duration=$((endStamp-startStamp))
now=`date +"%Y-%m-%d %H:%M:%S"`

echo "$now etl performed in $duration seconds" >> $logFile
