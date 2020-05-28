---
title: 记录xpath解析html的一个坑
date: 2020-05-14 10:07:23
tags:
- xpath
- 爬虫
categories:
- xpath   
---
使用xpath解析表格时，个别``td``标签内容为空，导致解析出来的数组列数有问题，进而在写入csv文件时，数据错位。
解决的办法用占位符填补空白:
```
text.replace(r'<td style="white-space: pre-wrap;"></td>',
                               '<td style="white-space: pre-wrap;">None</td>')
```

> [https://lioswong.github.io/2020/05/10/%E8%A7%A3%E6%9E%90html%E9%A1%B5%E9%9D%A2%E5%AF%BC%E5%87%BAcsv%E6%96%87%E4%BB%B6%E8%84%9A%E6%9C%AC/](https://lioswong.github.io/2020/05/10/%E8%A7%A3%E6%9E%90html%E9%A1%B5%E9%9D%A2%E5%AF%BC%E5%87%BAcsv%E6%96%87%E4%BB%B6%E8%84%9A%E6%9C%AC/)
