---
title: 删除docker镜像失败
date: 2019-09-06 16:37:57
tags:
- docker
- 镜像
- 容器
categories:
- docker   
copyright: true #版权声明开启    
---

#### 环境
1. MacBook Pro
2. Docker version 19.03.1, build 74b1e89

#### 问题  
```
MacdeMacBook-Pro:war lioswong$ docker rmi 620cdd31d76f5
Error response from daemon: conflict: unable to delete 620cdd31d76f (cannot be forced) - image has dependent child images
```

#### 解决  
参考网上的方法，找出依赖的镜像:
```
docker image inspect --format='{{.RepoTags}} {{.Id}} {{.Parent}}' $(docker image ls -q --filter since=620cdd31d76f)
```
发现还是删除不了，然后停止所有容器、删除所有容器、删除所有none容器，还是不行,具体命令如下:
```
# 停止所有容器
docker ps -a | grep "Exited" | awk '{print $1 }'|xargs docker stop
# 删除所有容器
docker ps -a | grep "Exited" | awk '{print $1 }'|xargs docker rm
# 删除所有none容器
docker images|grep none|awk '{print $3 }'|xargs docker rmi
```
也尝试了给镜像修改tag,也失败了，最后根据``REPOSITORY:TAG``删除成功了，具体原因不清楚
```
MacdeMacBook-Pro:war lioswong$ docker rmi hub.c.163.com/public/ubuntu:16.04-tools
Untagged: hub.c.163.com/public/ubuntu:16.04-tools
Untagged: hub.c.163.com/public/ubuntu@sha256:0fc4a48462a92b0a5a53b35540b8ca33a68606c6cd23c21df54c5f54bccbf33a
```

> 参考文章  

1. [https://blog.csdn.net/renzhewudi77/article/details/82858280](https://blog.csdn.net/renzhewudi77/article/details/82858280)  
2. [https://blog.csdn.net/u010483897/article/details/80940561](https://blog.csdn.net/u010483897/article/details/80940561)
