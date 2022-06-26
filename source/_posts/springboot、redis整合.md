---
title: springboot、redis整合
date: 2019-02-16 01:42:16
tags:
- java
- spring
- redis
categories:
- spring   
copyright: true #版权声明开启        
---
#### redis安装 
   * 下载:sudo wget http://download.redis.io/releases/redis-3.2.6.tar.gz
      * 解压 ``sudo tar -zxvf redis-3.2.6.tar.gz``
      * 安装gcc ``sudo apt-get install gcc``
      * 编译、安装 
        ```
        sudo make
        sudo make install 
        ```
   * redis-conf copy到/etc/redis目录,修改:
        ```
            requirepass 123456
            #bind 127.0.0.1 注释该行
        ```
    * 启动redis服务  
    ./redis-server /etc/redis/redis.conf
#### springboot中整合

* redis-client.xml
    
    ```
    <?xml version="1.0" encoding="UTF-8"?>
    <beans xmlns="http://www.springframework.org/schema/beans"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:aop="http://www.springframework.org/schema/aop"
           xsi:schemaLocation="http://www.springframework.org/schema/beans
               http://www.springframework.org/schema/beans/spring-beans-3.0.xsd http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd">
        <aop:aspectj-autoproxy/>
        <bean id="redisConfig" class="redis.clients.jedis.JedisPoolConfig">
            <property name="maxIdle" value="6"></property>
            <property name="minEvictableIdleTimeMillis" value="300000"></property>
            <property name="numTestsPerEvictionRun" value="3"></property>
            <property name="timeBetweenEvictionRunsMillis" value="60000"></property>
        </bean>
        <bean id="jedisConnectionFactory" class="org.springframework.data.redis.connection.jedis.JedisConnectionFactory">
            <property name="poolConfig" ref="redisConfig"></property>
            <property name="hostName" value="${redis.host}"></property>
            <property name="port" value="${redis.port}"></property>
            <property name="password" value="${redis.password}"></property>
            <property name="timeout" value="15000"></property>
            <property name="usePool" value="true"></property>
        </bean>
        <bean id="redisTemplate" class="org.springframework.data.redis.core.RedisTemplate">
            <property name="connectionFactory" ref="jedisConnectionFactory"></property>
            <property name="keySerializer">
                <bean class="org.springframework.data.redis.serializer.StringRedisSerializer"/>
            </property>
            <property name="valueSerializer">
                <bean class="org.springframework.data.redis.serializer.JdkSerializationRedisSerializer"/>
            </property>
            <property name="hashKeySerializer">
                <bean class="org.springframework.data.redis.serializer.JdkSerializationRedisSerializer"></bean>
            </property>
            <property name="hashValueSerializer">
                <bean class="org.springframework.data.redis.serializer.JdkSerializationRedisSerializer"></bean>
            </property>
        </bean>
        <bean id="shardedJedisPool" class="redis.clients.jedis.ShardedJedisPool" >
            <constructor-arg index="0" ref="redisConfig" />
            <constructor-arg index="1">
                <list>
                    <bean class="redis.clients.jedis.JedisShardInfo">
                        <constructor-arg name="host" value="${redis.host}" />
                        <constructor-arg name="port" value="${redis.port}" />
                       <!-- <constructor-arg name="timeout" value="15000" />
                        <constructor-arg name="weight" value="1" />-->
                        <property name="password" value="${redis.password}"></property>
                    </bean>
                </list>
            </constructor-arg>
        </bean>
        <bean id="valueOperations" class="org.springframework.data.redis.core.DefaultValueOperations">
            <constructor-arg name="template" ref="redisTemplate"></constructor-arg>
        </bean>
        <bean id="hashOperations" class="org.springframework.data.redis.core.DefaultHashOperations">
            <constructor-arg name="template" ref="redisTemplate"></constructor-arg>
        </bean>
        <bean id="setOperations" class="org.springframework.data.redis.core.DefaultSetOperations">
            <constructor-arg name="template" ref="redisTemplate"></constructor-arg>
        </bean>
        <bean id="zSetOperations" class="org.springframework.data.redis.core.DefaultZSetOperations">
            <constructor-arg name="template" ref="redisTemplate"></constructor-arg>
        </bean>
        <!-- 用String来做序列化的redis存储 -->
        <bean id="rawRedisTemplate" class="org.springframework.data.redis.core.RedisTemplate">
            <property name="connectionFactory" ref="jedisConnectionFactory"></property>
            <property name="KeySerializer">
                <bean class="org.springframework.data.redis.serializer.StringRedisSerializer"></bean>
            </property>
            <property name="defaultSerializer">
                <bean class="org.springframework.data.redis.serializer.StringRedisSerializer"></bean>
            </property>
        </bean>
        <bean id="rawValueOperations" class="org.springframework.data.redis.core.DefaultValueOperations">
            <constructor-arg name="template" ref="rawRedisTemplate"></constructor-arg>
        </bean>
    </beans>
    ```
* redis.properties
    ```
    #redis
    redis.host=192.168.31.168
    redis.port=6379
    redis.password=123456
    ```
#### 测试
```
@SpringBootApplication
@ImportResource({"classpath*:redis-client.xml"})
public class LiosBootApplication extends WebMvcConfigurerAdapter {
    public static void main(String[] args) {
        SpringApplication.run(LiosBootApplication.class, args);
   }
}

@RestController
public class HelloController {
    @Autowired
    RedisClient redisClient;
    @PostMapping(value = "/lios/boot/ok",produces = {"application/json;charset=utf-8"})
    public void ok(UserParam param){
        redisClient.set("xxxxx","lios");
        String a = redisClient.get("xxxxx");
    }
}
```
