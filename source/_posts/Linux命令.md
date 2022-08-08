---
title: Linux命令
date: 2022-08-07 17:09:52
tags:
- 工具
- 日志查询
- 命令
categories:
- 工具   
---
### 查询/日志
* 分析 TIME_WAIT
``netstat -natp | grep "TIME_WAIT" | awk '{print $5}' | sort | uniq -c | sort -t ' ' -k 1 -nr``  
* 分析某列倒排  
``cat tcp_up_in.log | awk -v FS="|" -v oneHourMill=3600000 '{group[int($4/(oneHourMill))*(oneHourMill)]++};END{for(i in group){print strftime("%Y-%m-%d %H:%M:%S",i/1000),group[i]}}' | sort -t ' ' -k 3 -nr``

* awk
* sed
* grep
* cut