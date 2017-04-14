#!/usr/bin/python

import psycopg2

conn = psycopg2.connect(database="postgres", user="pgadmin", password="klip2[gE%dad5", host="192.168.18.206", port="5432")
cur = conn.cursor()
# cur.execute("CREATE TABLE test(id serial PRIMARY KEY, num integer,data varchar);")
# cur.execute("SELECT * FROM product_category;")
cur.execute("SELECT * FROM pg_am;")
rows = cur.fetchall()        # all rows in table
print(rows)
for i in rows:
    print(i)
conn.commit()
cur.close()
conn.close()

print "Opened database successfully"  
