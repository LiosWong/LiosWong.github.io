---
title: mysql毫秒数丢失问题
date: 2019-10-17 11:10:07
tags:
- mysql
- 毫秒数丢失
categories:
- mysql   
copyright: true #版权声明开启    
---
开发过程中,前端传入时间'2019-10-10 23:59:59.600'入库后变成'2019-10-11 00:00:00',通过查询网上资料可知,mysql在``5.6.4``之前是不保存毫秒数的,在``5.6.4``之后的版本中毫秒数在低于500的时候会舍弃掉,大于等于500会进位,类似四舍五入.通过查当前的数据库版本在``5.6.4``之后:
```
select version();
`version()`
5.7.20-log
```
所以解决的方法就是设置日期的毫秒数,避免进位:
```
public static Date getDateInDay(Date date, int hour, int minute, int second){
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.set(Calendar.HOUR_OF_DAY, hour);
        c.set(Calendar.MINUTE, minute);
        c.set(Calendar.SECOND, second);
        //设置毫秒数，避免产生进位
        c.set(Calendar.MILLISECOND,0);
        return c.getTime();
    }
```

> 参考文章

1. [https://cloud.tencent.com/developer/article/1483417](https://cloud.tencent.com/developer/article/1483417)
