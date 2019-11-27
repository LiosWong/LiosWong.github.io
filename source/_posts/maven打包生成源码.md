---
title: maven打包生成源码
date: 2019-11-24 21:56:27
tags:
- maven
categories:
- maven
copyright: true #版权声明开启        
---
开发中,项目A中的模块需要打包给项目B用,在调试B时,发现A中的包的源码下载失败,报错:
```
上午10:37 Cannot download sources
Sources not found for:
com.xxxxxx.xx.base:xxxx-log:1.1.4.4-20191124.023005-49
```
开始怀疑是打的包问题,到远程仓库看了也没发现什么问题,idea检查也没问题,再去A中看maven配置,没有配置源码包插件,所以加入项目的配置即可:
```
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-source-plugin</artifactId>
                <version>3.0.0</version>
                <executions>
                    <execution>
                        <id>attach-sources</id>
                        <phase>verify</phase>
                        <goals>
                            <goal>jar-no-fork</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
```
往往我们打包都不会把源码打上去.如果想配置生成Javadoc包,加入插件即可:
```
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-javadoc-plugin</artifactId>
            <version>2.10.4</version>
            <configuration>
                <encoding>UTF-8</encoding>
                <aggregate>true</aggregate>
                <charset>UTF-8</charset>
                <docencoding>UTF-8</docencoding>
            </configuration>
            <executions>
                <execution>
                    <id>attach-javadocs</id>
                    <goals>
                        <goal>jar</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>

```
