---
title: python初试
date: 2019-02-16 01:42:16
tags:
- python
categories:
- python
copyright: true #版权声明开启
---
最近使用python批量处理业务需求,大概是读取本地文件中的每一行订单号,然后发起http请求接口,处理具体的业务,由于实现起来很简单,所以使用python最适当不过了。
python代码:
```
# -*- coding: UTF-8 -*-
import time
import json
import requests

def doIndexratePost(orderNo):
  // body数据
  data = {'orderNo':orderNo,'type':'3'}
  # 设置请求头token
  headers = {'token':'3eb44d33fdf59677fa97557c0e636463','Content-Type':'application/json'}
  requestUrl = "请求的URL"
  // 使用requests库发起post请求
  r = requests.post(requestUrl, data=json.dumps(data), headers=headers)
  res = r.json()
  // 打印响应
  print(res)
  # 休眠1s
  time.sleep(1);

# 批量读取文件
f = open('/Users/wenchao.wang/LiosWang/sublimetext/dodataone.txt');
num = 0;
for i in f.readlines():
  orderNo = i.strip('\n')
  // 调用函数doIndexratePost处理业务
  doIndexratePost(orderNo);
  num = num + 1;
  print (num,"已执行完")
```
在sublimetext3中执行如下:
![https://note.youdao.com/yws/api/personal/file/WEB502765ba8f341236c351995291594655?method=download&shareKey=6aefeeac4d18ea83d1e5ef974a66fb1d](https://note.youdao.com/yws/api/personal/file/WEB502765ba8f341236c351995291594655?method=download&shareKey=6aefeeac4d18ea83d1e5ef974a66fb1d)
上面简短的代码就实现批量处理业务需求,确实简单方便。我用的mac,用的brew安装python3.7,比自己下载源代码编译安装方便的多，而且很可能会在安装三方库时遇到一些蛋痛的问题,编辑器用的sublimetext3,集成插件用起来十分轻量快捷。
