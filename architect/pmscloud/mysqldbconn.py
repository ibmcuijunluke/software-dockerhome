# -*- encoding: utf8 -*-
'''
Created on 2016-11-11
updated on 2016-3-16
@author: cuijun
Description:数据库操作demo
'''
import MySQLdb

import ConfigParser
config=ConfigParser.ConfigParser()


db = {
    'host': '192.168.18.200',
    'port': 3306,
    'user': 'root',
    'passwd': '123456',
    'db': 'jw_platform',
    'charset': 'utf8',
}
conn = MySQLdb.connect(**db)
cur = conn.cursor()


def select():
    """
       查询记录
    """
    select_sql = "select * from BS_SYS_DAY"
    cur.execute(select_sql)
    result = cur.fetchall()

    print result

def select1():
    """
       查询记录
    """
    select_sql = "select * from BS_SYS_USER"
    cur.execute(select_sql)
    result = cur.fetchall()

    print result



def main():
    # insert()
    select()
    select1()
    # update()
    # delete()

if __name__ == "__main__":
    main()
