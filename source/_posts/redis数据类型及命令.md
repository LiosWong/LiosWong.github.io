---
title: redis数据类型及命令
date: 2019-02-24 22:29:09
tags:
- redis
categories:
- redis      
---
Redis是一个使用ANSI C编写的开源、支持网络、基于内存、可选持久性（英语：Durability_(database_systems)）的键值对存储数据库（英语：Key-value database）
##### 数据类型 
* strings(字符串)  
字符串是一种最基本的Redis值类型。Redis字符串是二进制安全的，这意味着一个Redis字符串能包含任意类型的数据，例如： 一张JPEG格式的图片或者一个序列化的Ruby对象。一个字符串类型的值最多能存储512M字节的内容。  
* hashes(哈希)  
Redis Hashes是字符串字段和字符串值之间的映射，所以它们是完美的表示对象（eg:一个有名，姓，年龄等属性的用户）的数据类型。  
* lists(列表)  
Redis列表是简单的字符串列表，按照插入顺序排序。 你可以添加一个元素到列表的头部（左边）或者尾部（右边）。LPUSH 命令插入一个新元素到列表头部，而RPUSH命令 插入一个新元素到列表的尾部。当 对一个空key执行其中某个命令时，将会创建一个新表。 类似的，如果一个操作要清空列表，那么key会从对应的key空间删除。这是个非常便利的语义，因为如果使用一个不存在的key作为参数，所有的列表命令都会像在对一个空表操作一样。  
* sets(集合)  
Redis集合是一个无序的字符串合集。你可以以O(1) 的时间复杂度（无论集合中有多少元素时间复杂度都为常量）完成 添加，删除以及测试元素是否存在的操作。
Redis集合有着不允许相同成员存在的优秀特性。向集合中多次添加同一元素，在集合中最终只会存在一个此元素。实际上这就意味着，在添加元素前，你并不需要事先进行检验此元素是否已经存在的操作。  
* zset(有序集合)
Redis集合是一个无序的字符串合集。你可以以O(1) 的时间复杂度（无论集合中有多少元素时间复杂度都为常量）完成 添加，删除以及测试元素是否存在的操作。
Redis集合有着不允许相同成员存在的优秀特性。向集合中多次添加同一元素，在集合中最终只会存在一个此元素。实际上这就意味着，在添加元素前，你并不需要事先进行检验此元素是否已经存在的操作。  

##### 命令(参考[http://redis.cn/commands.html#string](http://redis.cn/commands.html#string))
* strings

|命令|说明|
|---|---|
|APPEND key value|APPEND key value|
|BITCOUNT key [start end]|统计字符串指定起始位置的字节数|
|BITFIELD key[GET type offset][SET type offset value][INCRBY type offset increment][OVERFLOW WRAP、SAT、FAIL]|Perform arbitrary bitfield integer operations on strings|
|BITOP operation destkey key [key ...]|Perform bitwise operations between strings|
|BITPOS key bit [start] [end]|Find first bit set or clear in a string|
|DECR key|整数原子减1|
|DECRBY key decrement|原子减指定的整数|
|GET key|返回key的value|
|GETBIT key offset|返回位的值存储在关键的字符串值的偏移量。|
|GETRANGE key start end|获取存储在key上的值的一个子字符串|
|GETSET key value|设置一个key的value，并获取设置前的值|
|INCR key|执行原子加1操作|
|INCRBY key increment|执行原子增加一个整数|
|INCRBYFLOAT key increment|执行原子增加一个浮点数|
|MGET key [key ...]|获得所有key的值|
|MSET key value [key value ...]|设置多个key value|
|MSETNX key value [key value ...]|设置多个key value,仅当key存在时|
|PSETEX key milliseconds value|Set the value and expiration in milliseconds of a key|
|SET key value [EX seconds] [PX milliseconds] [NX|XX]|设置一个key的value值|
|SETBIT key offset value|Sets or clears the bit at offset in the string value stored at key|
|SETEX key seconds value|设置key-value并设置过期时间（单位：秒）|
|SETNX key value|设置的一个关键的价值，只有当该键不存在|
|SETRANGE key offset value|Overwrite part of a string at key starting at the specified offset|
|STRLEN key|获取指定key值的长度|

* hashes

