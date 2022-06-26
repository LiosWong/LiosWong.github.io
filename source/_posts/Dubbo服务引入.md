---
title: Dubbo服务引入
date: 2019-10-06 15:31:32
tags:
- java
- dubbo
- RPC
categories:
- Dubbo   
copyright: true #版权声明开启       
---
关于Dubbo的SPI机制、服务暴露已有文章介绍,该文介绍Dubbo的服务引入.在Dubbo中,我们可以通过两种方式引用远程服务。第一种是使用服务直连的方式引用服务,第二种方式是基于注册中心进行引用.服务直连的方式仅适合在调试或测试服务的场景下使用,不适合在线上环境使用.因此,本文我将重点分析通过注册中心引用服务的过程.  
运行 ``demo-dubbo --》 dubbo-demo-api --》 dubbo-demo-api-consumer`` 中 ``Application``:
```
public class ApplicationConsumer {
    public static void main(String[] args) {
        ReferenceConfig<DemoService> reference = new ReferenceConfig<>();
        reference.setApplication(new ApplicationConfig("dubbo-demo-api-consumer"));
        reference.setRegistry(new RegistryConfig("zookeeper://127.0.0.1:2181"));
        reference.setInterface(DemoService.class);
        DemoService service = reference.get();
        String message = service.sayHello("dubbo");
        System.out.println(message);
    }
}
```
断点进入org.apache.dubbo.config.ReferenceConfig#get:
```
public synchronized T get() {
        checkAndUpdateSubConfigs();

        if (destroyed) {
            throw new IllegalStateException("The invoker of ReferenceConfig(" + url + ") has already destroyed!");
        }
        if (ref == null) {
            init();
        }
        return ref;
    }
```
该方法中会判断接口的代理对象是否为空,如果为空,则初始化,进入org.apache.dubbo.config.ReferenceConfig#init,该方法中大部分代码是对属性检查、获取,最关键的是看代理对象的创建,进入方法org.apache.dubbo.config.ReferenceConfig#createProxy:
```
    private T createProxy(Map<String, String> map) {
        if (shouldJvmRefer(map)) {  //本地引用
            ...
            ...
        } else {  // 远程引用
            urls.clear(); // reference retry init will add url to urls, lead to OOM
            // url 不为空，表明用户可能想进行点对点调用
            if (url != null && url.length() > 0) { // user specified URL, could be peer-to-peer address, or register center's address.
                // 当需要配置多个 url 时，可用分号进行分割，这里会进行切分
                String[] us = SEMICOLON_SPLIT_PATTERN.split(url);
                if (us != null && us.length > 0) {
                    ...
                    ...
                }
            } else { // assemble URL from register center's configuration
                // if protocols not injvm checkRegistry
                if (!LOCAL_PROTOCOL.equalsIgnoreCase(getProtocol())){
                    checkRegistry();
                    // 加载注册中心 url
                    List<URL> us = loadRegistries(false);
                    ...
                    ...
                }
            }
            // 单个注册中心或服务提供者(服务直连，下同)
            if (urls.size() == 1) {
                invoker = REF_PROTOCOL.refer(interfaceClass, urls.get(0));
            } else { // 多个注册中心或多个服务提供者，或者两者混合
                List<Invoker<?>> invokers = new ArrayList<Invoker<?>>();
                URL registryURL = null;
                for (URL url : urls) {
                    invokers.add(REF_PROTOCOL.refer(interfaceClass, url));
                    if (REGISTRY_PROTOCOL.equals(url.getProtocol())) {
                        registryURL = url; // use last registry url
                    }
                }
                if (registryURL != null) { // registry url is available
                    // use RegistryAwareCluster only when register's CLUSTER is available
                    URL u = registryURL.addParameter(CLUSTER_KEY, RegistryAwareCluster.NAME);
                    // The invoker wrap relation would be: RegistryAwareClusterInvoker(StaticDirectory) -> FailoverClusterInvoker(RegistryDirectory, will execute route) -> Invoker
                    invoker = CLUSTER.join(new StaticDirectory(u, invokers));
                } else { // not a registry url, must be direct invoke.
                    invoker = CLUSTER.join(new StaticDirectory(invokers));
                }
            }
        }
        ...
        ...
        // create service proxy
        return (T) PROXY_FACTORY.getProxy(invoker);
    }
```
#### 创建Invoker
该方法首先判断是否为本地引用服务,否则远程,这里走的是远程引用服务,如果单个注册中心,则直接获取Invoker:
```
invoker = REF_PROTOCOL.refer(interfaceClass, urls.get(0));
```
REF_PROTOCOL对象是在运行时由Dubbo SPI机制创建的,这里会根据自适应扩展创建对象包装对象,结构如下:
```
org.apache.dubbo.rpc.protocol.ProtocolFilterWrapper
   org.apache.dubbo.rpc.protocol.ProtocolListenerWrapper
       org.apache.dubbo.registry.integration.RegistryProtocol
```
前面文章也分析过,这里直接看RegistryProtocol中的refer:
```
 // 修改协议为dubbo
 url = URLBuilder.from(url)
                .setProtocol(url.getParameter(REGISTRY_KEY, DEFAULT_REGISTRY))
                .removeParameter(REGISTRY_KEY)
                .build();
        Registry registry = registryFactory.getRegistry(url);
        if (RegistryService.class.equals(type)) {
            return proxyFactory.getInvoker((T) registry, type, url);
        }

        // group="a,b" or group="*"
        Map<String, String> qs = StringUtils.parseQueryString(url.getParameterAndDecoded(REFER_KEY));
        String group = qs.get(GROUP_KEY);
        if (group != null && group.length() > 0) {
            if ((COMMA_SPLIT_PATTERN.split(group)).length > 1 || "*".equals(group)) {
                return doRefer(getMergeableCluster(), registry, type, url);
            }
        }
        return doRefer(cluster, registry, type, url);
```
继续看doRefer方法:
```
        // 创建服务目录 RegistryDirectory 实例
        RegistryDirectory<T> directory = new RegistryDirectory<T>(type, url);
        directory.setRegistry(registry);
        directory.setProtocol(protocol);
        // all attributes of REFER_KEY
        Map<String, String> parameters = new HashMap<String, String>(directory.getUrl().getParameters());
        // 生成服务消费者链接
        URL subscribeUrl = new URL(CONSUMER_PROTOCOL, parameters.remove(REGISTER_IP_KEY), 0, type.getName(), parameters);
        if (!ANY_VALUE.equals(url.getServiceInterface()) && url.getParameter(REGISTER_KEY, true)) {
            directory.setRegisteredConsumerUrl(getRegisteredConsumerUrl(subscribeUrl, url));
            // 注册服务消费者，在 consumers 目录下新节点
            registry.register(directory.getRegisteredConsumerUrl());
        }
        directory.buildRouterChain(subscribeUrl);
        // 订阅 providers、configurators、routers 等节点数据
        directory.subscribe(subscribeUrl.addParameter(CATEGORY_KEY,
                PROVIDERS_CATEGORY + "," + CONFIGURATORS_CATEGORY + "," + ROUTERS_CATEGORY));

        // 一个注册中心可能有多个服务提供者，因此这里需要将多个服务提供者合并为一个
        Invoker invoker = cluster.join(directory);
        ProviderConsumerRegTable.registerConsumer(invoker, url, subscribeUrl, directory);
        return invoker;
```
进入服务目录订阅节点信息方法org.apache.dubbo.registry.integration.RegistryDirectory#subscribe:
```
public void subscribe(URL url) {
        setConsumerUrl(url);
        CONSUMER_CONFIGURATION_LISTENER.addNotifyListener(this);
        serviceConfigurationListener = new ReferenceConfigurationListener(this, url);
        registry.subscribe(url, this);
    }
```
继续进入org.apache.dubbo.registry.support.FailbackRegistry#subscribe:
```
public void subscribe(URL url, NotifyListener listener) {
        super.subscribe(url, listener);
        removeFailedSubscribed(url, listener);
        // Sending a subscription request to the server side
        doSubscribe(url, listener);
        ...
        ...
}
```
继续进入org.apache.dubbo.registry.zookeeper.ZookeeperRegistry#doSubscribe:
```
...
...
notify(url, listener, urls);
```
以上代码很多都省略了,主要看notify方法,进入:
```
protected void notify(URL url, NotifyListener listener, List<URL> urls) {
        if (url == null) {
            throw new IllegalArgumentException("notify url == null");
        }
        if (listener == null) {
            throw new IllegalArgumentException("notify listener == null");
        }
        try {
            doNotify(url, listener, urls);
        } catch (Exception t) {
            // Record a failed registration request to a failed list, retry regularly
            addFailedNotified(url, listener, urls);
            logger.error("Failed to notify for subscribe " + url + ", waiting for retry, cause: " + t.getMessage(), t);
        }
    }
```
主要看org.apache.dubbo.registry.support.FailbackRegistry#doNotify方法:
```
 protected void doNotify(URL url, NotifyListener listener, List<URL> urls) {
        super.notify(url, listener, urls);
    }
```
继续进入org.apache.dubbo.registry.support.AbstractRegistry#notify(org.apache.dubbo.common.URL, org.apache.dubbo.registry.NotifyListener, java.util.List<org.apache.dubbo.common.URL>):
```
...
...
for (Map.Entry<String, List<URL>> entry : result.entrySet()) {
            String category = entry.getKey();
            List<URL> categoryList = entry.getValue();
            categoryNotified.put(category, categoryList);
            listener.notify(categoryList);
            // We will update our cache file after each notification.
            // When our Registry has a subscribe failure due to network jitter, we can return at least the existing cache URL.
            saveProperties(url);
        }
```
这里会遍历routers、configurators、providers节点,示范:
```
routers=[empty://192.168.1.220/org.apache.dubbo.demo.DemoService?application=dubbo-demo-api-consumer&category=routers&dubbo=2.0.2&interface=org.apache.dubbo.demo.DemoService&lazy=false&methods=sayHello&pid=77530&retries=0&sent=true&side=consumer&sticky=false&timeout=3600&timestamp=1572419547454]

configurators=[empty://192.168.1.220/org.apache.dubbo.demo.DemoService?application=dubbo-demo-api-consumer&category=configurators&dubbo=2.0.2&interface=org.apache.dubbo.demo.DemoService&lazy=false&methods=sayHello&pid=77530&retries=0&sent=true&side=consumer&sticky=false&timeout=3600&timestamp=1572419547454]

providers=[dubbo://192.168.1.220:20880/org.apache.dubbo.demo.DemoService?anyhost=true&application=dubbo-demo-api-provider&deprecated=false&dubbo=2.0.2&dynamic=true&generic=false&interface=org.apache.dubbo.demo.DemoService&methods=sayHello&pid=73959&release=&side=provider&timeout=3600&timestamp=1572403767806]
```
如果是providers节点时,则方法调用链入下:
```
org.apache.dubbo.registry.integration.RegistryDirectory#notify
   -->  org.apache.dubbo.registry.integration.RegistryDirectory#refreshOverrideAndInvoker
   -->  org.apache.dubbo.registry.integration.RegistryDirectory#refreshInvoker
   -->  org.apache.dubbo.registry.integration.RegistryDirectory#toInvokers
```
org.apache.dubbo.registry.integration.RegistryDirectory#toInvokers中会重新引用远程服务:
```
 ...
 ...
 ...
 // Cache key is url that does not merge with consumer side parameters, regardless of how the consumer combines parameters, if the server url changes, then refer again
            Map<String, Invoker<T>> localUrlInvokerMap = this.urlInvokerMap; // local reference
            Invoker<T> invoker = localUrlInvokerMap == null ? null : localUrlInvokerMap.get(key);
            if (invoker == null) { // Not in the cache, refer again
                try {
                    boolean enabled = true;
                    if (url.hasParameter(DISABLED_KEY)) {
                        enabled = !url.getParameter(DISABLED_KEY, false);
                    } else {
                        enabled = url.getParameter(ENABLED_KEY, true);
                    }
                    if (enabled) {
                        invoker = new InvokerDelegate<>(protocol.refer(serviceType, url), url, providerUrl);
                    }
                } catch (Throwable t) {
                    logger.error("Failed to refer invoker for interface:" + serviceType + ",url:(" + url + ")" + t.getMessage(), t);
                }
...
...
...
```
回到org.apache.dubbo.registry.integration.RegistryProtocol#doRefer中,上面注释也很清楚,具体看:
```
Invoker invoker = cluster.join(directory);
```
如果一个注册中心有多个服务提供者,这里需要将多个服务提供者合并为一个,cluster对象也是在运行时由Dubbo SPI生成的对象,会根据自适应创建包装类org.apache.dubbo.rpc.cluster.support.wrapper.MockClusterWrapper,结构如下:
```
org.apache.dubbo.rpc.cluster.support.wrapper.MockClusterWrapper
  org.apache.dubbo.rpc.cluster.support.FailbackCluster
```
Dubbo提供了Failover Cluster(失败自动切换)、Failfast Cluster(快速失败)、Failsafe Cluster(失败安全)、Failback Cluster(失败自动恢复)、Forking Cluster(并行调用多个服务提供者)五种集群容错机制,默认为Failover,关于集群的这里不多作介绍,
继续进入MockClusterWrapper的join方法:
```
public <T> Invoker<T> join(Directory<T> directory) throws RpcException {
        return new MockClusterInvoker<T>(directory,
                this.cluster.join(directory));
    }
```
在创建MockClusterInvoker对象之前,会调用org.apache.dubbo.rpc.cluster.support.FailbackCluster#join:
```
 public <T> Invoker<T> join(Directory<T> directory) throws RpcException {
        return new FailbackClusterInvoker<T>(directory);
    }
```
会直接创建对象FailbackClusterInvoker,然后返回,到这里Invoker的对象创建已经完成.
#### 创建代理对象
回到org.apache.dubbo.config.ReferenceConfig#createProxy方法中,最后一段代码用于创建代理对象,同理PROXY_FACTORY对象也是通过Dubbo SPI创建,根据自适应实现,创建对象StubProxyFactoryWrapper,进入org.apache.dubbo.rpc.proxy.wrapper.StubProxyFactoryWrapper#getProxy:
```
T proxy = proxyFactory.getProxy(invoker);
...
...
```
进入org.apache.dubbo.rpc.proxy.javassist.JavassistProxyFactory#getProxy:
```
 public <T> T getProxy(Invoker<T> invoker, Class<?>[] interfaces) {
        return (T) Proxy.getProxy(interfaces).newInstance(new InvokerInvocationHandler(invoker));
    }
```
上面使用了jdk的动态代理实现代理对象的创建,具体看InvokerInvocationHandler的代码:
```
public class InvokerInvocationHandler implements InvocationHandler {
    private static final Logger logger = LoggerFactory.getLogger(InvokerInvocationHandler.class);
    private final Invoker<?> invoker;

    public InvokerInvocationHandler(Invoker<?> handler) {
        this.invoker = handler;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String methodName = method.getName();
        Class<?>[] parameterTypes = method.getParameterTypes();
        if (method.getDeclaringClass() == Object.class) {
            return method.invoke(invoker, args);
        }
        if ("toString".equals(methodName) && parameterTypes.length == 0) {
            return invoker.toString();
        }
        if ("hashCode".equals(methodName) && parameterTypes.length == 0) {
            return invoker.hashCode();
        }
        if ("equals".equals(methodName) && parameterTypes.length == 1) {
            return invoker.equals(args[0]);
        }

        return invoker.invoke(new RpcInvocation(method, args)).recreate();
    }
}
```
invoke方法里会实现Invoker的invoke方法调用.到这里代理对象的创建已经完成.

> 参考文章

1. [http://dubbo.apache.org/zh-cn/docs/source_code_guide/refer-service.html](http://dubbo.apache.org/zh-cn/docs/source_code_guide/refer-service.html)
