---
title: zookeeper入门
date: 2019-04-21 18:28:32
tags:
- zookeeper
- zookeeper集群
categories:
- zookeeper   
copyright: true #版权声明开启     
---
Apache ZooKeeper是Apache软件基金会的一个软件项目，他为大型分布式计算提供开源的分布式配置服务、同步服务和命名注册。 ZooKeeper曾经是Hadoop的一个子项目，但现在是一个独立的顶级项目。  
ZooKeeper的架构通过冗余服务实现高可用性。因此，如果第一次无应答，客户端就可以询问另一台ZooKeeper主机。ZooKeeper节点将它们的数据存储于一个分层的命名空间，非常类似于一个文件系统或一个前缀树结构。客户端可以在节点读写，从而以这种方式拥有一个共享的配置服务。更新是全序的。--[维基百科](https://zh.wikipedia.org/wiki/Apache_ZooKeeper)

#### 搭建
* 单机配置  
      - 去官网上下载[https://archive.apache.org/dist/zookeeper/](https://archive.apache.org/dist/zookeeper/),然后解压  
      - copy conf/zoo_sample.cfg文件重命名为zoo.cfg,并配置修改  
      - /bin/zkServer.sh start  启动服务  
       
      zoo.cfg配置文件如下:
      
```
        # The number of milliseconds of each tick
        tickTime=2000
        # The number of ticks that the initial 
        # synchronization phase can take
        initLimit=10
        # The number of ticks that can pass between 
        # sending a request and getting an acknowledgement
        syncLimit=5
        # the directory where the snapshot is stored.
        dataDir=/Users/wenchao.wang/dev/zookeeper/data
        dataLogDir=/Users/wenchao.wang/dev/zookeeper/logs

        # the port at which the clients will connect
        clientPort=2181
```
* 集群配置  
一般zookeeper集群由三台及以上机器组成,只要集群中存在超过一半的机器能够正常工作，那么整个集群就能够正常对外服务.下面将安装三个节点的zookeeper集群,即一个leader、两个follower. 
    - 下载安装包、解压(同上)  
    - 把解压包copy三份,分别命名为zookeeper-node-1、zookeeper-node-2、zookeeper-node-3  
    - 分别copy三个节点下conf/zoo_sample.cfg文件重命名为zoo.cfg,并修改配置  
    - 然后在zookeeper-node-1、zookeeper-node-2、zookeeper-node-3同级目录下创建目录zookeeper-data/8001/data、zookeeper-data/8002/data、zookeeper-data/8003/data、zookeeper-data/8001/logs、zookeeper-data/8002/logs、zookeeper-data/8003/logs  
    - 在zookeeper-data/8001/data、zookeeper-data/8002/data、zookeeper-data/8003/data目录下分别创建文件myid,分别在myid中写入1,2,3
    - /bin/zkServer.sh start 分别启动三台服务  
    zoo.cfg配置如下:
```
        # The number of milliseconds of each tick
        # The number of milliseconds of each tick
        tickTime=2000
        # The number of ticks that the initial
        # synchronization phase can take
        initLimit=10
        # The number of ticks that can pass between
        # sending a request and getting an acknowledgement
        syncLimit=5
        # the directory where the snapshot is stored.
        dataDir=/Users/wenchao.wang/dev/zookeeper-cluster/zookeeper-data/8002/data
        # dataDir=/Users/wenchao.wang/dev/zookeeper-cluster/zookeeper-data/8001/data
        # dataDir=/Users/wenchao.wang/dev/zookeeper-cluster/zookeeper-data/8003/data
        dataLogDir=/Users/wenchao.wang/dev/zookeeper-cluster/zookeeper-data/8002/logs
        # dataLogDir=/Users/wenchao.wang/dev/zookeeper-cluster/zookeeper-data/8001/logs
        # dataLogDir=/Users/wenchao.wang/dev/zookeeper-cluster/zookeeper-data/8003/logs

        # the port at which the clients will connect
        clientPort=2182
        # clientPort=2181
        # clientPort=2183

        # server.number (number是1、2、3)分别对应myid中的内容，
        # zookeeper也是通过server后面的数字以及dataDir下的myid内容来判断zookeeper集群的关系的（哪个server对应哪个地址），然后后面两个端
        # 口号，一个是跟服务器发送链接的端口，另一个是接受服务器链接的端口
        server.1=127.0.0.1:8001:9001
        server.2=127.0.0.1:8002:9002
        server.3=127.0.0.1:8003:9003
```

下面是在本地机器上配置的zookeeper集群三级目录树状图:
```
        /Users/wenchao.wang/dev/zookeeper-cluster
        ├── zookeeper-data
        │   ├── 8001
        │   │   ├── data
        │   │   └── logs
        │   ├── 8002
        │   │   ├── data
        │   │   └── logs
        │   └── 8003
        │       ├── data
        │       └── logs
        ├── zookeeper-node-1
        │   ├── bin
        │   ├── conf
        │   ├── contrib
        │   │   ├── ZooInspector
        │   │   ├── bookkeeper
        │   │   ├── fatjar
        │   │   ├── rest
        │   │   ├── zkfuse
        │   │   ├── zkperl
        │   │   ├── zkpython
        │   │   └── zktreeutil
        │   ├── data
        │   ├── dist-maven
        │   ├── docs
        │   │   ├── api
        │   │   ├── images
        │   │   ├── jdiff
        │   │   └── skin
        │   ├── lib
        │   │   ├── cobertura
        │   │   └── jdiff
        │   ├── recipes
        │   │   ├── lock
        │   │   └── queue
        │   └── src
        │       ├── c
        │       ├── contrib
        │       ├── docs
        │       ├── java
        │       └── recipes
        ├── zookeeper-node-2
        │   ├── bin
        │   ├── conf
        │   ├── contrib
        │   │   ├── ZooInspector
        │   │   ├── bookkeeper
        │   │   ├── fatjar
        │   │   ├── rest
        │   │   ├── zkfuse
        │   │   ├── zkperl
        │   │   ├── zkpython
        │   │   └── zktreeutil
        │   ├── data
        │   ├── dist-maven
        │   ├── docs
        │   │   ├── api
        │   │   ├── images
        │   │   ├── jdiff
        │   │   └── skin
        │   ├── lib
        │   │   ├── cobertura
        │   │   └── jdiff
        │   ├── recipes
        │   │   ├── lock
        │   │   └── queue
        │   └── src
        │       ├── c
        │       ├── contrib
        │       ├── docs
        │       ├── java
        │       └── recipes
        └── zookeeper-node-3
            ├── bin
            ├── conf
            ├── contrib
            │   ├── ZooInspector
            │   ├── bookkeeper
            │   ├── fatjar
            │   ├── rest
            │   ├── zkfuse
            │   ├── zkperl
            │   ├── zkpython
            │   └── zktreeutil
            ├── data
            ├── dist-maven
            ├── docs
            │   ├── api
            │   ├── images
            │   ├── jdiff
            │   └── skin
            ├── lib
            │   ├── cobertura
            │   └── jdiff
            ├── recipes
            │   ├── lock
            │   └── queue
            └── src
                ├── c
                ├── contrib
                ├── docs
                ├── java
                └── recipes
```
#### 客户端命令  
在bin/目录下执行``./zkCli.sh``,登录客户端,输入任意字符回车,会看见命令提示,下面简单的介绍一些常用的命令:

|命令|说明|
|---|---|
|stat path [watch]|查看节点状态,例:``stat /lios/server``|
|set path data [version]|节点设值,例:``set /lios/server 3``|
|ls path [watch]|查看节点子节点,例:``ls /lios/server``|
|delete path [version]|删除节点,例:``delete /lios/server/f``|
|get path [watch]|获取节点值,例:``get /lios/server``|
|create [-s] [-e] path data acl|创建节点,例:``create /lios/server/f "lios"``,加上-e参数表示临时节点,重启会丢失数据;-s表示创建有序节点|
|rmr|递归删除节点 例子:``rmr /lios/server``|
|ls2|查看节点及其他信息,例:``ls2 /lios/server ``|

#### Java客户端
下面通过Java代码简单说明,服务端往zookeeper中添加节点信息,客户端订阅该节点,当节点发生变化时,刷新节点数据,首先添加依赖包:
```
<dependency>
     <groupId>org.apache.zookeeper</groupId>
     <artifactId>zookeeper</artifactId>
     <version>3.4.8</version>
</dependency>
```
ZookeeperServer:
```
/**
 * @author LiosWong
 * @description
 * @date 2019/4/18 下午4:39
 */
public class ZookeeperServer extends AbstractZoo {

    // 创建链接
    @Override
    protected ZooKeeper connect() {
        try {
            zooKeeper = new ZooKeeper(connectString, sessionTimeout, new Watcher() {
                @Override
                public void process(WatchedEvent event) {
                    // 当连接状态时,处理逻辑.关于状态参考org.apache.zookeeper.Watcher.Event.KeeperState
                    if (Event.KeeperState.SyncConnected.equals(event.getState())) {
                        System.out.println("====>" + event.getPath() + ";" + event.getType());
                    }
                }
            });
        } catch (IOException e) {
            e.printStackTrace();
        }
        return zooKeeper;
    }

    // 创建节点
    public ZooKeeper serverRegister(Integer type, String data) {
        try {
            Stat stat = connect().exists(CREATE_SERVER_NODE, true);
            switch (type) {
                case 1:
                    // 同步创建节点
                    if (Objects.isNull(stat)) {
                        zooKeeper.create(CREATE_SERVER_NODE, data.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
//                        zooKeeper.create(CREATE_SERVER_NODE, data.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT_SEQUENTIAL);  顺序节点
                    }
                    break;
                case 2:
                    // 异步创建节点
                    zooKeeper.create(CREATE_SERVER_NODE, data.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT, new CallBack(), "异步创建节点");
//                    zooKeeper.create(CREATE_SERVER_NODE, data.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT_SEQUENTIAL, new CallBack(), "异步创建节点");  顺序节点
                    break;
                default:
                    break;
            }
        } catch (KeeperException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return zooKeeper;
    }


    public static void main(String[] args) throws InterruptedException {
        ZookeeperServer zoo = new ZookeeperServer();
        zoo.serverRegister(2, "d,");
        Thread.sleep(999999);
    }

    private static class CallBack implements AsyncCallback.StringCallback {

        @Override
        public void processResult(int rc, String path, Object ctx, String name) {
            System.out.println("rc=" + rc + ";" + "path=" + path + ";" + "ctx=" + ctx + ";" + "name=" + name);
        }
    }
}

public abstract class AbstractZoo {
    protected static final String connectString = "127.0.0.1:2181,127.0.0.1:2182,127.0.0.1:2183";
    protected static final int sessionTimeout = 10000;
    protected static final String CREATE_SERVER_NODE = "/lios/server/g";
    protected static final String GET_SERVER_NODE = "/lios/server";
    protected static ZooKeeper zooKeeper = null;

    // 创建链接
    protected abstract ZooKeeper connect();

    // 获取节点
    protected void getNodeData() {

    }
}

```
ZookeeperClient:
```
public class ZookeeperClient extends AbstractZoo {
    @Override
    protected ZooKeeper connect() {
        try {
            zooKeeper = new ZooKeeper(connectString, sessionTimeout, new Watcher() {
                @Override
                public void process(WatchedEvent event) {
                    if (Event.KeeperState.SyncConnected.equals(event.getState())) {
                        // 刷新节点
                        getNodeData();
                    }
                }
            });
        } catch (IOException e) {
            e.printStackTrace();
        }
        return zooKeeper;
    }

    @Override
    protected void getNodeData() {
        try {
            List<String> childList = zooKeeper.getChildren(GET_SERVER_NODE, true);
            for (String addr : childList) {
                byte[] data = zooKeeper.getData(GET_SERVER_NODE + "/" + addr, false, null);
                System.out.println("=======>节点addr:" + addr + ";" + "data:" + new String(data));
            }
            System.out.println("==================>刷新完成");
        } catch (KeeperException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        AbstractZoo client = new ZookeeperClient();
        client.connect();
        client.getNodeData();
        try {
            Thread.sleep(99999999);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```
发现ZookeeperServer中只要在``/lios/server``下新增或删除,ZookeeperClient中都会刷新该节点下的列表,实际中可通过``./zkCli.sh``在命令下操作节点,观察ZookeeperClient下刷新状态.
