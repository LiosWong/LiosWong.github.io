---
title: 构建tomcat镜像
date: 2019-09-07 23:43:20
tags:
- docker
- 镜像
- 容器
- tomcat镜像
categories:
- docker   
copyright: true #版权声明开启    
---
如果使用tomcat镜像非常简单,到镜像仓库pull现有的就可以满足,为了个人后面的学习,本文介绍下如何构建简单的tomcat镜像.
#### 步骤
1. 以``hub.c.163.com/library/tomcat:latest``为父镜像，生成容器  
2. 在容器中安装``jdk-8u221-linux-x64.tar.gz``、``apache-tomcat-8.5.45.tar.gz``,具体配置可google  
3. 根据容器生成镜像  
4. 根据新镜像运行容器  
5. 把新镜像push到远程仓库中  

#### 说明

``步骤1``中根据镜像生成容器，很简单:``docker run -i -t --name ubuntu e64071ee23c7``,  
得到容器之后,进入容器，使用``exec``命令进入:
``docker exec -it d6b7d20148aa bash``,   
进入之后可以按部就班按照jdk、tomcat,完成之后,根据该容器生成镜像``步骤3``,使用commit命令:   
``docker commit d6b7d20148aa tomcat:0.1 ``  
虽然得到了一个拥有web容器的镜像,但是当我们运行起容器时,如果自动启动tomcat程序呢?所以需要结合Dockerfile根据得到的``tomcat:0.1``的镜像再生成一个镜像,Dockerfile内容如下:  
```
# 指定源镜像
FROM hub.c.163.com/lioswang/tomcat:0.1
MAINTAINER diy_os diy_os@163.com
# 设置JAVA环境
ENV JAVA_HOME /usr/dev/jdk1.8.0_221
ENV JAVA_BIN=/usr/dev/jdk1.8.0_221/bin
ENV PATH $PATH:$JAVA_BIN:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
# 运行tomcat程序
CMD ["sh","/usr/dev/tomcat8/bin/catalina.sh","run"]
```
然后在Dockerfile文件当前目录下,执行:  
``docker build -t tomcat:0.3 .``
得到了新的镜像``tomcat:0.3``,为了验证当容器启动时,tomcat程序启动,可以在宿主机上copy一个测试web包到容器中:  
``docker cp ./web.war tomcat_1:/usr/dev/tomcat8/webapps``  
重启容器发现,可以直接访问到了我们的web资源.  
``步骤5``可根据使用的镜像仓库服务,由于我使用的网易蜂巢镜像仓库,可参考官方文档即可:
``https://www.163yun.com/help/documents/15587826830438400``
