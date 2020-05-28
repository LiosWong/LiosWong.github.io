---
title: kafka consumer
date: 2020-05-10 18:55:05
tags:
- python
- kafka-consumer
categories:
- useful-scripts
copyright: true #版权声明开启
---
工作中会在开发环境中测试消费其他系统的消息，该脚本简单的实现了这一功能。
```
#!/usr/bin/python
# -*- coding:utf-8 -*-
from pykafka import KafkaClient
import json
import logging
# logging.basicConfig(level=logging.INFO)

client = KafkaClient(hosts="102.1.10.221:15386")  # 可接受多个Client,多个broker

# print(client.topics) # 查看所有topic

def receiveMsg(topics):
    topic = client.topics[topics]  # 选择一个topic
    consumer = topic.get_simple_consumer(consumer_group = 'dev26-dc',reset_offset_on_start=False)
    partitions = topic.partitions
    offset_list = consumer.held_offsets
    print("当前消费者分区offset情况{}".format(offset_list))  # 消费者拥有的分区offset的情况
    consumer.reset_offsets([(partitions[0], 0)])  # 设置offset
    msg = consumer.consume()
    for i in range(0,10):
        print("消费 :{}".format(msg.value.decode()))
        pass
    pass

receiveMsg("TEST_NOTIFY")
```
