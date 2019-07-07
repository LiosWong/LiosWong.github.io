---
title: scrapy爬取1024种子
date: 2019-02-17 23:26:22
tags:
- python
- scrapy
- 爬虫 
categories:
- python   
copyright: true #版权声明开启 
top: 5010 
---
1024不必多说,老司机都懂,本文介绍scrapy爬取1024种子,代码不到50行!*Scrapy，Python开发的一个快速、高层次的屏幕抓取和web抓取框架，用于抓取web站点并从页面中提取结构化的数据。Scrapy用途广泛，可以用于数据挖掘、监测和自动化测试。* 关于scrapy用下图来说明即可(图片来自[https://cuiqingcai.com/3472.html](https://cuiqingcai.com/3472.html)  )

![https://note.youdao.com/yws/api/personal/file/WEB66810b6bcef1257b8ef71ff9bbbfe9b6?method=download&shareKey=d2785fa786b89417a34819ad7c832bf6](https://note.youdao.com/yws/api/personal/file/WEB66810b6bcef1257b8ef71ff9bbbfe9b6?method=download&shareKey=d2785fa786b89417a34819ad7c832bf6)

scrapy最好的方式通过[官方文档](https://docs.scrapy.org/en/latest/),以及社区贡献的[中文文档](https://scrapy-chs.readthedocs.io/zh_CN/latest/)去学习,使用起来也非常简单,当然功能非常强大!
首先创建scrapy项目、CaoliuSpider,下面是创建的爬虫代码:
```
# -*- coding: utf-8 -*-
import scrapy
import json
from LiosScrapy.items import CaoLiuItem
from scrapy.http.request import Request
import sys

class CaoliuSpider(scrapy.Spider):
    # 爬虫名称
    name = 'caoliu'
    # 涉及到敏感网站地址
    allowed_domains = ['网站地址']
    start_urls = ['请求地址']
    # 列表解析
    def parse(self, response):
        # 通过xpath提取
        node_list = response.xpath("//td[@class='tal']")
        next_page = response.xpath("//a[text()='下一頁']/@href").extract()[0]
        # 遍历列表获取种子名称、详情页URL
        for node in node_list:
            if not len(node.xpath('./h3/a/text()').extract()) or not len(node.xpath('./h3/a/@href').extract()):
                continue
            fileName = node.xpath('./h3/a/text()').extract()[0]
            listUrl = node.xpath('./h3/a/@href').extract()[0]
            # 通过Request meta传递参数
            yield scrapy.Request(self.allowed_domains[0] + "/" + listUrl, callback=self.parseDetail, meta={'fileName': fileName}, dont_filter=True)
        if next_page not in self.allowed_domains[0]:
            yield scrapy.Request(self.allowed_domains[0] + "/" + next_page,callback=self.parse,dont_filter=True)

    # 解析详情页
    def parseDetail(self, response):
        fileName = response.meta['fileName']
        node_list = response.xpath(
            '//a[@style="cursor:pointer;color:#008000;"]')
        for node in node_list:
            yield scrapy.Request(node.xpath('./@href').extract()[0], callback=self.parseDownLoanUrl, meta={'fileName': fileName}, dont_filter=True)
            # 默认获取第一条种子下载地址
            break

    # 拼接种子、下载
    def parseDownLoanUrl(self, response):
        fileName = response.meta['fileName']
        refNode = response.xpath("//input[@type='hidden' and @name='ref']/@value")[0].extract()
        reffNode = response.xpath("//input[@type='hidden' and @name='reff']/@value")[0].extract()
        torrentUrl = "http://www.rmdown.com/download.php?" + "ref="+str(refNode)+ "&reff="+str(reffNode)
        item = CaoLiuItem()
        item['file_urls'] = torrentUrl
        item['file_name'] = fileName+".torrent"
        yield item
```
Item文件中的代码:
```
class CaoLiuItem(scrapy.Item):
    # 文件名称
    file_name = scrapy.Field()
    # 指定文件下载的连接
    file_urls = scrapy.Field()
    #文件下载完成后会往里面写相关的信息
    files = scrapy.Field()
```
管道文件中的代码:
```
# 继承FilesPipeline,用于下载文件
class CaoLiuPipeline(FilesPipeline):
    def get_media_requests(self, item, info):
        file_url = item['file_urls']
        meta = {'filename': item['file_name']}
        # 交给调度器发送请求
        yield Request(url=file_url, meta=meta)
    # 自定义下载文件的名称    
    def file_path(self, request, response=None, info=None):
        return request.meta.get('filename','')
```
记得再settings文件中添加管道、以及设置文件存储路径:
```
ITEM_PIPELINES = {
   # 'LiosScrapy.pipelines.LiosscrapyPipeline': 300,
   'LiosScrapy.pipelines.CaoLiuPipeline': 2
}
FILES_STORE = '/Users/wenchao.wang/LiosWang/sublimetext/LiosScrapy/data/caoliu'
```
然后执行命令:
```
scrapy crawl caoliu
```
终端输出:
![https://note.youdao.com/yws/api/personal/file/WEB99a50db27fab136be8085afc6fb1bdc8?method=download&shareKey=cdf5c51f1ae1ac0d9bb56d97e3b5d6af](https://note.youdao.com/yws/api/personal/file/WEB99a50db27fab136be8085afc6fb1bdc8?method=download&shareKey=cdf5c51f1ae1ac0d9bb56d97e3b5d6af)
打开存储文件夹,发现种子源源不断下载:
![https://note.youdao.com/yws/api/personal/file/WEBd6850c267e5c6705108f107032b9fddb?method=download&shareKey=4b49e98d7022de6ee647ec613d29551b](https://note.youdao.com/yws/api/personal/file/WEBd6850c267e5c6705108f107032b9fddb?method=download&shareKey=4b49e98d7022de6ee647ec613d29551b)
scrapy的功能非常强大,以上运用其简单爬取网页信息,**作者**只用于学习.最后欢迎感兴趣的朋友欢迎一起讨论学习scrapy.
