---
title: clone
date: 2019-02-16 01:41:54
tags:
- clone
- java
categories:
- java   
copyright: true #版权声明开启       
---
> #### 简介  

实现Cloneable接口的类才可以被克隆,如果不实现该接口,调用Object clone方法会报``CloneNotSupportedException``:
 ```
 <p>
 * Invoking Object's clone method on an instance that does not implement the
 * <code>Cloneable</code> interface results in the exception
 * <code>CloneNotSupportedException</code> being thrown.
 <p>
 ```
 > #### 分类
 
 1. 浅克隆  
 指拷贝对象时仅拷贝对象本身中的基本变量,而不拷贝对象包含的引用指向的对象
 2. 深克隆  
 不仅拷贝对象本身中的基本变量，而且还拷贝对象中包含的引用指向的所有对象

> #### 说明

```
package com.lios.clone;

/**
 * @author LiosWong
 * @description
 * @date 2018/6/25 上午4:11
 */
public class Person implements Cloneable {
    private String name;

    private Worker worker;

    public Person(String name, Worker worker) {
        this.name = name;
        this.worker = worker;
    }

    public String getName() {
        return name;
    }

    public Person setName(String name) {
        this.name = name;
        return this;
    }

    @Override
    protected Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

    public static void main(String[] args) {
        Person p = new Person("lios", new Worker("worker", 25));
        Person p1 = p;
        System.out.println("p:toString:" + p + ",hashCode:" + p.hashCode() + ",Worker:" + p.getWorker().hashCode() + ",name=" + p.getName().hashCode());
        System.out.println("p1:toString:" + p1 + ",hashCode:" + p1.hashCode() + ",Worker:" + p1.getWorker().hashCode() + ",name=" + p1.getName().hashCode());
        System.out.println(p1);


        System.out.println("=====================");

        try {
            Person p2 = (Person) p.clone();
            System.out.println("p:Worker:name:"+p.getWorker().getName());
            System.out.println("p1:Worker:name:"+p1.getWorker().getName());
            System.out.println("p2:Worker:name:"+p2.getWorker().getName());


            System.out.println("p2:toString:" + p2 + ",hashCode:" + p2.hashCode() + ",Worker:" + p2.getWorker().hashCode() + ",name=" + p2.getName().hashCode());
            p.getWorker().setName("workp");
            p.setName("cc");
            System.out.println("p2:toString:" + p2 + ",hashCode:" + p2.hashCode() + ",Worker:" + p2.getWorker().hashCode() + ",name=" + p2.getName().hashCode());
            System.out.println("p:Worker:name:"+p.getWorker().getName());
            System.out.println("p1:Worker:name:"+p1.getWorker().getName());
            System.out.println("p2:Worker:name:"+p2.getWorker().getName());
            System.out.println("p:"+p.getName());
            System.out.println("p1:"+p1.getName());
            System.out.println("p2:"+p2.getName());
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }
    }

    public Worker getWorker() {
        return worker;
    }

    public Person setWorker(Worker worker) {
        this.worker = worker;
        return this;
    }

    public static class Worker implements Cloneable {
        private String name;
        private Integer age;

        public Worker(String name, Integer age) {
            this.name = name;
            this.age = age;
        }

        @Override
        protected Object clone() throws CloneNotSupportedException {
            return super.clone();
        }

        public String getName() {
            return name;
        }

        public Worker setName(String name) {
            this.name = name;
            return this;
        }

        public Integer getAge() {
            return age;
        }

        public Worker setAge(Integer age) {
            this.age = age;
            return this;
        }
    }
}
```
执行结果为:
```
p:toString:com.lios.clone.Person@2401f4c3,hashCode:604107971,Worker:123961122,name=3321889
p1:toString:com.lios.clone.Person@2401f4c3,hashCode:604107971,Worker:123961122,name=3321889
com.lios.clone.Person@2401f4c3
=====================
p:Worker:name:worker
p1:Worker:name:worker
p2:Worker:name:worker
p2:toString:com.lios.clone.Person@4926097b,hashCode:1227229563,Worker:123961122,name=3321889
p2:toString:com.lios.clone.Person@4926097b,hashCode:1227229563,Worker:123961122,name=3321889
p:Worker:name:workp
p1:Worker:name:workp
p2:Worker:name:workp
p:cc
p1:cc
p2:lios
```
发现p,p1所有的值都是一致的,当对象p中重置name属性的值、Worker属性中name的值后,p、p1、p2中属性Worker中name属性值都改变了且值相同,但是p2中的name属性值没有变化,下面用图描述:
![https://note.youdao.com/yws/api/personal/file/WEBc3012c388ab80da868f67a461b7023d5?method=download&shareKey=84a8b2485e2356be6e6fa18a91b6797f](https://note.youdao.com/yws/api/personal/file/WEBc3012c388ab80da868f67a461b7023d5?method=download&shareKey=84a8b2485e2356be6e6fa18a91b6797f)  
p1与p指向堆中的同一块内存区域,p2虽然与p、p1不是指向同一块内存区域,但是它们中的Worker属性都引用同一块内存区域,其实这就是<font color=#FF6347 size=3>浅克隆</font>,修改上面clone方法:
```
 @Override
    protected Object clone() throws CloneNotSupportedException {
         Person p = (Person) super.clone();
         p.worker = (Worker) p.getWorker().clone();
         return p;
    }
```
再执行,结果如下:
```
p:toString:com.lios.clone.Person@2401f4c3,hashCode:604107971,Worker:123961122,name=3321889
p1:toString:com.lios.clone.Person@2401f4c3,hashCode:604107971,Worker:123961122,name=3321889
com.lios.clone.Person@2401f4c3
=====================
p:Worker:name:worker
p1:Worker:name:worker
p2:Worker:name:worker
p2:toString:com.lios.clone.Person@4926097b,hashCode:1227229563,Worker:1982791261,name=3321889
p2:toString:com.lios.clone.Person@4926097b,hashCode:1227229563,Worker:1982791261,name=3321889
p:Worker:name:workp
p1:Worker:name:workp
p2:Worker:name:worker
p:cc
p1:cc
p2:lios
```
发现此时p2中属性Worker中的name属性值没有改变,仅仅p、p1中属性Worker中的name属性值改变了,图示:
![https://note.youdao.com/yws/api/personal/file/WEBe26613ea80dae7acc685ad9312704f38?method=download&shareKey=3e6af8ebb6ae3a40892d823c43ffc524](https://note.youdao.com/yws/api/personal/file/WEBe26613ea80dae7acc685ad9312704f38?method=download&shareKey=3e6af8ebb6ae3a40892d823c43ffc524)
上面就是<font color=#FF6347 size=3>深克隆</font>

> #### 总结

1. 对象被clone必须实现Cloneable接口
2. 深克隆需拷贝对象中包含的引用指向的所有对象
