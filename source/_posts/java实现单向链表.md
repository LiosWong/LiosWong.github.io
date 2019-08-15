---
title: java实现单向链表
date: 2019-08-15 16:45:36
tags:
- java
- 数据结构
- 链表长度
categories:
- 数据结构   
copyright: true #版权声明开启    
---

链表（Linked list）是一种常见的基础数据结构，是一种线性表，但是并不会按线性的顺序存储数据，而是在每一个节点里存到下一个节点的指针(Pointer)。由于不必须按顺序存储，链表在插入的时候可以达到O(1)的复杂度，比另一种线性表顺序表快得多，但是查找一个节点或者访问特定编号的节点则需要O(n)的时间，而顺序表相应的时间复杂度分别是O(logn)和O(1)。  
使用链表结构可以克服数组链表需要预先知道数据大小的缺点，链表结构可以充分利用计算机内存空间，实现灵活的内存动态管理。但是链表失去了数组随机读取的优点，同时链表由于增加了结点的指针域，空间开销比较大。  
在计算机科学中，链表作为一种基础的数据结构可以用来生成其它类型的数据结构。链表通常由一连串节点组成，每个节点包含任意的实例数据（data fields）和一或两个用来指向上一个/或下一个节点的位置的链接（"links"）。链表最明显的好处就是，常规数组排列关联项目的方式可能不同于这些数据项目在记忆体或磁盘上顺序，数据的访问往往要在不同的排列顺序中转换。而链表是一种自我指示数据类型，因为它包含指向另一个相同类型的数据的指针（链接）。链表允许插入和移除表上任意位置上的节点，但是不允许随机存取。链表有很多种不同的类型：单向链表，双向链表以及循环链表。--[维基百科](https://zh.wikipedia.org/wiki/%E9%93%BE%E8%A1%A8)  
下面是关于单向链表的操作代码:
```
package com.lios.algorithm;
import java.util.Objects;
/**
 * @author LiosWong
 * @description
 * @date 2019-08-15 10:55
 */
public class MyNodeList {

    // 头节点
    private Node head = null;

    class Node {
        // 节点数据
        private int data;
        // 下一个节点的引用地址
        private Node next = null;

        public Node(int data) {
            this.data = data;
        }
    }

    // 增加节点
    public Node addNode(int data) {
        Node node = new Node(data);
        if (head == null) {
            head = node;
            return node;
        }
        Node temp = head;
        while (temp.next != null) {
            temp = temp.next;
        }
        temp.next = node;
        return node;
    }

    // 删除链表中第几个节点
    public void deleteNodeByIndex(int index) {
        int lenght = getNodeListLenght();
        if (index < 1 || index > lenght) {
            return;
        }

        Node temp = head;
        Node preNode = null;
        int flag = 1;
        while (temp != null) {
            if (Objects.equals(flag, index)) {
                // 若删除的头节点
                if (index == 1) {
                    head = temp.next;
                    temp = null;
                    return;
                }

                if (temp.next != null) {
                    preNode.next = temp.next;
                } else {
                    // 删除的尾节点
                    preNode.next = null;
                }
                temp = null;

            }
            if (temp != null) {
                preNode = temp;
                temp = temp.next;
            }
            flag++;
        }
    }

    // 删除指定节点
    public void deleteNodeByNode(Node node) {
        Node temp = head;
        // 若删除头元素
        if ((temp.next == null) && node.next == null) {
            head = null;
            return;
        }

        Node preNode = null;

        while (temp != null) {
            if (temp.next == head.next) {
                head = temp.next;
                temp = null;
                return;
            }
            if ((temp.next == node.next)) {
                preNode.next = temp.next;
                temp = null;
            }
            if (temp != null) {
                preNode = temp;
                temp = temp.next;
            }
        }
    }


    // 打印所有节点
    public void printNodeList() {
        Node temp = head;
        while (temp != null) {
            System.out.println("节点数据:" + temp.data);
            temp = temp.next;
        }
    }

    // 获取链表长度
    public int getNodeListLenght() {
        int length = 0;
        Node temp = head;
        while (temp != null) {
            ++length;
            temp = temp.next;
        }
        return length;
    }

    public static void main(String[] args) {
        MyNodeList myNodeList = new MyNodeList();
        Node node = myNodeList.addNode(1);
        myNodeList.addNode(2);
        myNodeList.addNode(3);
        myNodeList.addNode(4);
        myNodeList.addNode(5);

        myNodeList.printNodeList();

        System.out.println("链表长度:" + myNodeList.getNodeListLenght());

        myNodeList.deleteNodeByIndex(4);

        System.out.println("链表长度:" + myNodeList.getNodeListLenght());

        myNodeList.printNodeList();

        myNodeList.deleteNodeByNode(node);

        System.out.println("链表长度:" + myNodeList.getNodeListLenght());


        myNodeList.printNodeList();
    }

}
```