|命令|说明|
|---|---|
|HDEL key field [field ...]|删除一个或多个Hash的field|
|HEXISTS key field|判断field是否存在于hash中|
|HGET key field|获取hash中field的值|
|HGETALL key|从hash中读取全部的域和值|
|HINCRBY key field increment|将hash中指定域的值增加给定的数字|
|HINCRBYFLOAT key field increment|将hash中指定域的值增加给定的浮点数|
|HKEYS key|获取hash的所有字段|
|HLEN key|获取hash里所有字段的数量|
|HMGET key field [field ...]|获取hash里面指定字段的值|
|HMSET key field value [field value ...]|设置hash字段值|
|HSET key field value|设置hash里面一个字段的值|
|HSETNX key field value|设置hash的一个字段，只有当这个字段不存在时有效|
|HSTRLEN key field|获取hash里面指定field的长度|
|HVALS key|获得hash的所有值|
|HSCAN key cursor [MATCH pattern] [COUNT count]|迭代hash里面的元素|

* sets

|命令|说明|
|---|---|
|SADD key member [member ...]|添加一个或者多个元素到集合(set)里|
|SCARD key|获取集合里面的元素数量|
|SDIFF key [key ...]|获得队列不存在的元素|
|SDIFFSTORE destination key [key ...]|获得队列不存在的元素，并存储在一个关键的结果集|
|SINTER key [key ...]|获得两个集合的交集|
|SINTERSTORE destination key [key ...]|获得两个集合的交集，并存储在一个关键的结果集|
|SISMEMBER key member|确定一个给定的值是一个集合的成员|
|SMEMBERS key|获取集合里面的所有元素|
|SMOVE source destination member|移动集合里面的一个元素到另一个集合|
|SPOP key [count]|删除并获取一个集合里面的元素|
|SRANDMEMBER key [count]|从集合里面随机获取一个元素|
|SREM key member [member ...]|从集合里删除一个或多个元素|
|SUNION key [key ...]|添加多个set元素|
|SUNIONSTORE destination key [key ...]|合并set元素，并将结果存入新的set里面|
|SSCAN key cursor [MATCH pattern] [COUNT count]|迭代set里面的元素|

* zset

|命令|说明|
|---|---|
|ZADD key [NX|XX] [CH] [INCR] score member [score member ...]|添加到有序set的一个或多个成员，或更新的分数，如果它已经存在|
|ZCARD key|获取一个排序的集合中的成员数量|
|ZCOUNT key min max|返回分数范围内的成员数量|
|ZINCRBY key increment member|增量的一名成员在排序设置的评分|
|ZINTERSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM、MIN、MAX]|相交多个排序集，导致排序的设置存储在一个新的关键|
|ZLEXCOUNT key min max|返回成员之间的成员数量|
|ZPOPMAX key [count]|Remove and return members with the highest scores in a sorted set|
|ZPOPMIN key [count]|Remove and return members with the lowest scores in a sorted set|
|ZRANGE key start stop [WITHSCORES]|根据指定的index返回，返回sorted set的成员列表|
|ZRANGEBYLEX key min max [LIMIT offset count]|返回指定成员区间内的成员，按字典正序排列, 分数必须相同。|
|ZREVRANGEBYLEX key max min [LIMIT offset count]|返回指定成员区间内的成员，按字典倒序排列, 分数必须相同|
|ZRANGEBYSCORE key min max [WITHSCORES] [LIMIT offset count]|返回有序集合中指定分数区间内的成员，分数由低到高排序。|
|ZRANK key member|确定在排序集合成员的索引|
|ZREM key member [member ...]|从排序的集合中删除一个或多个成员|
|ZREMRANGEBYLEX key min max|删除名称按字典由低到高排序成员之间所有成员。|
|ZREMRANGEBYRANK key start stop|在排序设置的所有成员在给定的索引中删除|
|ZREMRANGEBYSCORE key min max|删除一个排序的设置在给定的分数所有成员|
|ZREVRANGE key start stop [WITHSCORES]|在排序的设置返回的成员范围，通过索引，下令从分数高到低|
|ZREVRANGEBYSCORE key max min [WITHSCORES] [LIMIT offset count]|返回有序集合中指定分数区间内的成员，分数由高到低排序。|
|ZREVRANK key member|确定指数在排序集的成员，下令从分数高到低|
|ZSCORE key member|获取成员在排序设置相关的比分|
|ZUNIONSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM、MIN、MAX]|添加多个排序集和导致排序的设置存储在一个新的关键|
|ZSCAN key cursor [MATCH pattern] [COUNT count]|迭代sorted sets里面的元素|

除了以上5种命令外,还有Cluster、Connection、Geo、HyperLogLog、Keys、Pub/Sub、Scripting、Server、Streams、Transactions等命令,具体参考[https://redis.io/commands](https://redis.io/commands).
