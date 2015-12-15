#!/bin/bash
scp zb@185.8.238.141:/home/zb/csapi/api/data.db ./

sqlite3 data.db 'select * from dividend;' > ../cs/app/src/main/assets/dividend.csv
sqlite3 data.db 'select * from historical_quote;' > ../cs/app/src/main/assets/historical_quote.csv
sqlite3 data.db 'select * from stock_detail;' > ../cs/app/src/main/assets/stock_detail.csv
