---
title: 生成海量csv文件数据脚本
date: 2020-05-10 18:45:13
tags:
- python
categories:
- useful-scripts
copyright: true #版权声明开启
---
工作中可能会用到海量的测试数据，可以通过脚本的方式简单快速处理，下面通过python生成海量的csv数据文件，具体的列可以根据需求定制。

```
# -*- coding: utf-8 -*-
import requests
import sys
import re
import csv
import random
'''
从csv文件中读取数据
'''
def readCsv():
# 读取csv至字典
  csvFile = open("/Users/lioswong/LiosWong/sublimetext/python/脚本/bindPhone.csv", "r")
  reader = csv.reader(csvFile)
  # 建立空字典
  result = {}
  for item in reader:
      # 忽略第一行
      if reader.line_num == 1:
        continue
      result[item[0]] = item[1]
  csvFile.close()
  print(result)

'''
往csv文件中写入数据
'''
def writerCsv():
  fileHeader = ["customerPhone", "orderNo","driverPhone","driverNo"]
  csvFile = open("/Users/lioswong/LiosWong/sublimetext/python/脚本/test6.csv", "w")
  writer = csv.writer(csvFile)
  d1 = [0]*4
  line = 1
  for i in range(0,1000001):
    if line==1:
        writer.writerow(fileHeader)
    d1[0]=random.choice(['177','156','159','188','199','139','152','188','133','185','170','136','189','158','178','151'])+"".join(random.choice("0123456789") for i in range(8))
    d1[1]="".join(random.choice("0123456789") for i in range(10))
    d1[2]=random.choice(['152','139','199','188','190','185','156','136','133','158','136','151','153'])+"".join(random.choice("0123456789") for i in range(8))
    d1[3]="".join(random.choice("0123456789") for i in range(8))
    # 写入的内容都是以列表的形式传入函数
    writer.writerow(d1)
    print(line)
    line+=1
  csvFile.close()


writerCsv()
# readCsv()
```
