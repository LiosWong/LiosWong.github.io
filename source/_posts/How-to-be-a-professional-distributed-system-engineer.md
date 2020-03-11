---
title: How to be a professional distributed system engineer
date: 2020-03-08 13:58:47
tags:
- java
- jvm
- Refactor
- Design
- linux
- Computer science
- Effective
- Performance
- Distributed Related
categories:
- 技术书籍   
---
If you want to get better at programming, there are two things you need to do:  
Write codes and read books.  
The following readings are my preferred references, please feel free to sink in them.  

---
### Basic
##### Java & Jvm  
[Core Java Volume I & Volume II](https://www.amazon.com/Core-Java-I--Fundamentals-9th/dp/0137081898/ref=sr_1_15?s=books&ie=UTF8&qid=1474871593&sr=1-15&keywords=thinking+in+java)  
[Head First Java](https://www.amazon.com/Head-First-Java-Kathy-Sierra/dp/0596009208/ref=pd_sim_14_5?ie=UTF8&pd_rd_i=0596009208&pd_rd_r=SPRXGS2PZVAYA6XYPH7D&pd_rd_w=2Hl6x&pd_rd_wg=os22k&psc=1&refRID=SPRXGS2PZVAYA6XYPH7D)  
[Java Concurrency in Practice](https://www.amazon.com/Java-Concurrency-Practice-Brian-Goetz/dp/0321349601/ref=pd_rhf_dp_s_cp_2ie=UTF8&pd_rd_i=0321349601&pd_rd_r=WX4CZQ2FAMC0N206EP3N&pd_rd_w=APm7x&pd_rd_wg=wv2aR&psc=1&refRID=WX4CZQ2FAMC0N206EP3N)  
[Programming Concurrency on the JVM: Mastering Synchronization, STM, and Actors](https://www.amazon.com/Programming-Concurrency-JVM-Mastering-Synchronization/dp/193435676X/ref=sr_1_5?ie=UTF8&qid=1474944772&sr=8-5&keywords=jvm)  
[Java Performance: The Definitive Guide](https://www.amazon.com/Java-Performance-Definitive-Scott-Oaks/dp/1449358454/ref=sr_1_1?ie=UTF8&qid=1474944772&sr=8-1&keywords=jvm)  
[Effective Java 3rd Edition](https://www.amazon.com/Effective-Java-Joshua-Bloch-ebook/dp/B078H61SCH)

<!--
1. java核心技术
2. Head First Java
3. Java并发编程实践
4. Programming Concurrency on the JVM：Mastering Synchronization, STM, and Actors
5. Java性能权威手册
6. Effective Java 3rd Edition
 
-->

##### Refactor & Design
[Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882/ref=pd_rhf_dp_s_cp_4?ie=UTF8&pd_rd_i=0132350882&pd_rd_r=WX4CZQ2FAMC0N206EP3N&pd_rd_w=APm7x&pd_rd_wg=wv2aR&psc=1&refRID=WX4CZQ2FAMC0N206EP3N)  
[Refactoring: Improving the Design of Existing Code](https://www.amazon.com/Refactoring-Improving-Design-Existing-Code/dp/0201485672/ref=pd_sim_14_7?ie=UTF8&pd_rd_i=0201485672&pd_rd_r=E682SHZVPNGKEEGQZAEN&pd_rd_w=vnwpP&pd_rd_wg=L4EFb&psc=1&refRID=E682SHZVPNGKEEGQZAEN)  
[Head First Design Patterns](https://www.amazon.com/Head-First-Design-Patterns-Freeman/dp/0596007124/ref=pd_rhf_dp_s_cp_1?ie=UTF8&pd_rd_i=0596007124&pd_rd_r=WX4CZQ2FAMC0N206EP3N&pd_rd_w=APm7x&pd_rd_wg=wv2aR&psc=1&refRID=WX4CZQ2FAMC0N206EP3N)  
[The Design of Design: Essays from a Computer Scientist](https://www.amazon.com/Design-Essays-Computer-Scientist/dp/0201362988/ref=sr_1_1?ie=UTF8&qid=1474952279&sr=8-1&keywords=The+Design+of+Design%3A+Essays+from+a+Computer+Scientist)  
[Pattern-Oriented Software Architecture](https://www.amazon.com/s/ref=nb_sb_noss_2?url=search-alias%3Daps&field-keywords=Pattern-Oriented+Software+Architecture)  
[Patterns of Enterprise Application Architecture](https://www.amazon.com/Patterns-Enterprise-Application-Architecture-Martin/dp/0321127420/ref=sr_1_6?ie=UTF8&qid=1474952693&sr=8-6&keywords=Pattern-Oriented+Software+Architecture)  
[Applying UML and Patterns : An Introduction to Object-Oriented Analysis and Design and Iterative Development](https://www.amazon.com/Applying-UML-Patterns-Introduction-Object-Oriented/dp/0131489062/ref=sr_1_1?ie=UTF8&qid=1474952990&sr=8-1&keywords=Applying+UML+and+Patterns)
<!--
1. 
-->
##### Software management & Agile practice
[The Pragmatic Programmer: From Journeyman to Master](https://www.amazon.com/Pragmatic-Programmer-Journeyman-Master/dp/020161622X/ref=pd_sim_14_7?ie=UTF8&pd_rd_i=020161622X&pd_rd_r=SPRXGS2PZVAYA6XYPH7D&pd_rd_w=2Hl6x&pd_rd_wg=os22k&psc=1&refRID=SPRXGS2PZVAYA6XYPH7D)  
[The Mythical Man-Month: Essays on Software Engineering,Anniversary Edition](https://www.amazon.com/Mythical-Man-Month-Software-Engineering-Anniversary/dp/0201835959/ref=sr_1_1?ie=UTF8&qid=1474952367&sr=8-1&keywords=The+Mythical+Man-Month%3A+Essays+on+Software+Engineering%2CAnniversary+Edition)  
[Peopleware: Productive Projects and Teams](https://www.amazon.com/Peopleware-Productive-Projects-Teams-3rd/dp/0321934113/ref=sr_1_1?ie=UTF8&qid=1474952492&sr=8-1&keywords=Peopleware%3A+Productive+Projects+and+Teams)
##### Linux internal
[The Linux Programming Interface: A Linux and UNIX System Programming Handbook](https://www.amazon.com/Linux-Programming-Interface-System-Handbook/dp/1593272200/ref=sr_1_4?s=books&ie=UTF8&qid=1474871802&sr=1-4&keywords=linux&refinements=p_72%3A1250221011)  
[Internetworking with TCP/IP](https://www.amazon.com/Internetworking-TCP-Vol-1-Principles-Architecture/dp/0130183806/ref=pd_sim_14_2?ie=UTF8&pd_rd_i=0130183806&pd_rd_r=R1SH3SQ0SYVFPJQXPNE5&pd_rd_w=5p0ox&pd_rd_wg=knykx&psc=1&refRID=R1SH3SQ0SYVFPJQXPNE5)  
[Unix Network Programming](https://www.amazon.com/Unix-Network-Programming-Sockets-Networking/dp/0131411551/ref=sr_1_1?s=books&ie=UTF8&qid=1474872220&sr=1-1&keywords=Unix+Network+Programming)
##### Computer science
[The Art of Computer Programming](https://www.amazon.com/Art-Computer-Programming-Vol-Fundamental/dp/0201896834/ref=sr_1_2?ie=UTF8&qid=1474952215&sr=8-2&keywords=The+Art+of+Computer+Programming)  
[Introduction to Algorithms](https://www.amazon.com/Introduction-Algorithms-3rd-MIT-Press/dp/0262033844/ref=sr_1_1?ie=UTF8&qid=1475060034&sr=8-1&keywords=algorithm)
##### Effective
[The Seven Habits of Highly Effective People](https://www.amazon.com/Habits-Highly-Effective-People-Powerful/dp/1451639619/ref=sr_1_1?s=books&ie=UTF8&qid=1476079772&sr=1-1&keywords=The+Seven+Habits+of+Highly+Effective+People)  
[Pomodoro Technique Illustrated](https://www.amazon.com/Pomodoro-Technique-Illustrated-Pragmatic-Life/dp/1934356506/ref=sr_1_1?s=books&ie=UTF8&qid=1476080242&sr=1-1&keywords=Pomodoro+Technique+Illustrated)
### Advanced
---
##### Performance
[Systems Performance: Enterprise and the Cloud](https://www.amazon.com/Systems-Performance-Enterprise-Brendan-Gregg/dp/0133390098/ref=sr_1_1?ie=UTF8&qid=1474953097&sr=8-1&keywords=systems+performance)  
[High performance browser networking](https://www.amazon.com/High-Performance-Browser-Networking-performance/dp/1449344763/ref=sr_1_1?ie=UTF8&qid=1474953244&sr=8-1&keywords=High+performance+browser+networking)  
[Computer Systems: A Programmer's Perspective](https://www.amazon.com/Computer-Systems-Programmers-Perspective-3rd/dp/013409266X/ref=sr_1_1?ie=UTF8&qid=1474953535&sr=8-1&keywords=Computer+Systems%3A+A+Programmer%27s+Perspective)
##### Distributed Related
[Programming Distributed Computing Systems: A Foundational Approach](https://www.amazon.com/Programming-Distributed-Computing-Systems-Foundational/dp/0262018985/ref=sr_1_7?s=books&ie=UTF8&qid=1539845327&sr=1-7&keywords=distributed+system)  
[Distributed Systems: Concepts and Design (5th Edition)](https://www.amazon.com/Distributed-Systems-Concepts-Design-5th/dp/0132143011/ref=sr_1_6?s=books&ie=UTF8&qid=1539845327&sr=1-6&keywords=distributed+system)


> #### 原文

[https://github.com/apache/rocketmq/issues/494](https://github.com/apache/rocketmq/issues/494)
