---
title: charles踩坑记录
date: 2019-11-11 15:03:41
tags:
- charles
categories:
- 工具   
copyright: true #版权声明开启       
---
#### 环境
1. charles v 4.2.8
2. MacBook Pro 
3. 手机一加6

#### 问题描述
使用charles抓手机上的包一直抓不到,手机上已经装了charles证书,而且重复装了很多次,还是不行

#### 解决

![https://note.youdao.com/yws/api/personal/file/WEB1a267a2d81820b6a79afd5d61aac7296?method=download&shareKey=dd6a1f5644e0c958a2622ebb9877399c](https://note.youdao.com/yws/api/personal/file/WEB1a267a2d81820b6a79afd5d61aac7296?method=download&shareKey=dd6a1f5644e0c958a2622ebb9877399c)

检查Proxy Settings的配置没有发现什么问题,
再检查SSL Proxying Settings:
![https://note.youdao.com/yws/api/personal/file/WEB2723e35e566573ed79da41131c8f2010?method=download&shareKey=ef22df54ea67fd4331e5a4c56916a45f](https://note.youdao.com/yws/api/personal/file/WEB2723e35e566573ed79da41131c8f2010?method=download&shareKey=ef22df54ea67fd4331e5a4c56916a45f)
SSL Proxying Settings配置也没发现问题,后面再检查Access Controll Setting发现里面配置了可用的IP段,猜想应该是这里引起的,修改成指定所有的ipv4、ipv6段:
![https://note.youdao.com/yws/api/personal/file/WEB9cf0957faf9120d4e55b34e762c6618e?method=download&shareKey=dd722afc63b9db082cd06067933f46bf](https://note.youdao.com/yws/api/personal/file/WEB9cf0957faf9120d4e55b34e762c6618e?method=download&shareKey=dd722afc63b9db082cd06067933f46bf)
然后就好了.

这个问题困扰了很久,之前一直怀疑是证书的问题,但是charles一直抓不到包,应该不是证书的问题,后面检查仔细charles配置发现了问题.
