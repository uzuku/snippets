#!/usr/bin/env python
# -*- coding: utf-8 -*-
import pymysql
import datetime

config = {
    'host': '10.14.14.180',
    'port': 3306,
    'user': 'root',
    'passwd': 'example_password',
    'charset':'utf8',
    'cursorclass':pymysql.cursors.DictCursor
    }
conn = pymysql.connect(**config)
conn.autocommit(1)
cursor = conn.cursor()

endtime = datetime.datetime.now() - datetime.timedelta(days=3)
endtimeStr = endtime.strftime("%Y-%m-%d") + " 00:00:00"
print "end_time: " + endtimeStr

try:
    conn.select_db('delivery_center')
     # fetch last job
    count = cursor.execute('SELECT * FROM delivery_job WHERE create_time < "%s" ORDER BY id DESC LIMIT 1' % endtimeStr)
    if cursor.rowcount == 1:
        results = cursor.fetchall()
        print results[0]
        endJobId = results[0]['id']
        print endJobId
        # fetch last deployment
        count = cursor.execute('SELECT * FROM delivery_deployment WHERE job_id = %s ORDER BY id DESC LIMIT 1' % endJobId)
        if cursor.rowcount == 1:
            results = cursor.fetchall()
            print results[0]
            endDepDeploymentId = results[0]['deployment_id']
            endDepId = results[0]['id']
            print endDepDeploymentId
            # fetch last execution
            count = cursor.execute('SELECT * FROM delivery_execution WHERE deployment_id = "%s" ORDER BY id DESC LIMIT 1' % endDepDeploymentId)
            if cursor.rowcount == 1:
                results = cursor.fetchall()
                print results[0]
                endExeId = results[0]['id']
                print "Begin to delete delivery_execution WHERE id <= %s" % endExeId
                cursor.execute('DELETE FROM delivery_execution WHERE id <= %s' % endExeId)
                print "Begin to delete delivery_deployment WHERE id <= %s" % endDepId
                cursor.execute('DELETE FROM delivery_deployment WHERE id <= %s' % endDepId)
                print "Begin to delete delivery_job WHERE id <= %s" % endJobId
                cursor.execute('DELETE FROM delivery_job WHERE id <= %s' % endJobId)

except:
    import traceback
    traceback.print_exc()
    # 发生错误时回滚
    conn.rollback()
finally:
    # 关闭游标连接
    cursor.close()
    # 关闭数据库连接
    conn.close()
