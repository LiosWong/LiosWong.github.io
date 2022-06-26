---
title: hexo使用本地图片
date: 2019-11-28 18:16:20
tags:
- hexo
categories:
- hexo   
copyright: true #版权声明开启        
---
步骤如下:  
**1. post_asset_folder:true**  
配置_config.yml里面的``post_asset_folder:true``  
**2. 安装hexo-asset-image**  
```
npm install hexo-asset-image --save
```
**3. 插入图片**  
运行``hexo new "Redis深度探险梳理"``,
来生成md博文时,/source/_posts文件夹内除了``Redis深度探险梳理.md``文件还有一个同名的文件夹 ``Redis深度探险梳理`` ,把图片放入该文件夹,
然后在文章中引入:
```
![Redis](Redis深度探险梳理/Redis.png)
```
本地运行发现是OK的,但是deploy到github上,发现图片不能展示了,然后看html文件发现是文件路径问题,然后改成:
```
![Redis](Redis.png)
```
就好了.
