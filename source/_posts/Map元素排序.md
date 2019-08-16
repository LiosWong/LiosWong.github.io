---
title: Map元素排序
date: 2019-08-17 00:31:04
tags:
- java
categories:
- java
copyright: true #版权声明开启        
---
开发中会遇到对Map元素排序的问题,下面介绍下如何根据key、value排序.  
##### key排序  
* 使用TreeMap的Comparator比较  
TreeMap默认是升序的,如果需要自定义排序规则,可以使用Comparator:
```
        Map<String, Integer> map = new TreeMap<String, Integer>(new Comparator<String>() {
            // 按照key排序
            @Override
            public int compare(String o1, String o2) {
                // 按照key降序排列
                return Integer.valueOf(o2).compareTo(Integer.valueOf(o1));
            }
        }) {
            {
                put("1", 9);
                put("3", 6);
                put("5", 2);
            }
        };
        
        for (Map.Entry c : map.entrySet()) {
            System.out.println(c.getKey() + "=" + c.getValue());
        }
```

* ``java.util.Collections``的sort方法  
```
        Map<String, Integer> map = new TreeMap<String, Integer>() {
            {
                put("1", 9);
                put("3", 6);
                put("5", 2);
            }
        };

        List<Map.Entry<String, Integer>> entryList = new ArrayList<Map.Entry<String, Integer>>(map.entrySet());

        Collections.sort(entryList, new Comparator<Map.Entry<String, Integer>>() {
            @Override
            public int compare(Map.Entry<String, Integer> o1, Map.Entry<String, Integer> o2) {
                // 根据key降序排列
                return Integer.valueOf(o2.getKey()).compareTo(Integer.valueOf(o1.getKey()));
            }
        });

        for (Map.Entry c : entryList) {
            System.out.println(c.getKey() + "=" + c.getValue());
        }
```

##### value排序

* ``java.util.Collections``的sort方法  
由上可知,对value排序也很容易实现:
```
        Map<String, Integer> map = new TreeMap<String, Integer>() {
            {
                put("1", 9);
                put("3", 6);
                put("5", 2);
            }
        };

        List<Map.Entry<String, Integer>> entryList = new ArrayList<Map.Entry<String, Integer>>(map.entrySet());

        Collections.sort(entryList, new Comparator<Map.Entry<String, Integer>>() {
            @Override
            public int compare(Map.Entry<String, Integer> o1, Map.Entry<String, Integer> o2) {
                // 根据value降序排列
                return o2.getValue().compareTo(o1.getValue());
            }
        });

        for (Map.Entry c : entryList) {
            System.out.println(c.getKey() + "=" + c.getValue());
        }
```

