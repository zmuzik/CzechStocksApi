#!/bin/bash

startStamp=`date +%s`
appRootDir=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
hist_dir=$appRootDir"/hist_data/"
tmp_dir=$appRootDir"/tmp/"
root_url="http://ftp.pse.cz"
isinsConfFile=$appRootDir"/etc/included_isins.csv"
closedDaysFile=$appRootDir"/etc/closed_days.csv"
sqlFile=$appRootDir"/tmp/update_historical_quotes.sql"
logFile=$appRootDir"/log/get_historical_data.log"
dbFile=$appRootDir"/data.db"

if [ $# -gt 0 ]; then
  datestr=$1
else
  datestr=`date +"%y%m%d"`
fi

echo "processing for date "$datestr >> $logFile

fname="pl"$datestr".zip"
url="http://ftp.pse.cz/Results.ak/"$fname

curl -o $hist_dir$fname $url

unzip $hist_dir$fname -d $tmp_dir
akfile=$tmp_dir"AK"$datestr".csv"
bofile=$tmp_dir"BO"$datestr".csv"

year="20"${datestr:0:2}
month=${datestr:2:2}
day=${datestr:4:2}
stamp=`TZ="Europe/Prague" date -d "$year-$month-$day" +%s`"000"

echo "begin transaction;" > $sqlFile

for isin in `grep "^[^#;]" $isinsConfFile | cut -d";" -f1`
do
  row=`grep $isin $bofile`
  if [ ${#row} -gt 0 ]; then
    price=`echo $row | cut -d"," -f6 | sed 's/ *$//'`
    volume=`echo $row | cut -d"," -f10 | sed 's/ *$//'`
    echo "insert into historical_quote (isin, stamp, price, volume) values ('$isin','$stamp', $price, $volume);" >> $sqlFile
  fi
done

echo "commit;" >> $sqlFile
sqlite3 $dbFile < $sqlFile

rm $akfile $bofile $sqlFile

endStamp=`date +%s`
duration=$((endStamp-startStamp))
now=`date +"%Y-%m-%d %H:%M:%S"`

echo "$now etl performed in $duration seconds" >> $logFile
