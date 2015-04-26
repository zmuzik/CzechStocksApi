# -*- coding: utf-8 -*-

import os
import collections
import json
import sqlite3
from flask import Flask, Response, jsonify, g, request, session, g, redirect, url_for, abort, render_template, flash


app = Flask(__name__)

# Load default config and override config from an environment variable
app.config.update(dict(
    DATABASE=os.path.join(app.root_path, 'data.db'),
    #DEBUG=True
))


def connect_db():
    """Connects to the specific database."""
    rv = sqlite3.connect(app.config['DATABASE'])
    rv.row_factory = sqlite3.Row
    return rv


def init_db():
    """Initializes the database."""
    db = get_db()
    with app.open_resource('create_schema.sql', mode='r') as f:
        db.cursor().executescript(f.read())
    db.commit()


def get_db():
    """Opens a new database connection if there is none yet for the
    current application context.
    """
    if not hasattr(g, 'sqlite_db'):
        g.sqlite_db = connect_db()
    return g.sqlite_db


@app.teardown_appcontext
def close_db(error):
    """Closes the database again at the end of the request."""
    if hasattr(g, 'sqlite_db'):
        g.sqlite_db.close()


@app.route('/csapi/currentQuotes')
def get_current_quotes():
    db = get_db()
    cur = db.execute('select isin, price, delta, timeStr, stamp from current_quote')
    rows = cur.fetchall()

    result_list = []
    for row in rows:
        d = collections.OrderedDict()
        d['isin'] = row[0]
        d['price'] = row[1]
        d['delta'] = row[2]
#        d['timeStr'] = row[3]
        d['stamp'] = row[4]
        result_list.append(d)

    #result_string = json.dumps(result_list, ensure_ascii=False).encode(encoding='utf-8')
    result_string = json.dumps(result_list)

    response = Response(result_string, status=200, mimetype='application/json')
    return response


@app.route('/csapi/dividends')
def get_dividends():
    db = get_db()
    cur = db.execute('select isin, amount, currency, ex_date, payment_date from dividend')
    rows = cur.fetchall()

    result_list = []
    for row in rows:
        d = collections.OrderedDict()
        d['isin'] = row[0]
        d['amount'] = row[1]
        d['currency'] = row[2]
        d['exDate'] = row[3]
        d['paymentDate'] = row[4]
        result_list.append(d)

    #result_string = json.dumps(result_list, ensure_ascii=False).encode(encoding='utf-8')
    result_string = json.dumps(result_list)

    response = Response(result_string, status=200, mimetype='application/json')
    return response


@app.route('/csapi/stockDetails')
def get_stock_details():
    db = get_db()
    cur = db.execute('select isin, indicator, value from stock_detail')
    rows = cur.fetchall()

    result_list = []
    for row in rows:
        d = collections.OrderedDict()
        d['isin'] = row[0]
        d['indicator'] = row[1]
        d['value'] = row[2]
        result_list.append(d)

    #result_string = json.dumps(result_list, ensure_ascii=False).encode(encoding='utf-8')
    result_string = json.dumps(result_list)

    response = Response(result_string, status=200, mimetype='application/json')
    return response


@app.route('/csapi/todaysQuotes/<timestamp>')
def get_todays_quotes_newer_than(timestamp):
    db = get_db()
    cur = db.execute('select isin, stamp, price, volume from todays_quote where stamp > ' + timestamp + ' order by stamp asc')
    rows = cur.fetchall()

    result_list = []
    for row in rows:
        d = collections.OrderedDict()
        d['isin'] = row[0]
        d['stamp'] = row[1]
        d['price'] = row[2]
        d['volume'] = row[3]

        result_list.append(d)

    #result_string = json.dumps(result_list, ensure_ascii=False).encode(encoding='utf-8')
    result_string = json.dumps(result_list)

    response = Response(result_string, status=200, mimetype='application/json')
    return response


@app.route('/csapi/historicalQuotes/<timestamp>')
def get_historical_quotes_newer_than(timestamp):
    db = get_db()
    cur = db.execute('select isin, stamp, price, volume from historical_quote where stamp > ' + timestamp + ' order by stamp asc')
    rows = cur.fetchall()

    result_list = []
    for row in rows:
        d = collections.OrderedDict()
        d['isin'] = row[0]
        d['stamp'] = row[1]
        d['price'] = row[2]
        d['volume'] = row[3]

        result_list.append(d)

    #result_string = json.dumps(result_list, ensure_ascii=False).encode(encoding='utf-8')
    result_string = json.dumps(result_list)

    response = Response(result_string, status=200, mimetype='application/json')
    return response

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
