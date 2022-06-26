---
title: Spring源码之解析并注册BeanDefinition(一)
date: 2019-02-16 01:42:16
tags:
- java
- spring
- bean
categories:
- spring   
copyright: true #版权声明开启        
---
最近有空把Spring加载bean流程复习了一下,也乘机可以做个整理.首先还是看下入口代码,本文主要讲解析及注册BeanDefinition整体加载流程:
```
ClassPathXmlApplicationContext resource = new ClassPathXmlApplicationContext("app.xml");
```
ClassPathXmlApplicationContext的类图继承关系如下:
![https://note.youdao.com/yws/api/personal/file/WEB951df51be30c58c70a1d159bdfd9e037?method=download&shareKey=9fb6c37f10d34fb28acf1a1313a4cf8c](https://note.youdao.com/yws/api/personal/file/WEB951df51be30c58c70a1d159bdfd9e037?method=download&shareKey=9fb6c37f10d34fb28acf1a1313a4cf8c)
类图可以方便的清楚该类的继承关系,利于阅读源码.
一步步跟进去,AbstractApplicationContext中的refresh()方法,便是IOC容器初始化的入口,该方法中调用的obtainFreshBeanFactory()方法,是载入Bean定义的资源文件,该文是分析该类的调用流程,本文使用spring版本为==4.2.4.RELEASE==,obtainFreshBeanFactory()中调用了AbstractApplicationContext子类AbstractRefreshableApplicationContext#refreshBeanFactory中的refreshBeanFactory()方法,这是
委派设计模式,具体实现由子类做.下面是整个调用层次关系图:
![https://note.youdao.com/yws/api/personal/file/WEB3e9cb9f135000bc7dacc228a2197389b?method=download&shareKey=9211e80a040a597bb89758af17de2f55](https://note.youdao.com/yws/api/personal/file/WEB3e9cb9f135000bc7dacc228a2197389b?method=download&shareKey=9211e80a040a597bb89758af17de2f55)
在DefaultListableBeanFactory类中的registerBeanDefinition方法内,注册了BeanDefinition信息:
```
this.beanDefinitionMap.put(beanName, beanDefinition);
```
DefaultListableBeanFactory是Spring Bean加载中的核心类,现在不分析加载过程中细节,后面的章节会剖析.
