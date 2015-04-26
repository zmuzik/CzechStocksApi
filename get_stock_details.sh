#!/bin/bash
startStamp=`date +%s`
url_prefix="www.pse.cz/Cenne-Papiry/Detail.aspx?isin="
url_postfix="#OL"
appRootDir=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
isinsConfFile=$appRootDir"/etc/included_isins.csv"
closedDaysFile=$appRootDir"/etc/closed_days.csv"
rawFile=$appRootDir"/tmp/raw.html"
tableFile=$appRootDir"/tmp/table.csv"
isinsFile=$appRootDir"/tmp/isins.csv"
completeFile=$appRootDir"/tmp/complete.csv"
sqlFile=$appRootDir"/tmp/update_stock_details.sql"
logFile=$appRootDir"/log/get_stock_info.log"
dbFile=$appRootDir"/data.db"

echo "begin transaction;" > $sqlFile
echo "DELETE FROM stock_detail;" >> $sqlFile

#for every stock
for isin in `grep "^[^#;]" $isinsConfFile | cut -d";" -f1`
do
  url=$url_prefix$isin$url_postfix
  curl -o $rawFile $url
  cat $rawFile | awk '/Selected Indicators/{f=1;next} /\/table/{f=0} f' | sed 's|</th><td>|;|' | sed 's|<[^>]*>||g' > $tableFile
  while read row
  do
    indicator=`echo $row | cut -d";" -f1`
    value=`echo $row | cut -d";" -f2 | tr "," "." | tr -d '\r' | sed 's/\xc2\xa0//g'`
    echo "insert into stock_detail (isin, indicator, value) values ('$isin','$indicator', '$value');" >> $sqlFile
  done < $tableFile
  rm $rawFile $tableFile
done

echo "commit;" >> $sqlFile

sqlite3 $dbFile < $sqlFile

#rm $sqlFile

endStamp=`date +%s`
duration=$((endStamp-startStamp))
now=`date +"%Y-%m-%d %H:%M:%S"`

echo "$now etl performed in $duration seconds" >> $logFile

