#!/bin/bash
echo current_quote 
sqlite3 data.db 'select count(0) from current_quote;'
echo todays_quote
sqlite3 data.db 'select count(0) from todays_quote;'
echo historical_quote
sqlite3 data.db 'select count(0) from historical_quote;'
echo stock_detail
sqlite3 data.db 'select count(0) from stock_detail;'
echo dividend
sqlite3 data.db 'select count(0) from dividend;'
