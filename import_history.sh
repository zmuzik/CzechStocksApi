#!/bin/bash

startStamp=`date +%s`
appRootDir=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
hist_dir=$appRootDir"/hist_data/"
tmp_dir=$appRootDir"/tmp/"
root_url="http://ftp.pse.cz"
isinsConfFile=$appRootDir"/etc/included_isins.csv"
closedDaysFile=$appRootDir"/etc/closed_days.csv"
sqlFile=$appRootDir"/tmp/import_history.sql"
logFile=$appRootDir"/log/get_historical_data.log"
dbFile=$appRootDir"/data.db"

if [ $# -lt 1 ]; then
  echo "usage: import_history.sh [isin]"
  exit 0
else
  isin=$1
  sqlFile=$appRootDir"/tmp/import_history_"$isin".sql"
fi

echo "begin transaction;" > $sqlFile
echo "delete from historical_quote where isin = '$isin';" >> $sqlFile

fname="pl"$datestr".zip"

for zipfile in `ls ${hist_dir}pl*.zip`
do
  fname=`echo $zipfile | cut -d"/" -f 7`
  datestr=${fname:2:6}
  echo $datestr

  unzip $hist_dir$fname -d $tmp_dir
  akfile=$tmp_dir"AK"$datestr".csv"
  bofile=$tmp_dir"BO"$datestr".csv"

  year="20"${datestr:0:2}
  month=${datestr:2:2}
  day=${datestr:4:2}
  stamp=`TZ="Europe/Prague" date -d "$year-$month-$day" +%s`"000"

  row=`grep $isin $bofile`
  if [ ${#row} -gt 0 ]; then
    price=`echo $row | cut -d"," -f6 | sed 's/ *$//'`
    volume=`echo $row | cut -d"," -f10 | sed 's/ *$//'`
    echo "insert into historical_quote (isin, stamp, price, volume) values ('$isin','$stamp', $price, $volume);" >> $sqlFile
  fi
  rm $akfile $bofile
done

echo "commit;" >> $sqlFile
#sqlite3 $dbFile < $sqlFile

#rm $akfile $bofile $sqlFile

