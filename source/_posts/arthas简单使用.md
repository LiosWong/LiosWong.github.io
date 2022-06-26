---
title: arthas简单使用
date: 2019-10-15 15:29:00
tags: 
- java
- arthas
categories:
- arthas   
copyright: true #版权声明开启    
---
#### 简介
Arthas 是Alibaba开源的Java诊断工具,深受开发者喜爱,[项目地址](https://github.com/alibaba/arthas).当你遇到以下类似问题而束手无策时,Arthas可以帮助你解决:  
1. 这个类从哪个 jar 包加载的？为什么会报各种类相关的 Exception？  
2. 我改的代码为什么没有执行到？难道是我没 commit？分支搞错了？  
3. 遇到问题无法在线上 debug,难道只能通过加日志再重新发布吗？  
4. 线上遇到某个用户的数据处理有问题,但线上同样无法 debug,线下无法重现！  
5. 是否有一个全局视角来查看系统的运行状况？  
6. 有什么办法可以监控到JVM的实时运行状态？  
Arthas支持JDK 6+,支持Linux/Mac/Windows,采用命令行交互模式,同时提供丰富的 Tab 自动补全功能,进一步方便进行问题的定位和诊断.

#### 快速使用
官方推荐通过arthas-boot方式安装,下载``arthas-boot.jar``,然后用``java -jar``的方式启动：
```
wget https://alibaba.github.io/arthas/arthas-boot.jar
java -jar arthas-boot.jar
```
当然如果有其他的需求,可以使用全量安装、手动安装的方式,具体参考[Arthas Install](https://alibaba.github.io/arthas/install-detail.html)

#### Simplecase
dubbo消费端调用服务时,会为接口生成一个代理类,这个代理类有什么信息呢,可以通过arthas可以反编译出Protocol、Cluster、Transporter、Wrapper等代理类,帮助理解源码.
* 启动dubbo消费端服务
* 启动arthas服务
```
➜  arthas java -jar arthas-boot.jar
[INFO] arthas-boot version: 3.1.4
[INFO] Found existing java process, please choose one and hit RETURN.
* [1]: 1089 zookeeper-dev-ZooInspector.jar
  [2]: 982 org.jetbrains.kotlin.daemon.KotlinCompileDaemon
  [3]: 1623 org.apache.dubbo.demo.provider.ApplicationProvider1
  [4]: 1627 org.jetbrains.jps.cmdline.Launcher
  [5]: 1628 org.apache.dubbo.demo.consumer.ApplicationConsumer
  [6]: 300 
  [7]: 637 org.jetbrains.idea.maven.server.RemoteMavenServer36
  [8]: 957 org.apache.zookeeper.server.quorum.QuorumPeerMain
  [9]: 958 org.apache.zookeeper.server.quorum.QuorumPeerMain
  [10]: 959 org.apache.zookeeper.server.quorum.QuorumPeerMain
5
[INFO] arthas home: /Users/lioswong/.arthas/lib/3.1.4/arthas
[INFO] Try to attach process 1628
[INFO] Attach process 1628 success.
[INFO] arthas-client connect 127.0.0.1 9998
  ,---.  ,------. ,--------.,--.  ,--.  ,---.   ,---.                           
 /  O  \ |  .--. ''--.  .--'|  '--'  | /  O  \ '   .-'                          
|  .-.  ||  '--'.'   |  |   |  .--.  ||  .-.  |`.  `-.                          
|  | |  ||  |\  \    |  |   |  |  |  ||  | |  |.-'    |                         
`--' `--'`--' '--'   `--'   `--'  `--'`--' `--'`-----'                          
                                                                                

wiki      https://alibaba.github.io/arthas                                      
tutorials https://alibaba.github.io/arthas/arthas-tutorials                     
version   3.1.4                                                                 
pid       1628                                                                  
time      2019-10-15 14:01:56    
```
arthas启动时,会发现dubbo服务消费者进程是第5个,则输入5,再输入回车/enter,Arthas会attach到目标进程上,并输出日志.

* 根据``sc``命令搜索JVM已加载的类信息
```
[arthas@1628]$ sc *proxy0
org.apache.dubbo.common.bytecode.proxy0
Affect(row-cnt:1) cost in 22 ms.
```
* 通过``jad``命令反编译  
```
[arthas@1628]$ jad org.apache.dubbo.common.bytecode.proxy0

ClassLoader:                                                                                        
+-sun.misc.Launcher$AppClassLoader@18b4aac2                                                         
  +-sun.misc.Launcher$ExtClassLoader@153f5a29                                                       

Location:                                                                                           
/Users/lioswong/dev/source/dubbo/dubbo-common/target/classes/                                       

/*
 * Decompiled with CFR.
 * 
 * Could not load the following classes:
 *  com.alibaba.dubbo.rpc.service.EchoService
 *  org.apache.dubbo.common.bytecode.ClassGenerator
 *  org.apache.dubbo.common.bytecode.ClassGenerator$DC
 */
package org.apache.dubbo.common.bytecode;

import com.alibaba.dubbo.rpc.service.EchoService;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import org.apache.dubbo.common.bytecode.ClassGenerator;
import org.apache.dubbo.demo.DemoService;

public class proxy0
implements ClassGenerator.DC,
EchoService,
DemoService {
    public static Method[] methods;
    private InvocationHandler handler;

    @Override
    public String sayHello(String string) {
        Object[] arrobject = new Object[]{string};
        Object object = this.handler.invoke(this, methods[0], arrobject);
        return (String)object;
    }

    public Object $echo(Object object) {
        Object[] arrobject = new Object[]{object};
        Object object2 = this.handler.invoke(this, methods[1], arrobject);
        return object2;
    }

    public proxy0() {
    }

    public proxy0(InvocationHandler invocationHandler) {
        this.handler = invocationHandler;
    }
}

Affect(row-cnt:1) cost in 571 ms.
```
上面简单介绍arthas使用.

#### 进阶使用 
可参考官方[中文文档](https://alibaba.github.io/arthas/advanced-use.html)
