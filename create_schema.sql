CREATE TABLE current_quote ("isin" text primary key, "price" real, "delta" real, "timeStr" text, "stamp" integer);
CREATE TABLE stock_detail ("isin" text, "indicator" text, "value" text);
CREATE TABLE historical_quote ("isin" text, "stamp" integer, "price" real, "volume" real);
CREATE TABLE todays_quote ("isin" text, "stamp" integer, "price" real, "volume" real);
CREATE TABLE dividend ("isin" text, "amount" real, "currency" text, "ex_date" integer, "payment_date" integer);
