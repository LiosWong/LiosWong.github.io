---
title: kafka producer
date: 2020-05-10 18:55:24
tags:
- python
- kafka-producer
categories:
- useful-scripts
copyright: true #版权声明开启
---
工作中会在开发环境中测试生产kafka消息，该脚本简单的实现了这一功能。
```
#!/usr/bin/python
# -*- coding:utf-8 -*-
from pykafka import KafkaClient
import json
import logging
logging.basicConfig(level=logging.INFO)

client = KafkaClient(hosts="10.0.10.21:15386")  # 可接受多个Client,多个broker

# print(client.topics) # 查看所有topic

def sendDevKafkaMsg(topic, message):
    try:
        topic = client.topics[topic]  # 选择一个topic
        producer = topic.get_producer(delivery_reports=True)
        producer.produce(bytes(message, encoding="utf8"))
        producer.get_delivery_report() # 返回之前发送失败的消息和结果
    except Exception as e:
        print(e)


sendDevKafkaMsg("TEST_TOPIC", json.dumps(data1))
```
