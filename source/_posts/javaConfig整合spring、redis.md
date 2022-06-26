---
title: javaConfig整合spring、redis
date: 2019-02-16 01:42:16
tags:
- java
- spring
categories:
- spring   
copyright: true #版权声明开启        
---
使用spring-data-redis的模版,客户端使用jedis,下面配置bean:
```
@Configuration
public class RedisConfig {
    @Autowired
    @Qualifier("jedisPoolConfig")
    JedisPoolConfig jedisPoolConfig;
    @Autowired
    @Qualifier("jedisConnectionFactory")
    JedisConnectionFactory jedisConnectionFactory;

    @Bean
    public JedisPoolConfig jedisPoolConfig() {
        JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
        jedisPoolConfig.setMaxIdle(6);
        jedisPoolConfig.setTestWhileIdle(true);
        jedisPoolConfig.setMinEvictableIdleTimeMillis(60000L);
        jedisPoolConfig.setTimeBetweenEvictionRunsMillis(30000L);
        jedisPoolConfig.setNumTestsPerEvictionRun(-1);
        return jedisPoolConfig;
    }

    @Bean
    @ConditionalOnBean(JedisPoolConfig.class)
    public JedisConnectionFactory jedisConnectionFactory() {
        JedisConnectionFactory jedisConnectionFactory = new JedisConnectionFactory();
        jedisConnectionFactory.setPoolConfig(jedisPoolConfig);
        jedisConnectionFactory.setHostName("127.0.0.1");
        jedisConnectionFactory.setPort(6379);
        jedisConnectionFactory.setPassword("123456");
        jedisConnectionFactory.setTimeout(15000);
        jedisConnectionFactory.setUsePool(true);
        return jedisConnectionFactory;
    }

    @Bean
    @ConditionalOnBean(JedisConnectionFactory.class)
    public RedisTemplate redisTemplate() {
        RedisTemplate redisTemplate = new RedisTemplate();
        redisTemplate.setConnectionFactory(jedisConnectionFactory);
        redisTemplate.setKeySerializer(new StringRedisSerializer());
        redisTemplate.setValueSerializer(new JdkSerializationRedisSerializer());
        redisTemplate.setHashKeySerializer(new JdkSerializationRedisSerializer());
        redisTemplate.setHashKeySerializer(new JdkSerializationRedisSerializer());
        return redisTemplate;
    }
}

```
下面是工具类使用:
```
package com.lios.base.cache;
import org.springframework.data.redis.core.*;
import org.springframework.stereotype.Component;
import javax.annotation.Resource;
import java.util.*;
import java.util.concurrent.TimeUnit;
import static com.lios.base.cache.AbstractLiosRedisClient.deeplyAppendParameter;
import static com.lios.base.cache.AbstractLiosRedisClient.isDoubleEscaped;
import static com.lios.base.cache.AbstractLiosRedisClient.isEscapedDelimeter;

/**
 * @author LiosWong
 * @description
 * @date 2018/7/22 下午11:56
 */
@Component
public class LiosRedisClient {
    /**
     * String操作
     */
    @Resource(name = "redisTemplate")
    private ValueOperations<String,Object> valueOperations;

    /**
     * hash操作
     */
    @Resource(name = "redisTemplate")
    private HashOperations<String, String, String> hashOperations;

    /**
     * set操作
     */
    @Resource(name = "redisTemplate")
    private SetOperations<String, String> setOperations;

    /**
     * list操作
     */
    @Resource(name = "redisTemplate")
    private ListOperations<String,String> listOperations;

    @Resource(name = "redisTemplate")
    private RedisTemplate redisTemplate;

    /**********************************set操作*******************************************/

    /**
     *
     * @param keyFormat key格式
     * @param value     实际的值
     * @param keyValues key占位符的值
     */
    public void set(String keyFormat, Object value, String... keyValues) {
        String key = format(keyFormat, keyValues);
        valueOperations.set(key, value);
    }

    /**
     *
     * @param keyFormat key格式
     * @param value     实际的值
     * @param expireSeconds 失效时间
     * @param keyValues  key占位符的值
     */
    public void set(String keyFormat, Object value,long expireSeconds,String... keyValues){
        String key = format(keyFormat,keyValues);
        valueOperations.set(key,value,expireSeconds,TimeUnit.MILLISECONDS);
    }

    /**
     *
     * @param keyFormat key格式
     * @param value     实际的值
     * @param keyValues key占位符的值
     * @return
     */
    public boolean setIfAbsent(String keyFormat, Object value, String... keyValues) {
        String key = format(keyFormat, keyValues);
        return valueOperations.setIfAbsent(key, value);
    }


    /**
     *
     * @param keyFormat key格式
     * @param keyValues key占位符值
     * @param <T>
     * @return
     */
    public <T> T get(String keyFormat, String... keyValues) {
        String key = format(keyFormat, keyValues);
        Object o = valueOperations.get(key);
        if (!Objects.isNull(o)) {
            return (T) o;
        }
        return null;
    }

    /**
     * 删除key值
     * @param keyFormat key格式
     * @param keyValues key占位符值
     */
    public void del(String keyFormat,String ... keyValues){
        String key = format(keyFormat,keyValues);
        redisTemplate.delete(key);
    }

    /**
     * 自增计数器
     * @param keyFormat
     * @param value
     * @param keyValues
     * @return
     */
    public Long incrBy(String keyFormat, Long value, String... keyValues) {
        String key = format(keyFormat, keyValues);
        return valueOperations.increment(key, value);
    }


    /**********************************hash操作*******************************************/


    public String hGet(String keyFormat, String hashKey, String... keyValues) {
        String key = format(keyFormat, keyValues);
        String result = hashOperations.get(key, hashKey);
        return result;
    }

    public void hPut(String keyFormat, String hashKey, String value, String... keyValues) {
        String key = format(keyFormat, keyValues);
        hashOperations.put(key, hashKey, value);
    }




    /**********************************set操作*******************************************/

    /**
     * 添加元素
     * @param keyFormat
     * @param value
     * @param keyValues
     */
    public Long add(String keyFormat,String value,String ... keyValues){
        String key = format(keyFormat,keyValues);
        return setOperations.add(key,value);
    }

    /**
     * 弹出某个key
     * @param keyFormat
     * @param keyValues
     * @param <T>
     * @return
     */
    public <T> T pop(String keyFormat,String ... keyValues){
        String key = format(keyFormat,keyValues);
        return (T) setOperations.pop(key);
    }

    /**
     * 比较两个key
     * @param key1
     * @param key2
     * @return
     */
    public Set<String> difference(String key1,String key2){
        return setOperations.difference(key1,key2);
    }




    /**********************************list操作*******************************************/


    /**
     *  左侧进入
     * @param keyFormat
     * @param value
     * @param keyValues
     */
    public void listLeftPush(String keyFormat,String value,String... keyValues) {
        String key = format(keyFormat,keyValues);
        listOperations.leftPush(key,value);
    }

    /**
     * 长度
     * @param keyFormat
     * @param keyValues
     * @return
     */
    public Long listSize(String keyFormat,String... keyValues) {
        String key = format(keyFormat,keyValues);
        return listOperations.size(key);
    }

    /**
     * 右侧进入
     * @param keyFormat
     * @param keyValues
     * @return
     */
    public String listRightPop(String keyFormat, String... keyValues) {
        String key = format(keyFormat,keyValues);
        return listOperations.rightPop(key);
    }

    /**
     * 取出队列中指定范围的元素
     * @param keyFormat
     * @param start
     * @param end
     * @param keyValues
     * @return
     */
    public List<String> listRange(String keyFormat, long start, long end, String... keyValues){
        String key = format(keyFormat,keyValues);
        return listOperations.range(key, start, end);
    }

    public static final String format(String messagePattern, Object[] argArray) {
        if(messagePattern == null) {
            return messagePattern;
        } else if(argArray == null) {
            return messagePattern;
        } else {
            int i = 0;
            StringBuilder sbuf = new StringBuilder(messagePattern.length() + 50);

            for(int L = 0; L < argArray.length; ++L) {
                int j = messagePattern  .indexOf("{}", i);
                if(j == -1) {
                    if(i == 0) {
                        return messagePattern;
                    }

                    sbuf.append(messagePattern, i, messagePattern.length());
                    return messagePattern;
                }

                if(isEscapedDelimeter(messagePattern, j)) {
                    if(!isDoubleEscaped(messagePattern, j)) {
                        --L;
                        sbuf.append(messagePattern, i, j - 1);
                        sbuf.append('{');
                        i = j + 1;
                    } else {
                        sbuf.append(messagePattern, i, j - 1);
                        deeplyAppendParameter(sbuf, argArray[L], new HashMap());
                        i = j + 2;
                    }
                } else {
                    sbuf.append(messagePattern, i, j);
                    deeplyAppendParameter(sbuf, argArray[L], new HashMap());
                    i = j + 2;
                }
            }

            sbuf.append(messagePattern, i, messagePattern.length());
            return sbuf.toString();
        }
    }
}

```

格式化key的方法使用的是slf4j中的方法.
