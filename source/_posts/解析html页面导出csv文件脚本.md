---
title: 解析html页面导出csv文件脚本
date: 2020-05-10 23:07:21
tags:
- python
- html
- csv
categories:
- useful-scripts
copyright: true #版权声明开启
---
某些时候，需要从前端页面中批量获取数据，但是没有导出功能，可以通过脚本的方式处理即可。下面是一种情况，后端接口返回了html文件，但是该页面并不支持表格导出功能，如果需要获取数据，需要解析该html文件。根据实际情况灵活处理。
```
#!/usr/bin/python
# -*- coding:utf-8 -*-
import json
import logging
import math
import time
import re
import requests
import sys
import csv
from lxml import etree


def exec(csrf_token, sql_content, dbase, dbconfig):
    headers = {
        "cookie": "U8c4-4c6d-8ddd-e66171c338b6; remember_token=300|a7ec4cfa4d27ad8cc523de4a2e0aaf389c4995a1df6",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36",
    }

    url = "https://10.32.48.102/query/mysql"

    data = {'csrf_token': csrf_token, 'sql_content': sql_content,
            'dbase': dbase, 'dbconfig': dbconfig}

    re = requests.post(url, data=data, headers=headers)

    # 深坑,可能td节点数据为空,需要特殊处理
    new_text = re.text.replace(r'<td style="white-space: pre-wrap;"></td>',
                               '<td style="white-space: pre-wrap;">None</td>')
    html = etree.HTML(new_text)

    thead = html.xpath("//div[@class='x_content sql_result']/table/thead")[0]

    th = thead.xpath("//tr/th/text()")

    filterStr = ['数据库信息', '名称', '内容预览', '是否开放', '备注', '操作']
    fileHeader = []

    for x in th:
        if x not in filterStr:
            fileHeader.append(x)
        pass
    writerToCSV(fileHeader, html)

def writerToCSV(fileHeader, html):
    csvFile = open(
        "/Users/lioswong/LiosWong/sublimetext/python/脚本/draft/cc_sql_to_file.csv", "w", encoding='utf-8-sig')
    writer = csv.writer(csvFile)
    writer.writerow(fileHeader)

    hLen = len(fileHeader)
    tdData = html.xpath(
        "//div[@class='x_content sql_result']/table/tbody/tr/td/text()")
    col = 0
    d1 = []
    for i in tdData:
        if col == 0:
            d1 = [0 for i in range(hLen)]
        if col + 1 == hLen:
            d1[col] = i
            writer.writerow(d1)
            col = 0
            pass
        else:
            d1[col] = i
            col += 1
    csvFile.close()

exec('52afaftqywtqsga.EZf8Gw.UF4MSicxUuqJUKjhZ0ORBNMDSF8',
     'SELECT phone from test_info where status=12 and type=1 order by id desc limit 100;',  'test_center', '生产主库只读')
```
