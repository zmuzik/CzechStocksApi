#!/bin/bash
startStamp=`date +%s`
url_prefix="http://www.pse.cz/XML/ProduktKontinualJS.aspx?cnpa="
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


now=`date +"%Y-%m-%d %H:%M:%S"`
echo "$now script started" >> $logFile

#quit if exchange closed today
today=`date +%Y-%m-%d`
if  grep -q $today $closedDaysFile; then
  echo "$now skipping run - stock exchange closed today" >> $logFile
  exit 0;
fi

oldStamp=`sqlite3 $dbFile "select max(stamp) from todays_quote;"`
if [ -z "$oldStamp" ]; then
  oldStamp=0
fi

echo "begin transaction;" > $sqlFile

#for every stock
for confRow in `grep "^[^#;]" $isinsConfFile`
do
  isin=`echo $confRow | cut -d";" -f1`
  id=`echo $confRow | cut -d";" -f2`
  url=$url_prefix$id
  curl -o $rawFile $url
  cat $rawFile | grep "d:new Date" | tr ":(,}" " " > $tableFile

  record=`head -n 1 $tableFile`
  year=`echo $record | cut -d" " -f4`
  month=`echo $record | cut -d" " -f5`
  month=$((month+1))
  day=`echo $record | cut -d" " -f6`
  baseStamp=`TZ="Europe/Prague" date -d "$year-$month-$day" +%s`"000"
  
  awk -v baseStamp=$baseStamp -v isin=$isin -v oldStamp=$oldStamp '{
     hour = $7;
     minute = $8;
     second = $9;
     stamp = baseStamp + 1000 * second + 60000 * minute + 3600000 * hour;
     price = $15;
     volume = $17;
     if (stamp > oldStamp) {
       printf ("insert into todays_quote (isin, stamp, price, volume) values ('\''%s'\'', %s, %s, %s);\n", isin, stamp, price, volume);
     }
  }' < $tableFile >> $sqlFile

  rm $rawFile $tableFile
done

maxStamp=`sqlite3 $dbFile "select max(stamp) from todays_quote;"`

lowLim=$baseStamp
upLim=$((baseStamp+86400000))

echo "delete from todays_quote where stamp < "$lowLim" or stamp > "$upLim";" >> $sqlFile

echo "commit;" >> $sqlFile
echo "vacuum;" >> $sqlFile

sqlite3 $dbFile < $sqlFile

rm $sqlFile

endStamp=`date +%s`
duration=$((endStamp-startStamp))
now=`date +"%Y-%m-%d %H:%M:%S"`

echo "$now etl performed in $duration seconds" >> $logFile
