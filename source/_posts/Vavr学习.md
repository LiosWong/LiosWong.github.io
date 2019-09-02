---
title: Vavr学习
date: 2019-09-01 23:07:54
tags:
- java
- java8
- Vavr
categories:
- java   
copyright: true #版权声明开启    
---
Vavr是java8函数式库，提供了非常丰富的API，便于开发使用。
#### 引入依赖
```
<dependency>
    <groupId>io.vavr</groupId>
    <artifactId>vavr</artifactId>
    <version>0.9.0</version>
</dependency>
```
#### 使用
下面通过case简单介绍Option、Tuple(元组)、Try、Function、Collections、Lazy、Match。

* Option:  用来解决空指针异常，减少ifelse语句
* Tuple(元组): Tuple是不可变的，用于保存不同类型对象的数据结构
* Try: 用于包装可能产生异常的代码
* Function: Java8的函数式接口最多有两个参数，Vavr最多可有8个参数
* Collections: Vavr可创建集合，且提供更多的功能操作集合
* Lazy: Lazy是一个容器，表示一个延迟计算的值。计算被推迟，直到需要时才计算。此外，计算的值被缓存或存储起来，当需要时被返回，而不需要重复计算。
* 模式匹配Matching: 通过过Match方法替换switch块。每个条件检查都通过Case方法调用来替换。 $()来替换条件并完成表达式计算得到结果。

```
package com.lios;

import io.vavr.*;
import io.vavr.control.Option;
import io.vavr.control.Try;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

public class VavrTest {

    static Integer[] l = {3, 4, 5, 1, 2};

    public static void main(String[] args) {
        lazy();

        list(l);

        func();

        try1();

        tuple();

        option(l);
    }


    /**
     * 模式匹配
     *
     * @param key
     * @return
     */
    private static String match(String key) {
        String result = API.Match(key).of(
                API.Case(API.$("1"), "one"),
                API.Case(API.$("2"), "two"),
                API.Case(API.$("3"), "three")
        );
        return result;
    }

    /**
     * 延迟计算
     */
    private static void lazy() {
        Lazy lazy = Lazy.of(UUID::randomUUID);
        // 两次拿到结果值一样
        System.out.println(lazy.get());
        System.out.println(lazy.get());
    }

    /**
     * 集合操作
     *
     * @param array
     */
    private static void list(Integer[] array) {
        List<Integer> list = io.vavr.collection.List.of(array).toJavaList();

        Integer sum = io.vavr.collection.List.of(array).sum().intValue();

    }

    /**
     * 函数式接口
     */
    private static void func() {
        Function3<String, String, String, String> function3 = (a, b, c) -> a + b + c + "hello";

        String result = function3.apply("1", "2", "3");

        System.out.println(result);
    }

    /**
     * try
     */
    private static void try1() {
        Try r = Try.of(() -> {
            return 0 / 1;
        });
        System.out.println(r.isSuccess() + ";" + r.get());
        r.andFinallyTry(() -> {
            System.out.println("finally处理");
        });
    }

    /**
     * 元组Tuple
     */
    private static void tuple() {
        Tuple3<String, String, String> tuple = Tuple.of("a", "b", "c");
        System.out.println(tuple._1 + ";" + tuple._1());
        System.out.println(tuple._2 + ";" + tuple._2());
        System.out.println(tuple._3 + ";" + tuple._3());
    }

    /**
     * option
     *
     * @param array
     */
    private static void option(Integer[] array) {
        array = null;
        // of会构造None或Some对象
        Option.of(array).forEach(p -> {
            Arrays.stream(p).forEach(q -> {
                System.out.println(q.intValue());
            });
        });
    }

}
```

> 参考文章

1. [https://blog.csdn.net/liubenlong007/article/details/96730721](https://blog.csdn.net/liubenlong007/article/details/96730721)

2. [https://www.baeldung.com/vavr](https://www.baeldung.com/vavr)
3. [https://www.vavr.io/vavr-docs/](https://www.vavr.io/vavr-docs/)
