---
title: java8 Optional使用
date: 2019-09-02 19:39:28
tags:
- java
- java8
categories:
- java   
copyright: true #版权声明开启    
---
Optional类是Java8进行空值判断处理的工具类,下面是该类提供的方法:
```
empty: 返回一个空的 Optional实例
filter: 如果一个值存在，并且该值给定的谓词相匹配时，返回一个 Optional描述的值，否则返回一个空的 Optional 
flatMap: 如果一个值存在，应用提供的 Optional映射函数给它，返回该结果，否则返回一个空的 Optional
get: 如果 Optional中有一个值，返回值，否则抛出 NoSuchElementException
isPresent(): 返回 true如果存在值，否则为 false
ifPresent(Consumer<? super T> consumer): 如果存在值，则使用该值调用指定的消费者，否则不执行任何操作
map: 如果存在一个值，则应用提供的映射函数，如果结果不为空，则返回一个 Optional结果的 Optional 
of: 返回具有 Optional的当前非空值的Optional
ofNullable: 返回一个 Optional指定值的Optional，如果非空，则返回一个空的 Optional 
orElse: 如果值存在返回，否则返回 other 
orElseGet: 如果值存在返回，否则调用 other并返回该调用的结果
orElseThrow: 如果值存在返回，否则抛出由提供的供应商创建的异常
```
示例:
```
       Boolean b = null;

        // 返回空的Option实例
        Optional empty = Optional.empty();

        b  = empty.isPresent();

        // b为空报错
        Optional option = Optional.of(b);

        // filter过滤
        Optional<Boolean> optional = Optional.ofNullable(b).filter(p->{
            return p.equals(Boolean.TRUE);
        });

        TestAEntity testAEntity = new TestAEntity();

        // map
        Optional<TestBEntity> optionalMap = Optional.ofNullable(testAEntity).map(p -> new TestBEntity().setId(1));

        // flatMap
        Optional<TestBEntity> optionalFlatMap = Optional.ofNullable(testAEntity).flatMap(p -> Optional.of(new TestBEntity().setId(2)));

        // orElse
        b = Optional.ofNullable(b).orElse(Boolean.FALSE);

        b = null;

        // orElseGet
        b = Optional.ofNullable(b).orElseGet(() -> {
            if (Boolean.TRUE) {
                return Boolean.TRUE;
            }
            ;
            return Boolean.FALSE;
        });

        // orElseThrow
        b = Optional.ofNullable(b).orElseThrow(() -> {
            throw new RuntimeException();
        });

        // ifPresent
        Optional.ofNullable(testAEntity).ifPresent(p -> {
            System.out.println(p.getName());
        });

        // 过滤后组装
        Optional options = Optional.ofNullable(testAEntity).filter(p -> {
            return Objects.nonNull(p.getId());
        }).map(p -> new TestBEntity().setId(3));
```

