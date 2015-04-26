#!/bin/bash
startStamp=`date +%s`
appRootDir=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
diviFile=$appRootDir"/etc/divi.csv"
dbFile=$appRootDir"/data.db"
sqlFile=$appRootDir"/load_divi.sql"
logFile=$appRootDir"/log/load_divi_data.log"

echo "begin transaction;" > $sqlFile
echo "DELETE FROM dividend;" >> $sqlFile

while read line; do
  firstChar=${line:0:1}
  if [[ $firstChar == "#" ]]; then
    continue
  fi
  isin=`echo $line | cut -d";" -f2`
  amount=`echo $line | cut -d";" -f3`
  currency=`echo $line | cut -d";" -f4`

  exDateStr=`echo $line | cut -d";" -f5`
  if [[ $exDateStr == "n/a" ]]; then
    exDate="null"
  else
    day=`echo $exDateStr | cut -d"." -f1`
    month=`echo $exDateStr | cut -d"." -f2`
    year=`echo $exDateStr | cut -d"." -f3`
    exDate="'"`date -d "$year-$month-$day" +%s`"000'"
  fi

  paymentDateStr=`echo $line | cut -d";" -f6`
  if [[ paymentDateStr == "n/a" ]]; then
    paymentDate="null"
  else
    day=`echo $paymentDateStr | cut -d"." -f1`
    month=`echo $paymentDateStr | cut -d"." -f2`
    year=`echo $paymentDateStr | cut -d"." -f3`
    paymentDate="'"`date -d "$year-$month-$day" +%s`"000'"
  fi

  echo "insert into dividend (isin, amount, currency, ex_date, payment_date) \
  values ('$isin','$amount', '$currency', $exDate, $paymentDate);" >> $sqlFile
done < $diviFile

echo "commit;" >> $sqlFile
sqlite3 $dbFile < $sqlFile
rm $sqlFile

endStamp=`date +%s`
duration=$((endStamp-startStamp))
now=`date +"%Y-%m-%d %H:%M:%S"`

echo "$now load_divi_data performed in $duration seconds" >> $logFile
