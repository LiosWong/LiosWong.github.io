---
title: GCP搭建V2ray服务
date: 2019-03-06 01:24:09
tags:
- GCP
- V2ray
- 科学上网
categories:
- 科学上网
copyright: true #版权声明开启
---
由于之前使用的virmach vps,搭建的v2ray服务,首先来看下配置:
```
•   512MB RAM
•   20GB Disk
•   500GB Bandwidth @ 1 Gbps
•   Shared Intel HT CPU 2 Cores @ 1.5GHz
•   1x IPv4 Addresses
```
是最低配版的服务器,而且不够稳定,这次通过GCP搭建V2ray服务,首先得有google账号,然后在[https://cloud.google.com/free/](https://cloud.google.com/free/)注册,可以获得300美金赠金,12月内可畅享GCP,再到[https://console.cloud.google.com](https://console.cloud.google.com)新建``Project``并关联结算账户.由于我没有申请GCP服务,用的是同学的账号,省去了前面的一部分流程,下面简单介绍下配置、搭建流程.
#### 创建VM实例  
![https://note.youdao.com/yws/api/personal/file/WEB7368471975985095dcd0b25b92a94bb6?method=download&shareKey=fc85e82ea39869353c28aa058bd46e5c](https://note.youdao.com/yws/api/personal/file/WEB7368471975985095dcd0b25b92a94bb6?method=download&shareKey=fc85e82ea39869353c28aa058bd46e5c)
![https://note.youdao.com/yws/api/personal/file/WEB165db1e068be8d3e88f7af199b3ff17b?method=download&shareKey=0206137fd63217f96266d1b42e839a72](https://note.youdao.com/yws/api/personal/file/WEB165db1e068be8d3e88f7af199b3ff17b?method=download&shareKey=0206137fd63217f96266d1b42e839a72)
服务器最好选择香港、台湾或者日本,离大陆较近,TTL较小,速度更快,然后再防火墙处勾选HTTP流量.创建完之后,回到首页会看到Project、实例:
![https://note.youdao.com/yws/api/personal/file/WEBbaabf5d35d7dbb7e9fc95cce701dc06a?method=download&shareKey=8cf7ca4496a370c96524734a1fffe985](https://note.youdao.com/yws/api/personal/file/WEBbaabf5d35d7dbb7e9fc95cce701dc06a?method=download&shareKey=8cf7ca4496a370c96524734a1fffe985)
#### 防火墙规则、外部IP地址  
![https://note.youdao.com/yws/api/personal/file/WEBd0417df3e1a4d541e99717cbc41cb760?method=download&shareKey=60cad63353b81075e15464104044f580](https://note.youdao.com/yws/api/personal/file/WEBd0417df3e1a4d541e99717cbc41cb760?method=download&shareKey=60cad63353b81075e15464104044f580)
注意在添加出站防火墙规则时,目标是所有实例
![https://note.youdao.com/yws/api/personal/file/WEB891d0bd5a2a5ba500ef54e0fb49c85ca?method=download&shareKey=e9b9497f365c873baa1b577413d1a714](https://note.youdao.com/yws/api/personal/file/WEB891d0bd5a2a5ba500ef54e0fb49c85ca?method=download&shareKey=e9b9497f365c873baa1b577413d1a714)
在配置当前实例IP类型选择静态
####   配置服务器、一键安装V2ray
* 配置  
首先需要在网页打开SSH会话窗口,登录服务器后:
```
sudo -i  #切换用户
vi /etc/ssh/sshd_config
```
修改sshd_config文件:
```
# Authentication:
PermitRootLogin yes //开启root用户访问
# Change to no to disable tunnelled clear text passwords
PasswordAuthentication yes //开启密码登陆
```
修改后执行``passwd root``重置root密码,然后再重启ssh服务:
``/etc/init.d/ssh restart``
此时可以ssh在本地通过密码登录服务器
可以安装ufw(``apt-get install ufw`)关闭防火墙(``ufw disable``),实际没有多大意义

* 安装V2ray服务  
执行``source <(curl -sL https://git.io/fNgqx)`,可以一键安装V2ray,完成后在终端输入V2ray,可以通过界面化操作,使用起来很方便,V2ray安装路径信息:
```
/usr/bin/v2ray/v2ray：V2Ray 程序
/usr/bin/v2ray/v2ctl：V2Ray 工具
/etc/v2ray/config.json：配置文件
/usr/bin/v2ray/geoip.dat：IP 数据文件
/usr/bin/v2ray/geosite.dat：域名数据文件
```
其中``config.json``文件是服务配置文件,以上的一键化脚本来自[https://github.com/Jrohy/multi-v2ray](https://github.com/Jrohy/multi-v2ray),当然网上还有很多配置脚本.配置完成之后,还可以通过该界面化生成客户端配置json,把客户端配置json copy到客户端配置condig.json中即可,手机V2ray客户端:[v2rayNG](https://github.com/2dust/v2rayNG),mac客户端:[v2ray-core](https://github.com/v2ray/v2ray-core)  
V2ray服务完全可以根据官方文档完成,而且网上有丰富的v2ray配置模板,可搭建出更快、更稳定的V2ray服务!最后感谢磊哥提供强大的GCP云服务器,让速度更快更稳定!

> 参考资料

1. [https://cloud.google.com/vpc/docs/](https://cloud.google.com/vpc/docs/)
2. [https://www.flyzy2005.com/v2ray/how-to-build-v2ray/](https://www.flyzy2005.com/v2ray/how-to-build-v2ray/)
3. [https://github.com/KiriKira/vTemplate](https://github.com/KiriKira/vTemplate)
4. [https://www.v2ray.com/](https://www.v2ray.com/)
5. [https://toutyrater.github.io/](https://toutyrater.github.io/)
6. [https://github.com/2dust/v2rayNG/releases](https://github.com/2dust/v2rayNG/releases)
7. [https://github.com/Jrohy/multi-v2ray](https://github.com/Jrohy/multi-v2ray)
8. [https://blog1.jyzzj.online/?p=2000](https://blog1.jyzzj.online/?p=2000)
