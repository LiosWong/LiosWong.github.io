---
title: elasticsearch(6.5.4)踩坑
date: 2019-11-15 17:05:45
tags:
- Elasticsearch
- elk
- Logstash
- Kibana
- Filebeat    
categories:
- elk    
copyright: true #版权声明开启
---
#### 环境
1. mac pro
2. elk、filebeat版本6.5.4  

#### 问题
本地在本地搭建elk+filebeat环境,elasticsearch启动报错如下：
```
java.lang.IllegalArgumentException: Rejecting mapping update to [driver_trace_2019.11.15] as the final mapping would have more than 1 type: [driver_trace, doc]
    at org.elasticsearch.index.mapper.MapperService.internalMerge(MapperService.java:451) ~[elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.index.mapper.MapperService.internalMerge(MapperService.java:399) ~[elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.index.mapper.MapperService.merge(MapperService.java:331) ~[elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.cluster.metadata.MetaDataMappingService$PutMappingExecutor.applyRequest(MetaDataMappingService.java:313) ~[elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.cluster.metadata.MetaDataMappingService$PutMappingExecutor.execute(MetaDataMappingService.java:229) ~[elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.cluster.service.MasterService.executeTasks(MasterService.java:639) ~[elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.cluster.service.MasterService.calculateTaskOutputs(MasterService.java:268) ~[elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.cluster.service.MasterService.runTasks(MasterService.java:198) [elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.cluster.service.MasterService$Batcher.run(MasterService.java:133) [elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.cluster.service.TaskBatcher.runIfNotProcessed(TaskBatcher.java:150) [elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.cluster.service.TaskBatcher$BatchedTask.run(TaskBatcher.java:188) [elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.common.util.concurrent.ThreadContext$ContextPreservingRunnable.run(ThreadContext.java:624) [elasticsearch-6.5.4.jar:6.5.4]
    at org.elasticsearch.common.util.concurrent.PrioritizedEsThreadPoolExecutor$TieBreakingPrioritizedRunnable.runAndClean(PrioritizedEsThreadPoolExecutor.java:244) [elasticsearch-6.5.4.jar:6.5.4]
```
原因是elastic search在6.x版本调整了,一个index只能存储一种type导致,即Logstash启动的时候会看到它使用的template是默认的,然后这样导入的数据后,自动创建了索引,默认的_type是doc,即:logstash在同步的时候会自动创建一个doc类型的index. 
#### 解决
参考[https://blog.csdn.net/q18810146167/article/details/89339380](https://blog.csdn.net/q18810146167/article/details/89339380)这篇文章:  
**1.删除原有的Elasticsearch indices**
![https://note.youdao.com/yws/api/personal/file/WEB1b3ebfdc85a39f18fc7d6a3e39fe084d?method=download&shareKey=228b42ff8a6f4f6bf3fbd9c9f973e5ca](https://note.youdao.com/yws/api/personal/file/WEB1b3ebfdc85a39f18fc7d6a3e39fe084d?method=download&shareKey=228b42ff8a6f4f6bf3fbd9c9f973e5ca)
**2.新建Elasticsearch indices**
![https://note.youdao.com/yws/api/personal/file/WEB931f74297293eb06e5ae7be70f8271d2?method=download&shareKey=ed8e634e35bc7a8101af35970c4858c9](https://note.youdao.com/yws/api/personal/file/WEB931f74297293eb06e5ae7be70f8271d2?method=download&shareKey=ed8e634e35bc7a8101af35970c4858c9)
创建的索引里默认mapping里面的type是doc,上面操作的含义可以理解为把所有的类型都映射为string,里面type为text 分词为ik_max_word.
具体创建的脚本如下:
```
{
  "mappings":{
    "doc":{
      "dynamic_templates":[
       {
        "named_analyzers":{
         "match_mapping_type":"string",
         "match":"*",
         "mapping":{
          "type":"text",
          "analyzer":"ik_max_word"
         }
        }
       }
      ]
    }
  
  }
}
```
重新创建后,不再报错了.
