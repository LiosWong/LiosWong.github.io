---
title: Jrebel使用
date: 2019-08-23 14:03:34
tags:
- jrebel  
categories:
- 工具   
copyright: true #版权声明开启        
---
关于Jrebel就不多说了,开发中由于修改代码或者配置文件,导致服务重启,非常的耗时的,但是利用Jrebel可以大大提高效率.本文介绍的是``ilanyu大神``提供的反代理工具,可以免费使用Jrebel.  
> 步骤

* 首先去docker远程仓库download镜像,地址``https://hub.docker.com/r/ilanyu/golang-reverseproxy/``
* 根据镜像生成容器,``docker run -d -p 8888:8888 ilanyu/golang-reverseproxy``
* idea按照插件Jrebel,然后在Team URL里输入``http://localhost:8888/88414687-3b91-4286-89ba-2dc813b107ce``,``88414687-3b91-4286-89ba-2dc813b107ce``是GUID(生成即可),,邮箱可任意填写即可.至此就激活啦
* 建议Jrebel License离线工作

> 本地环境

1. MacBook Pro (Retina, 15-inch, Mid 2015)
2. idea 2019.1
3. docker mac 18.09.2

> 参考

1. [http://blog.lanyus.com/archives/317.html#comment-3803](http://blog.lanyus.com/archives/317.html#comment-3803)
2. [http://blog.lanyus.com/archives/337.html](http://blog.lanyus.com/archives/337.html)
3. [https://hub.docker.com/r/ilanyu/golang-reverseproxy/](https://hub.docker.com/r/ilanyu/golang-reverseproxy/)


