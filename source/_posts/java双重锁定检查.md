---
title: java双重锁定检查
date: 2019-04-01 00:30:59
tags:
- java
- 单例
categories:
- java   
copyright: true #版权声明开启    
---
在阅读dubbo源码时,很多类似如下代码:
```
        Object instance = holder.get();
        if (instance == null) {
            synchronized (holder) {
                instance = holder.get();
                if (instance == null) {
                    instance = createExtension(name);
                    holder.set(instance);
                }
            }
        }
```
上面的代码保证对象instance唯一,如果上面代码改写成:
```
        Object instance = holder.get();
        instance = holder.get();
            if (instance == null) {
                instance = createExtension(name);
                holder.set(instance);
            }

```
这样显然是在多线程下非安全的,若两个线程A、B,A发现instance为空,然后执行createExtension方法创建对象,此时cpu分配给现场A的时间片已经用完了,线程A让出cpu,线程B也执行到该方法块,发现instance为空,也执行createExtension方法创建对象,这样会导致instance对象被重复创建. 
再改写成:
```
        Object instance = holder.get();
        synchronized (holder) {
        instance = holder.get();
            if (instance == null) {
                instance = createExtension(name);
                holder.set(instance);
            }
        }
``` 
这样虽然可以保证对象的唯一性,但是存在同步锁性能开销问题,因此人们想出"双重锁定检查(Double-checked locking)"来解决该问题:首先检查对象是否为空,不为空则不需要创建,若为空则待创建,然后通过加锁创建对象,这样可以大大降低同步锁带来的性能开销问题.

> 参考文章  

1. [https://blog.csdn.net/tuhooo/article/details/84577996](https://blog.csdn.net/tuhooo/article/details/84577996)
