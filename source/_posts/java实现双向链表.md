---
title: java实现双向链表
date: 2019-08-16 15:00:50
tags:
- java
- 数据结构
- 链表长度
categories:
- 数据结构   
copyright: true #版权声明开启    
---
双向链表，又称为双链表，是链表的一种，它的每个数据结点中都有两个指针，分别指向直接后继和直接前驱。所以，从双向链表中的任意一个结点开始，都可以很方便地访问它的前驱结点和后继结点。一般我们都构造双向循环链表。[--维基百科](https://zh.wikipedia.org/wiki/双向链表)  
下面用Java实现不具有双端性质的双向链表.
```
package com.lios.algorithm;
import java.util.Objects;
/**
 * @author LiosWong
 * @description 双向链表
 * @date 2019-08-15 17:00
 */
public class My2NodeList {

    private Node head = null;

    class Node {
        private Integer data;
        private Node preNode;
        private Node nextNode;

        public Node(Integer data) {
            this.data = data;
        }

        public Integer getData() {
            return data;
        }

        public Node setData(Integer data) {
            this.data = data;
            return this;
        }

        public Node getPreNode() {
            return preNode;
        }

        public Node setPreNode(Node preNode) {
            this.preNode = preNode;
            return this;
        }

        public Node getNextNode() {
            return nextNode;
        }

        public Node setNextNode(Node nextNode) {
            this.nextNode = nextNode;
            return this;
        }
    }

    // 尾部插入节点
    public Node addNodeLast(Integer data) {
        Node node = new Node(data);
        if (head == null) {
            this.head = node;
            return head;
        }

        Node temp = head;

        while (temp.nextNode != null) {
            temp = temp.nextNode;
        }

        temp.nextNode = node;
        node.preNode = temp;
        return node;
    }

    // 首部插入节点,注意和尾插法的区别,尾插法需要根据head找到最后的节点,而首插法根据head就能操作
    public Node addNodeFirst(Integer data) {
        Node node = new Node(data);
        if (head == null) {
            head = node;
            return head;
        }
        node.nextNode = head;
        head.preNode = node;
        head = node;
        return head;
    }

    // 链表长度
    public Integer getNodeLength() {
        Integer lenght = 0;
        Node temp = head;
        while (temp != null) {
            temp = temp.nextNode;
            lenght++;
        }
        return lenght;
    }

    // 查找前驱元素
    public Integer queryPreNode(Integer data) {
        Node temp = head;
        while (temp != null) {
            if (temp.data.equals(data)) {
                if (temp.preNode == null) {
                    return null;
                }
                return temp.preNode.data;
            }
            temp = temp.nextNode;
        }
        return null;
    }

    // 查找后驱元素
    public Integer queryAfterNode(Integer data) {
        Node temp = head;
        while (temp != null) {
            if (temp.data.equals(data)) {
                if (temp.nextNode == null) {
                    return null;
                }
                return temp.nextNode.data;
            }
            temp = temp.nextNode;
        }
        return null;
    }

    // 删除第几个节点
    public void deleteByIndex(Integer index) {
        if (index < 1 || index > getNodeLength()) {
            return;
        }

        Node temp = head;
        Integer flag = 1;

        while (temp != null) {
            if (Objects.equals(flag, index)) {

                // 删除首节点
                if (temp.preNode == null) {
                    if (temp.nextNode != null) {
                        head = temp.nextNode;
                        head.preNode = null;
                        temp = null;
                        break;
                    }
                    temp = null;
                    break;
                }

                if (temp.nextNode == null) {
                    Node pre = temp.preNode;
                    pre.nextNode = null;
                    temp = null;
                    break;

                }

                Node pre = temp.preNode;
                Node next = temp.nextNode;

                pre.nextNode = next;
                next.preNode = pre;

                temp = null;
            }
            if (temp != null) {
                temp = temp.nextNode;
            }
            flag++;
        }

    }

    // 遍历链表打印所有节点
    public void printNodeList() {
        Node temp = head;
        while (temp != null) {
            System.out.println("元素:" + temp.data);
            temp = temp.nextNode;
        }
    }

    public static void main(String[] args) {

        My2NodeList my2NodeList = new My2NodeList();

        my2NodeList.addNodeLast(1);
        my2NodeList.addNodeLast(2);
        my2NodeList.addNodeLast(3);
        my2NodeList.addNodeLast(4);

//        my2NodeList.addNodeFirst(1);
//        my2NodeList.addNodeFirst(2);
//        my2NodeList.addNodeFirst(3);
//        my2NodeList.addNodeFirst(4);

        System.out.println("链表长度:" + my2NodeList.getNodeLength());
        
        my2NodeList.printNodeList();

        System.out.println("查找前驱元素:" + my2NodeList.queryPreNode(1));
        System.out.println("查找后驱元素:" + my2NodeList.queryAfterNode(2));

        my2NodeList.deleteByIndex(3);

        my2NodeList.printNodeList();
    }
}
```
