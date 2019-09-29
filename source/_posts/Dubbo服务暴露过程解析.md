---
title: Dubbo服务暴露过程解析.md
date: 2019-09-29 13:25:21
tags:
- java
- dubbo
- RPC
categories:
- Dubbo   
copyright: true #版权声明开启       
---
Dubbo SPI的暴露原理参考[https://lioswong.github.io/2019/09/17/Dubbo-SPI%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86/](https://lioswong.github.io/2019/09/17/Dubbo-SPI%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86/),本文分析服务暴露过程,运行 ``demo-dubbo --》 dubbo-demo-api --》 dubbo-demo-api-provider`` 中 ``Application``:
```
public class Application {
    public static void main(String[] args) throws Exception {
        ServiceConfig<DemoServiceImpl> service = new ServiceConfig<>();
        service.setApplication(new ApplicationConfig("dubbo-demo-api-provider"));
        service.setRegistry(new RegistryConfig("zookeeper://127.0.0.1:2181"));
        service.setInterface(DemoService.class);
        service.setRef(new DemoServiceImpl());
        service.export();
        System.in.read();
    }
}
```
先创建对象 ``ServiceConfig`` ,设置 ``ApplicationConfig`` 、``RegistryConfig`` 、接口 、实现类对象,接下来导出服务,断点进入 ``org.apache.dubbo.config.ServiceConfig#export`` :
```
 public synchronized void export() {
        // 配置检查
        checkAndUpdateSubConfigs();
        // 是否导出
        if (!shouldExport()) {
            return;
        }
        // 是否延导出
        if (shouldDelay()) {
            DELAY_EXPORT_EXECUTOR.schedule(this::doExport, getDelay(), TimeUnit.MILLISECONDS);
        } else {
            // 直接暴露服务
            doExport();
        }
    }
```
首先配置检查(涉及检查和刷新,这里不多做介绍),根据属性配置 ``export`` 判断是否导出服务,根据 ``delay`` 判断是否延迟导出,比如某些应用需要预热处理,配置示例如下:
```
<dubbo:service interface="org.apache.dubbo.demo.DemoService" export="true" delay="5000"/>
```
进入 ``org.apache.dubbo.config.ServiceConfig#doExport`` 方法:
```
protected synchronized void doExport() {
        if (unexported) {
            throw new IllegalStateException("The service " + interfaceClass.getName() + " has already unexported!");
        }
        if (exported) {
            return;
        }
        exported = true;

        if (StringUtils.isEmpty(path)) {
            path = interfaceName;
        }
        // 导出
        doExportUrls();
    }
```
上面的代码很简单,直接断点进入 ``org.apache.dubbo.config.ServiceConfig#doExportUrls()`` :
```
    List<URL> registryURLs = loadRegistries(true);
    for (ProtocolConfig protocolConfig : protocols) {
        String pathKey = URL.buildKey(getContextPath(protocolConfig).map(p -> p + "/" + path).orElse(path), group, version);
        ProviderModel providerModel = new ProviderModel(pathKey, ref, interfaceClass);
        ApplicationModel.initProviderModel(pathKey, providerModel);
        doExportUrlsFor1Protocol(protocolConfig, registryURLs);
    }
```
``org.apache.dubbo.config.AbstractInterfaceConfig#loadRegistries`` 这个方法逻辑很简单,从 ``RegistryConfig`` 中获取协议配置属性然后封装成 ``org.apache.dubbo.common.URL`` ,返回协议列表,然后遍历列表,把服务以不同的协议以 ``URL`` 形式暴露,例如:
```
registry://127.0.0.1:2181/org.apache.dubbo.registry.RegistryService?application=dubbo-demo-api-provider&dubbo=2.0.2&pid=7660&registry=zookeeper&timestamp=1569035160813
```
进入 ``org.apache.dubbo.config.ServiceConfig#doExportUrlsFor1Protocol`` :
```
private void doExportUrlsFor1Protocol(ProtocolConfig protocolConfig, List<URL> registryURLs) {
        String name = protocolConfig.getName();
        // 默认协议dubbo
        if (StringUtils.isEmpty(name)) {
            name = DUBBO;
        }

        Map<String, String> map = new HashMap<String, String>();
        map.put(SIDE_KEY, PROVIDER_SIDE);

        // 获取属性配置放入map中
        appendRuntimeParameters(map);
        appendParameters(map, metrics);
        appendParameters(map, application);
        appendParameters(map, module);
        ...
        ...
        ...
        if (ProtocolUtils.isGeneric(generic)) {
            map.put(GENERIC_KEY, generic);
            map.put(METHODS_KEY, ANY_VALUE);
        } else {
            // 获取revision
            String revision = Version.getVersion(interfaceClass, version);
            if (revision != null && revision.length() > 0) {
                map.put(REVISION_KEY, revision);
            }

            String[] methods = Wrapper.getWrapper(interfaceClass).getMethodNames();  // a
            if (methods.length == 0) {
                logger.warn("No method found in service interface " + interfaceClass.getName());
                map.put(METHODS_KEY, ANY_VALUE);
            } else {
                map.put(METHODS_KEY, StringUtils.join(new HashSet<String>(Arrays.asList(methods)), ","));
            }
        }
        if (!ConfigUtils.isEmpty(token)) {
            if (ConfigUtils.isDefault(token)) {
                map.put(TOKEN_KEY, UUID.randomUUID().toString());
            } else {
                map.put(TOKEN_KEY, token);
            }
        }
        // export service
        String host = this.findConfigedHosts(protocolConfig, registryURLs, map);
        // 获取服务暴露端口号
        Integer port = this.findConfigedPorts(protocolConfig, name, map);
        // 构建URL
        URL url = new URL(name, host, port, getContextPath(protocolConfig).map(p -> p + "/" + path).orElse(path), map);

        if (ExtensionLoader.getExtensionLoader(ConfiguratorFactory.class) // b
                .hasExtension(url.getProtocol())) { 
            url = ExtensionLoader.getExtensionLoader(ConfiguratorFactory.class) // c
                    .getExtension(url.getProtocol()).getConfigurator(url).configure(url);
        }

        String scope = url.getParameter(SCOPE_KEY);
        // don't export when none is configured
        if (!SCOPE_NONE.equalsIgnoreCase(scope)) {  // d

            // export to local if the config is not remote (export to remote only when config is remote)
            if (!SCOPE_REMOTE.equalsIgnoreCase(scope)) { // e
                exportLocal(url); 
            }
            // export to remote if the config is not local (export to local only when config is local)
            if (!SCOPE_LOCAL.equalsIgnoreCase(scope)) { // f
                if (CollectionUtils.isNotEmpty(registryURLs)) {
                    for (URL registryURL : registryURLs) {
                        //if protocol is only injvm ,not register
                        if (LOCAL_PROTOCOL.equalsIgnoreCase(url.getProtocol())) {
                            continue;
                        }
                        url = url.addParameterIfAbsent(DYNAMIC_KEY, registryURL.getParameter(DYNAMIC_KEY));
                        URL monitorUrl = loadMonitor(registryURL);
                        if (monitorUrl != null) {
                            url = url.addParameterAndEncoded(MONITOR_KEY, monitorUrl.toFullString());
                        }
                        if (logger.isInfoEnabled()) {
                            if (url.getParameter(REGISTER_KEY, true)) {
                                logger.info("Register dubbo service " + interfaceClass.getName() + " url " + url + " to registry " + registryURL);
                            } else {
                                logger.info("Export dubbo service " + interfaceClass.getName() + " to url " + url);
                            }
                        }

                        // For providers, this is used to enable custom proxy to generate invoker
                        String proxy = url.getParameter(PROXY_KEY);
                        if (StringUtils.isNotEmpty(proxy)) {
                            registryURL = registryURL.addParameter(PROXY_KEY, proxy);
                        }

                        Invoker<?> invoker = PROXY_FACTORY.getInvoker(ref, (Class) interfaceClass, registryURL.addParameterAndEncoded(EXPORT_KEY, url.toFullString()));  // f
                        DelegateProviderMetaDataInvoker wrapperInvoker = new DelegateProviderMetaDataInvoker(invoker, this);

                        Exporter<?> exporter = protocol.export(wrapperInvoker); // g
                        exporters.add(exporter); // h
                    }
                } else {
                    if (logger.isInfoEnabled()) {
                        logger.info("Export dubbo service " + interfaceClass.getName() + " to url " + url);
                    }
                    Invoker<?> invoker = PROXY_FACTORY.getInvoker(ref, (Class) interfaceClass, url);
                    DelegateProviderMetaDataInvoker wrapperInvoker = new DelegateProviderMetaDataInvoker(invoker, this);

                    Exporter<?> exporter = protocol.export(wrapperInvoker);
                    exporters.add(exporter);
                }
                /**
                 * @since 2.7.0
                 * ServiceData Store
                 */
                MetadataReportService metadataReportService = null;
                if ((metadataReportService = getMetadataReportService()) != null) {
                    metadataReportService.publishProvider(url);
                }
            }
        }
        this.urls.add(url);
    }
```
#### 构建包装类Wrapper
这段代码比较长,首先把各个属性值放入到 ``map`` 中，断点到 ``a`` 处,进入 ``org.apache.dubbo.common.bytecode.Wrapper#getWrapper`` :
```
public static Wrapper getWrapper(Class<?> c) {
        while (ClassGenerator.isDynamicClass(c)) // can not wrapper on dynamic class.
        {
            c = c.getSuperclass();
        }

        if (c == Object.class) {
            return OBJECT_WRAPPER;
        }

        Wrapper ret = WRAPPER_MAP.get(c);
        if (ret == null) {
            ret = makeWrapper(c);
            WRAPPER_MAP.put(c, ret);
        }
        return ret;
    }
```
首先从缓存中获取包装类 ``Wrapper``,如果没有创建,进入 ``org.apache.dubbo.common.bytecode.Wrapper#makeWrapper`` :
```
private static Wrapper makeWrapper(Class<?> c) {
        if (c.isPrimitive()) {
            throw new IllegalArgumentException("Can not create wrapper for primitive type: " + c);
        }
        String name = c.getName();
        ClassLoader cl = ClassUtils.getClassLoader(c);
        StringBuilder c1 = new StringBuilder("public void setPropertyValue(Object o, String n, Object v){ ");
        StringBuilder c2 = new StringBuilder("public Object getPropertyValue(Object o, String n){ ");
        StringBuilder c3 = new StringBuilder("public Object invokeMethod(Object o, String n, Class[] p, Object[] v) throws " + InvocationTargetException.class.getName() + "{ ");
        ...
        ...
        ...
        ...
        try {
            Class<?> wc = cc.toClass();
            // setup static field.
            wc.getField("pts").set(null, pts);
            wc.getField("pns").set(null, pts.keySet().toArray(new String[0]));
            wc.getField("mns").set(null, mns.toArray(new String[0]));
            wc.getField("dmns").set(null, dmns.toArray(new String[0]));
            int ix = 0;
            for (Method m : ms.values()) {
                wc.getField("mts" + ix++).set(null, m.getParameterTypes());
            }
            return (Wrapper) wc.newInstance();
        } catch (RuntimeException e) {
            throw e;
        } catch (Throwable e) {
            throw new RuntimeException(e.getMessage(), e);
        } finally {
            cc.release();
            ms.clear();
            mns.clear();
            dmns.clear();
        }
    }
```
上面的代码不具体分析,通过javassist动态生成类 ``class org.apache.dubbo.common.bytecode.Wrapper0`` :
```
public class org.apache.dubbo.common.bytecode.Wrapper0 extends Wrapper
{
    public static String[] pns;
    public static java.util.Map pts;
    public static String[] mns;
    public static String[] dmns;
    public static Class[] mts0;
    public String[] getPropertyNames()
    {
        return pns;
    }
    public boolean hasProperty(String n)
    {
        return pts.containsKey($1);
    }
    public Class getPropertyType(String n)
    {
        return (Class)pts.get($1);
    }
    public String[] getMethodNames()
    {
        return mns;
    }
    public String[] getDeclaredMethodNames()
    {
        return dmns;
    }
    public void setPropertyValue(Object o, String n, Object v)
    {
        org.apache.dubbo.demo.DemoService w;
        try
        {
            w = ((org.apache.dubbo.demo.DemoService)$1);
        }
        catch(Throwable e)
        {
            throw new IllegalArgumentException(e);
        }
        throw new org.apache.dubbo.common.bytecode.NoSuchPropertyException("Not found property \"" + $2 + "\" field or setter method in class org.apache.dubbo.demo.DemoService.");
    }
    public Object getPropertyValue(Object o, String n)
    {
        org.apache.dubbo.demo.DemoService w;
        try
        {
            w = ((org.apache.dubbo.demo.DemoService)$1);
        }
        catch(Throwable e)
        {
            throw new IllegalArgumentException(e);
        }
        throw new org.apache.dubbo.common.bytecode.NoSuchPropertyException("Not found property \"" + $2 + "\" field or setter method in class org.apache.dubbo.demo.DemoService.");
    }
    // 根据方法名调用
    public Object invokeMethod(Object o, String n, Class[] p, Object[] v) throws java.lang.reflect.InvocationTargetException
    {
        org.apache.dubbo.demo.DemoService w;
        try
        {
            w = ((org.apache.dubbo.demo.DemoService)$1);
        }
        catch(Throwable e)
        {
            throw new IllegalArgumentException(e);
        }
        try
        {
            if( "sayHello".equals( $2 )  &&  $3.length == 1 )
            {
                return ($w)w.sayHello((java.lang.String)$4[0]);
            }
        }
        catch(Throwable e)
        {
            throw new java.lang.reflect.InvocationTargetException(e);
        }
        throw new org.apache.dubbo.common.bytecode.NoSuchMethodException("Not found method \"" + $2 + "\" in class org.apache.dubbo.demo.DemoService.");
    }
}
```
有上面可知,包装类 ``Wrapper0`` 的 ``invokeMethod`` 方法里会真正调用服务方法。

#### 本地暴露服务

回到 ``org.apache.dubbo.config.ServiceConfig#doExportUrlsFor1Protocol`` 方法的 ``a`` 处,返回的方法数组只有一个元素 ``sayHello``, ``d`` 处会根据 ``scope`` 判断是否暴露服务, ``e`` 处如果不是远程暴露服务则暴露到本地,进入 ``org.apache.dubbo.config.ServiceConfig#exportLocal`` :
```
private void exportLocal(URL url) {
    URL local = URLBuilder.from(url)
    .setProtocol(LOCAL_PROTOCOL)
    .setHost(LOCALHOST_VALUE)
    .setPort(0)
    .build();
    Exporter<?> exporter = protocol.export(
        PROXY_FACTORY.getInvoker(ref, (Class) interfaceClass, local));
        exporters.add(exporter);
        logger.info("Export dubbo service " + interfaceClass.getName() + " to local registry url : " + local);
}
```
关于 ``PROXY_FACTORY`` 、``protocol`` 的初始化过程不再分析,通过Dubbo SPI实现,生成的自适应代理工厂类 ``PROXY_FACTORY`` 对象为:
```
package org.apache.dubbo.rpc;
import org.apache.dubbo.common.extension.ExtensionLoader;
public class ProxyFactory$Adaptive implements org.apache.dubbo.rpc.ProxyFactory
{
    public java.lang.Object getProxy(org.apache.dubbo.rpc.Invoker arg0) throws org.apache.dubbo.rpc.RpcException
    {
        if (arg0 == null) throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument == null");
        if (arg0.getUrl() == null) throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument getUrl() == null");
        org.apache.dubbo.common.URL url = arg0.getUrl();
        String extName = url.getParameter("proxy", "javassist");
        if(extName == null) throw new IllegalStateException("Failed to get extension (org.apache.dubbo.rpc.ProxyFactory) name from url (" + url.toString() + ") use keys([proxy])");
        org.apache.dubbo.rpc.ProxyFactory extension = (org.apache.dubbo.rpc.ProxyFactory)ExtensionLoader.getExtensionLoader(org.apache.dubbo.rpc.ProxyFactory.class).getExtension(extName);
        return extension.getProxy(arg0);
    }
    public java.lang.Object getProxy(org.apache.dubbo.rpc.Invoker arg0, boolean arg1) throws org.apache.dubbo.rpc.RpcException
    {
        if (arg0 == null) throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument == null");
        if (arg0.getUrl() == null) throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument getUrl() == null");
        org.apache.dubbo.common.URL url = arg0.getUrl();
        String extName = url.getParameter("proxy", "javassist");
        if(extName == null) throw new IllegalStateException("Failed to get extension (org.apache.dubbo.rpc.ProxyFactory) name from url (" + url.toString() + ") use keys([proxy])");
        org.apache.dubbo.rpc.ProxyFactory extension = (org.apache.dubbo.rpc.ProxyFactory)ExtensionLoader.getExtensionLoader(org.apache.dubbo.rpc.ProxyFactory.class).getExtension(extName);
        return extension.getProxy(arg0, arg1);
    }
    public org.apache.dubbo.rpc.Invoker getInvoker(java.lang.Object arg0, java.lang.Class arg1, org.apache.dubbo.common.URL arg2) throws org.apache.dubbo.rpc.RpcException
    {
        if (arg2 == null) throw new IllegalArgumentException("url == null");
        org.apache.dubbo.common.URL url = arg2;
        String extName = url.getParameter("proxy", "javassist");
        if(extName == null) throw new IllegalStateException("Failed to get extension (org.apache.dubbo.rpc.ProxyFactory) name from url (" + url.toString() + ") use keys([proxy])");
        org.apache.dubbo.rpc.ProxyFactory extension = (org.apache.dubbo.rpc.ProxyFactory)ExtensionLoader.getExtensionLoader(org.apache.dubbo.rpc.ProxyFactory.class).getExtension(extName);
        return extension.getInvoker(arg0, arg1, arg2);
    }
}
```
``getInvoker`` 方法中首先会获取 ``extName``,默认值为 ``javassist``,即默认的代理工厂类为 ``org.apache.dubbo.rpc.proxy.javassist.JavassistProxyFactory``, 在文章 [Dubbo SPI实现原理](https://lioswong.github.io/2019/09/17/Dubbo-SPI%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86/) 中知晓,该类会被包装类 ``org.apache.dubbo.rpc.proxy.wrapper.StubProxyFactoryWrapper`` 包裹,进入 ``org.apache.dubbo.rpc.proxy.javassist.JavassistProxyFactory#getInvoker`` :
```
 public <T> Invoker<T> getInvoker(T proxy, Class<T> type, URL url) {
        // TODO Wrapper cannot handle this scenario correctly: the classname contains '$'
        final Wrapper wrapper = Wrapper.getWrapper(proxy.getClass().getName().indexOf('$') < 0 ? proxy.getClass() : type);
        return new AbstractProxyInvoker<T>(proxy, type, url) {
            @Override
            protected Object doInvoke(T proxy, String methodName,
                                      Class<?>[] parameterTypes,
                                      Object[] arguments) throws Throwable {
                return wrapper.invokeMethod(proxy, methodName, parameterTypes, arguments);
            }
        };
    }
```
首先会获取包装类,然后生成 ``org.apache.dubbo.rpc.proxy.AbstractProxyInvoker`` 的匿名类,并返回.在 ``doInvoke`` 方法中实现真正的方法调用,
关于包装类 ``Wrapper`` 的生成不具体分析,和上文分析一致,看下生成的包装类: 
```
class org.apache.dubbo.common.bytecode.Wrapper1
{
    public static String[] pns;
    public static java.util.Map pts;
    public static String[] mns;
    public static String[] dmns;
    public static Class[] mts0;
    public String[] getPropertyNames()
    {
        return pns;
    }
    public boolean hasProperty(String n)
    {
        return pts.containsKey($1);
    }
    public Class getPropertyType(String n)
    {
        return (Class)pts.get($1);
    }
    public String[] getMethodNames()
    {
        return mns;
    }
    public String[] getDeclaredMethodNames()
    {
        return dmns;
    }
    public void setPropertyValue(Object o, String n, Object v)
    {
        org.apache.dubbo.demo.provider.DemoServiceImpl w;
        try
        {
            w = ((org.apache.dubbo.demo.provider.DemoServiceImpl)$1);
        }
        catch(Throwable e)
        {
            throw new IllegalArgumentException(e);
        }
        throw new org.apache.dubbo.common.bytecode.NoSuchPropertyException("Not found property \"" + $2 + "\" field or setter method in class org.apache.dubbo.demo.provider.DemoServiceImpl.");
    }
    public Object getPropertyValue(Object o, String n)
    {
        org.apache.dubbo.demo.provider.DemoServiceImpl w;
        try
        {
            w = ((org.apache.dubbo.demo.provider.DemoServiceImpl)$1);
        }
        catch(Throwable e)
        {
            throw new IllegalArgumentException(e);
        }
        throw new org.apache.dubbo.common.bytecode.NoSuchPropertyException("Not found property \"" + $2 + "\" field or setter method in class org.apache.dubbo.demo.provider.DemoServiceImpl.");
    }
    public Object invokeMethod(Object o, String n, Class[] p, Object[] v) throws java.lang.reflect.InvocationTargetException
    {
        org.apache.dubbo.demo.provider.DemoServiceImpl w;
        try
        {
            w = ((org.apache.dubbo.demo.provider.DemoServiceImpl)$1);
        }
        catch(Throwable e)
        {
            throw new IllegalArgumentException(e);
        }
        try
        {
            if( "sayHello".equals( $2 )  &&  $3.length == 1 )
            {
                return ($w)w.sayHello((java.lang.String)$4[0]);
            }
        }
        catch(Throwable e)
        {
            throw new java.lang.reflect.InvocationTargetException(e);
        }
        throw new org.apache.dubbo.common.bytecode.NoSuchMethodException("Not found method \"" + $2 + "\" in class org.apache.dubbo.demo.provider.DemoServiceImpl.");
    }
}
```
invokeMethod方法的内部逻辑十分清晰,就不多做分析,继续回到 ``org.apache.dubbo.config.ServiceConfig#exportLocal`` 方法中,上面 ``Invoker`` 对象已经生成,然后就导出服务,在[Dubbo SPI实现原理](https://lioswong.github.io/2019/09/17/Dubbo-SPI%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86/)中分析过,生成的 ``Protocol`` 会被包装类包裹,由于是本地暴露,所以结构为:
```
org.apache.dubbo.rpc.protocol.ProtocolFilterWrapper
   org.apache.dubbo.rpc.protocol.ProtocolListenerWrapper
      org.apache.dubbo.rpc.protocol.injvm.InjvmProtocol
```
即首先会调用 ``org.apache.dubbo.rpc.protocol.ProtocolFilterWrapper#export`` 方法,然后再调用 ``org.apache.dubbo.rpc.protocol.ProtocolListenerWrapper#export`` 方法,最后调用 ``org.apache.dubbo.rpc.protocol.injvm.InjvmProtocol#export`` 方法,首先进入 ``org.apache.dubbo.rpc.protocol.ProtocolFilterWrapper#export`` 方法:
```
 public <T> Exporter<T> export(Invoker<T> invoker) throws RpcException {
        // 如果协议为registry,直接暴露
        if (REGISTRY_PROTOCOL.equals(invoker.getUrl().getProtocol())) {
            return protocol.export(invoker);
        }
        // 构建过滤器调用链
        return protocol.export(buildInvokerChain(invoker, SERVICE_FILTER_KEY, CommonConstants.PROVIDER));
    }
```
上面代码注释已经说明,如果协议是非registry,则会调用 ``org.apache.dubbo.rpc.protocol.ProtocolFilterWrapper#buildInvokerChain`` 方法,进行过滤器调用链的组装,进入该方法:
```
private static <T> Invoker<T> buildInvokerChain(final Invoker<T> invoker, String key, String group) {
        Invoker<T> last = invoker;
        // 自适应扩展获取过滤器
        List<Filter> filters = ExtensionLoader.getExtensionLoader(Filter.class).getActivateExtension(invoker.getUrl(), key, group);

        if (!filters.isEmpty()) {
            for (int i = filters.size() - 1; i >= 0; i--) {
                final Filter filter = filters.get(i);
                final Invoker<T> next = last;
                last = new Invoker<T>() {

                    @Override
                    public Class<T> getInterface() {
                        return invoker.getInterface();
                    }

                    @Override
                    public URL getUrl() {
                        return invoker.getUrl();
                    }

                    @Override
                    public boolean isAvailable() {
                        return invoker.isAvailable();
                    }

                    @Override
                    public Result invoke(Invocation invocation) throws RpcException {
                        Result asyncResult;
                        try {
                            asyncResult = filter.invoke(next, invocation);
                        } catch (Exception e) {
                            // onError callback
                            if (filter instanceof ListenableFilter) {
                                Filter.Listener listener = ((ListenableFilter) filter).listener();
                                if (listener != null) {
                                    listener.onError(e, invoker, invocation);
                                }
                            }
                            throw e;
                        }
                        return asyncResult;
                    }

                    @Override
                    public void destroy() {
                        invoker.destroy();
                    }

                    @Override
                    public String toString() {
                        return invoker.toString();
                    }
                };
            }
        }
        return new CallbackRegistrationInvoker<>(last, filters);
    }
```
上面主要根据自适应扩展获取过滤器,然后循环过滤器列表,创建匿名的 ``Invoker`` 类,在``invoke``方法中调用过滤器的``invoke``方法,实现一些其他功能逻辑,获取的过滤器如下:
```
org.apache.dubbo.rpc.filter.ExceptionFilter
org.apache.dubbo.monitor.support.MonitorFilter
org.apache.dubbo.rpc.filter.TimeoutFilter
org.apache.dubbo.rpc.protocol.dubbo.filter.TraceFilter
org.apache.dubbo.rpc.filter.ContextFilter
org.apache.dubbo.rpc.filter.GenericFilter
org.apache.dubbo.rpc.filter.ClassLoaderFilter
org.apache.dubbo.rpc.filter.EchoFilter
```
根据过滤器的名称就大概知道功能,获取过滤器的过程就不多做分析,感兴趣可以调试分析,回到 ``org.apache.dubbo.rpc.protocol.ProtocolFilterWrapper#export`` 方法中,至此,过滤器链已构建完成,下一步继续调用包装类``ProtocolListenerWrapper``的``org.apache.dubbo.rpc.protocol.ProtocolListenerWrapper#export``方法:
```
public <T> Exporter<T> export(Invoker<T> invoker) throws RpcException {
        // 如果协议为registry,直接暴露
        if (REGISTRY_PROTOCOL.equals(invoker.getUrl().getProtocol())) {
            return protocol.export(invoker);
        }
        // 
        return new ListenerExporterWrapper<T>(protocol.export(invoker),
                Collections.unmodifiableList(ExtensionLoader.getExtensionLoader(ExporterListener.class)
                        .getActivateExtension(invoker.getUrl(), EXPORTER_LISTENER_KEY)));
    }
```
如果协议为registry,直接暴露,否则会先暴露,然后获取监听器列表,构建ListenerExporterWrapper对象返回.由于本地暴露,所以直接导出到本地, 进入到 ```org.apache.dubbo.rpc.protocol.injvm.InjvmProtocol#export``:
```
public <T> Exporter<T> export(Invoker<T> invoker) throws RpcException {
        return new InjvmExporter<T>(invoker, invoker.getUrl().getServiceKey(), exporterMap);
    }
```
直接创建对象 ``InjvmExporter`` 返回,并把 ``InjvmExporter`` 放入缓存 ``exporterMap``中.回到 ``org.apache.dubbo.rpc.protocol.ProtocolListenerWrapper#export``中,本地服务导出很简单,然后通过 
```
ExtensionLoader.getExtensionLoader(ExporterListener.class)
                        .getActivateExtension(invoker.getUrl(), EXPORTER_LISTENER_KEY)
```
自适应扩展获取监听器列表,该过程不再分析,然后进入到 ```org.apache.dubbo.rpc.listener.ListenerExporterWrapper#ListenerExporterWrapper``` 中:
```
    public ListenerExporterWrapper(Exporter<T> exporter, List<ExporterListener> listeners) {
        // 如果exporter为空则抛异常
        if (exporter == null) {
            throw new IllegalArgumentException("exporter == null");
        }
        this.exporter = exporter;
        this.listeners = listeners;
        if (CollectionUtils.isNotEmpty(listeners)) {
            RuntimeException exception = null;
            // 循环调用监听器
            for (ExporterListener listener : listeners) {
                if (listener != null) {
                    try {
                        listener.exported(this);
                    } catch (RuntimeException t) {
                        logger.error(t.getMessage(), t);
                        exception = t;
                    }
                }
            }
            if (exception != null) {
                throw exception;
            }
        }
    }
```
调试过程中发现,``listeners`` 为空,也就是这里dubbo没有实现自己的监听器,所以用户可以在服务暴露完成或者不暴露添加自定义监听器,用于业务逻辑的处理.
分析到这里,本地暴露基本完成,回到 ``org.apache.dubbo.config.ServiceConfig#exportLocal`` 中,暴露结束后,会把 ``exporter`` 放入到缓存中.
#### 服务远程暴露
让我们再回到 ``org.apache.dubbo.config.ServiceConfig#doExportUrlsFor1Protocol``,下面判断如果没有配置本地暴露,则远程暴露,然后循环协议列表 ``registryURLs`` 逐个暴露服务,我们着重分析以下几行代码:
```
Invoker<?> invoker = PROXY_FACTORY.getInvoker(ref, (Class) interfaceClass, registryURL.addParameterAndEncoded(EXPORT_KEY, url.toFullString()));
DelegateProviderMetaDataInvoker wrapperInvoker = new DelegateProviderMetaDataInvoker(invoker, this);
Exporter<?> exporter = protocol.export(wrapperInvoker);
exporters.add(exporter);
```
关于 ``invoker`` 的获取,在本地暴露时已经分析,由于本地依据暴露完成,所以 ``JavassistProxyFactory``、``Wrapper``直接从缓存中获取即可,不再分析.然后构建对象 ``DelegateProviderMetaDataInvoker``,然后服务导出,由本地导出可知,通过自适应扩展动态获取的 ``RegistryProtocol`` 对象被对象 ``ProtocolFilterWrapper``、``ProtocolListenerWrapper`` 包裹,但是注意,由于此时协议为``registry``,所以再这两个类中导出时不作任何处理,直接进入 ``org.apache.dubbo.registry.integration.RegistryProtocol#export``:
```
    public <T> Exporter<T> export(final Invoker<T> originInvoker) throws RpcException {
        // 获取URL,用于向注册中心注册
        URL registryUrl = getRegistryUrl(originInvoker);
        // url to export locally  获取URL用于导出服务
        URL providerUrl = getProviderUrl(originInvoker);

        // Subscribe the override data
        // FIXME When the provider subscribes, it will affect the scene : a certain JVM exposes the service and call
        //  the same service. Because the subscribed is cached key with the name of the service, it causes the
        //  subscription information to cover.
        final URL overrideSubscribeUrl = getSubscribedOverrideUrl(providerUrl);
        final OverrideListener overrideSubscribeListener = new OverrideListener(overrideSubscribeUrl, originInvoker);
        overrideListeners.put(overrideSubscribeUrl, overrideSubscribeListener);

        providerUrl = overrideUrlWithConfig(providerUrl, overrideSubscribeListener);
        //export invoker 导出服务
        final ExporterChangeableWrapper<T> exporter = doLocalExport(originInvoker, providerUrl);

        // url to registry
        final Registry registry = getRegistry(originInvoker);
        final URL registeredProviderUrl = getRegisteredProviderUrl(providerUrl, registryUrl);
        ProviderInvokerWrapper<T> providerInvokerWrapper = ProviderConsumerRegTable.registerProvider(originInvoker,
                registryUrl, registeredProviderUrl);
        //to judge if we need to delay publish
        boolean register = registeredProviderUrl.getParameter("register", true);
        if (register) {
            register(registryUrl, registeredProviderUrl);
            providerInvokerWrapper.setReg(true);
        }

        // Deprecated! Subscribe to override rules in 2.6.x or before.
        registry.subscribe(overrideSubscribeUrl, overrideSubscribeListener);

        exporter.setRegisterUrl(registeredProviderUrl);
        exporter.setSubscribeUrl(overrideSubscribeUrl);
        //Ensure that a new exporter instance is returned every time export
        return new DestroyableExporter<>(exporter);
    }
```
首先获取注册URL,在后面往注册中心注册服务会用到,然后获取服务提供者URL,用于服务导出,例如:
```
dubbo://192.168.1.220:20880/org.apache.dubbo.demo.DemoService?anyhost=true&application=dubbo-demo-api-provider&bind.ip=192.168.1.220&bind.port=20880&deprecated=false&dubbo=2.0.2&dynamic=true&generic=false&interface=org.apache.dubbo.demo.DemoService&methods=sayHello&pid=11557&release=&side=provider&timestamp=1569413558031
```
断点进入``org.apache.dubbo.registry.integration.RegistryProtocol#doLocalExport``:
```
private <T> ExporterChangeableWrapper<T> doLocalExport(final Invoker<T> originInvoker, URL providerUrl) {
        String key = getCacheKey(originInvoker);
        return (ExporterChangeableWrapper<T>) bounds.computeIfAbsent(key, s -> {
            // 创建InvokerDelegate封装originInvoker, providerUrl
            Invoker<?> invokerDelegate = new InvokerDelegate<>(originInvoker, providerUrl);
            return new ExporterChangeableWrapper<>((Exporter<T>) protocol.export(invokerDelegate), originInvoker);
        });
    }
```
首先从缓存中获取key-value的值,如果key-value值不存在,则重新获取,再重新获取时,就需要暴露服务,一般key为:
```
dubbo://192.168.1.220:20880/org.apache.dubbo.demo.DemoService?anyhost=true&application=dubbo-demo-api-provider&bind.ip=192.168.1.220&bind.port=20880&deprecated=false&dubbo=2.0.2&generic=false&interface=org.apache.dubbo.demo.DemoService&methods=sayHello&pid=11557&release=&side=provider&timestamp=1569413558031
```
暴露服务时,还是通过Dubbo SPI自适应扩展实现,动态获取到的对象结构如下:
```
org.apache.dubbo.rpc.protocol.ProtocolFilterWrapper
  org.apache.dubbo.rpc.protocol.ProtocolListenerWrapper
     org.apache.dubbo.rpc.protocol.dubbo.DubboProtocol
```
``DubboProtocol`` 被包装类包装,所以在导出时首先调用的是 ``ProtocolFilterWrapper``的``export`` 方法,同样与本地服务导出一样,同样会构建过滤器链,这里就不再重述;然后继续调用 ``ProtocolListenerWrapper``的 ``export`` 方法,在该方法中,首先进行服务的暴露,然后再根据自适应扩展获取监听器类列表,再构建``ListenerExporterWrapper``对象返回,与本地暴露一样.但是这里服务暴露会调用 ``org.apache.dubbo.rpc.protocol.dubbo.DubboProtocol#export``:
```
public <T> Exporter<T> export(Invoker<T> invoker) throws RpcException {
    URL url = invoker.getUrl();

    // export service.
    String key = serviceKey(url);  
    DubboExporter<T> exporter = new DubboExporter<T>(invoker, key, exporterMap);
    exporterMap.put(key, exporter);

    //export an stub service for dispatching event
    Boolean isStubSupportEvent = url.getParameter(STUB_EVENT_KEY, DEFAULT_STUB_EVENT);
    Boolean isCallbackservice = url.getParameter(IS_CALLBACK_SERVICE, false);
    if (isStubSupportEvent && !isCallbackservice) {
        String stubServiceMethods = url.getParameter(STUB_EVENT_METHODS_KEY);
        if (stubServiceMethods == null || stubServiceMethods.length() == 0) {
            if (logger.isWarnEnabled()) {
                logger.warn(new IllegalStateException("consumer [" + url.getParameter(INTERFACE_KEY) +
                "], has set stubproxy support event ,but no stub methods founded."));
            }
            } else {
                stubServiceMethodsMap.put(url.getServiceKey(), stubServiceMethods);
            }
        }
        openServer(url);
        optimizeSerialization(url);
        return exporter;
}
```
首先获取service key,这里的值为``org.apache.dubbo.demo.DemoService:20880``,然后创建DubboExporter对象,放入缓存Map中,直接进入到``org.apache.dubbo.rpc.protocol.dubbo.DubboProtocol#openServer``:
```
 private void openServer(URL url) {
        // find server.  
        String key = url.getAddress(); 
        //client can export a service which's only for server to invoke
        boolean isServer = url.getParameter(IS_SERVER_KEY, true);
        if (isServer) {
            // 从缓存中获取ExchangeServer
            ExchangeServer server = serverMap.get(key);
            if (server == null) {
                synchronized (this) {
                    server = serverMap.get(key);
                    if (server == null) {
                        serverMap.put(key, createServer(url));
                    }
                }
            } else {
                // server supports reset, use together with override
                server.reset(url);
            }
        }
    }
```
首先获取到服务提供者地址,例如``192.168.1.220:20880``,根据URL判断,如果是服务提供者,则从缓存中获取ExchangeServer,如果缓存为空,则创建,断点进入到``org.apache.dubbo.rpc.protocol.dubbo.DubboProtocol#createServer``:
```
    private ExchangeServer createServer(URL url) {
        url = URLBuilder.from(url)
                // send readonly event when server closes, it's enabled by default
                .addParameterIfAbsent(CHANNEL_READONLYEVENT_SENT_KEY, Boolean.TRUE.toString())
                // enable heartbeat by default
                .addParameterIfAbsent(HEARTBEAT_KEY, String.valueOf(DEFAULT_HEARTBEAT))
                .addParameter(CODEC_KEY, DubboCodec.NAME)
                .build();
        // 获取通信协议,默认为netty
        String str = url.getParameter(SERVER_KEY, DEFAULT_REMOTING_SERVER);

        if (str != null && str.length() > 0 && !ExtensionLoader.getExtensionLoader(Transporter.class).hasExtension(str)) {
            throw new RpcException("Unsupported server type: " + str + ", url: " + url);
        }

        ExchangeServer server;
        try {
            server = Exchangers.bind(url, requestHandler);
        } catch (RemotingException e) {
            throw new RpcException("Fail to start server(url: " + url + ") " + e.getMessage(), e);
        }

        str = url.getParameter(CLIENT_KEY);
        if (str != null && str.length() > 0) {
            Set<String> supportedTypes = ExtensionLoader.getExtensionLoader(Transporter.class).getSupportedExtensions();
            if (!supportedTypes.contains(str)) {
                throw new RpcException("Unsupported client type: " + str);
            }
        }

        return server;
    }
```
首先构建URL,添加属性参数,比如心跳、编码解码器参数,默认通信协议是netty,传入的``requestHandler``是ExchangeHandler类型,这个类十分重要,服务提供者在收到消费这请求时,会通过该处理器处理,实现方法的调用.然后根据自适应扩展判断是否存在协议通信类,然后再进行服务的绑定,进入``org.apache.dubbo.remoting.exchange.Exchangers#bind``:
```
public static ExchangeServer bind(URL url, ExchangeHandler handler) throws RemotingException {
        if (url == null) {
            throw new IllegalArgumentException("url == null");
        }
        if (handler == null) {
            throw new IllegalArgumentException("handler == null");
        }
        url = url.addParameterIfAbsent(Constants.CODEC_KEY, "exchange");
        return getExchanger(url).bind(url, handler);
    }
```
根据自适应扩展动态获取到对象``org.apache.dubbo.remoting.exchange.support.header.HeaderExchanger``,然后继续调用``org.apache.dubbo.remoting.exchange.support.header.HeaderExchanger#bind``:
```
public ExchangeServer bind(URL url, ExchangeHandler handler) throws RemotingException {
    return new HeaderExchangeServer(Transporters.bind(url, new DecodeHandler(new HeaderExchangeHandler(handler))));
}
```
首先对传入的``handler``进行包裹,然后调用``org.apache.dubbo.remoting.Transporters#bind``方法:
```
public static Server bind(URL url, ChannelHandler... handlers) throws RemotingException {
        if (url == null) {
            throw new IllegalArgumentException("url == null");
        }
        if (handlers == null || handlers.length == 0) {
            throw new IllegalArgumentException("handlers == null");
        }
        ChannelHandler handler;
        if (handlers.length == 1) {
            handler = handlers[0];
        } else {
            handler = new ChannelHandlerDispatcher(handlers);
        }
        return getTransporter().bind(url, handler);
}
```
``getTransporter``获取自适应扩展类,具体过程不再分析,然后根据URL动态获取具体的实现,断点进入``org.apache.dubbo.remoting.transport.netty4.NettyTransporter#bind``:
```
 public Server bind(URL url, ChannelHandler listener) throws RemotingException {
        return new NettyServer(url, listener);
}
```
创建了NettyServer对象,进入其构造函数:
```
  public NettyServer(URL url, ChannelHandler handler) throws RemotingException {
        // you can customize name and type of client thread pool by THREAD_NAME_KEY and THREADPOOL_KEY in CommonConstants.
        // the handler will be warped: MultiMessageHandler->HeartbeatHandler->handler
        super(url, ChannelHandlers.wrap(handler, ExecutorUtil.setThreadName(url, SERVER_THREAD_POOL_NAME)));
    }
```
继续进入父类的构造函数``org.apache.dubbo.remoting.transport.AbstractServer#AbstractServer``:
```
public AbstractServer(URL url, ChannelHandler handler) throws RemotingException {
        super(url, handler);
        localAddress = getUrl().toInetSocketAddress();

        String bindIp = getUrl().getParameter(Constants.BIND_IP_KEY, getUrl().getHost());
        int bindPort = getUrl().getParameter(Constants.BIND_PORT_KEY, getUrl().getPort());
        if (url.getParameter(ANYHOST_KEY, false) || NetUtils.isInvalidLocalHost(bindIp)) {
            bindIp = ANYHOST_VALUE;
        }
        bindAddress = new InetSocketAddress(bindIp, bindPort);
        this.accepts = url.getParameter(ACCEPTS_KEY, DEFAULT_ACCEPTS);
        this.idleTimeout = url.getParameter(IDLE_TIMEOUT_KEY, DEFAULT_IDLE_TIMEOUT);
        try {
            doOpen();
            if (logger.isInfoEnabled()) {
                logger.info("Start " + getClass().getSimpleName() + " bind " + getBindAddress() + ", export " + getLocalAddress());
            }
        } catch (Throwable t) {
            throw new RemotingException(url.toInetSocketAddress(), null, "Failed to bind " + getClass().getSimpleName()
                    + " on " + getLocalAddress() + ", cause: " + t.getMessage(), t);
        }
        //fixme replace this with better method
        DataStore dataStore = ExtensionLoader.getExtensionLoader(DataStore.class).getDefaultExtension();
        executor = (ExecutorService) dataStore.get(Constants.EXECUTOR_SERVICE_COMPONENT_KEY, Integer.toString(url.getPort()));
}
```
再进入父类构造函数:
```
public AbstractEndpoint(URL url, ChannelHandler handler) {
        super(url, handler);
        // 编解码器
        this.codec = getChannelCodec(url);
        this.timeout = url.getPositiveParameter(TIMEOUT_KEY, DEFAULT_TIMEOUT);
        this.connectTimeout = url.getPositiveParameter(Constants.CONNECT_TIMEOUT_KEY, Constants.DEFAULT_CONNECT_TIMEOUT);
}
```
上面会获取编解码器,默认获取的是``org.apache.dubbo.rpc.protocol.dubbo.DubboCountCodec``,再获取远程服务调用超时时间、netty连接超时时间.
再回到``org.apache.dubbo.remoting.transport.AbstractServer#AbstractServer``中,根据URL获取服务提供者的IP、端口号,据此创建对象 ``InetSocketAddress``,进入``org.apache.dubbo.remoting.transport.netty4.NettyServer#doOpen``,该方法是模版方法,具体实现有子类完成: 
```
    @Override
    protected void doOpen() throws Throwable {
        bootstrap = new ServerBootstrap();

        bossGroup = new NioEventLoopGroup(1, new DefaultThreadFactory("NettyServerBoss", true));
        workerGroup = new NioEventLoopGroup(getUrl().getPositiveParameter(IO_THREADS_KEY, Constants.DEFAULT_IO_THREADS),
                new DefaultThreadFactory("NettyServerWorker", true));

        final NettyServerHandler nettyServerHandler = new NettyServerHandler(getUrl(), this);
        channels = nettyServerHandler.getChannels();

        bootstrap.group(bossGroup, workerGroup)
                .channel(NioServerSocketChannel.class)
                .childOption(ChannelOption.TCP_NODELAY, Boolean.TRUE)
                .childOption(ChannelOption.SO_REUSEADDR, Boolean.TRUE)
                .childOption(ChannelOption.ALLOCATOR, PooledByteBufAllocator.DEFAULT)
                .childHandler(new ChannelInitializer<NioSocketChannel>() {
                    @Override
                    protected void initChannel(NioSocketChannel ch) throws Exception {
                        // FIXME: should we use getTimeout()?
                        int idleTimeout = UrlUtils.getIdleTimeout(getUrl());
                        NettyCodecAdapter adapter = new NettyCodecAdapter(getCodec(), getUrl(), NettyServer.this);
                        ch.pipeline()//.addLast("logging",new LoggingHandler(LogLevel.INFO))//for debug
                                .addLast("decoder", adapter.getDecoder())
                                .addLast("encoder", adapter.getEncoder())
                                .addLast("server-idle-handler", new IdleStateHandler(0, 0, idleTimeout, MILLISECONDS))
                                .addLast("handler", nettyServerHandler);
                    }
                });
        // bind 服务绑定
        ChannelFuture channelFuture = bootstrap.bind(getBindAddress());
        channelFuture.syncUninterruptibly();
        channel = channelFuture.channel();

    }
```
这里很清楚的看到netty相关的类了,在这里进行服务端口的暴露,关于netty相关知识在这里不作介绍了.
#### 服务注册
继续回到``org.apache.dubbo.registry.integration.RegistryProtocol#export``中.
然后获取Registry、注册服务提供者URL对象,然后在往注册中心注册服务,进入``org.apache.dubbo.registry.support.FailbackRegistry#register``:
```
@Override
    public void register(URL url) {
        super.register(url);
        removeFailedRegistered(url);
        removeFailedUnregistered(url);
        try {
            // Sending a registration request to the server side
            doRegister(url);
        } catch (Exception e) {
            Throwable t = e;

            // If the startup detection is opened, the Exception is thrown directly.
            boolean check = getUrl().getParameter(Constants.CHECK_KEY, true)
                    && url.getParameter(Constants.CHECK_KEY, true)
                    && !CONSUMER_PROTOCOL.equals(url.getProtocol());
            boolean skipFailback = t instanceof SkipFailbackWrapperException;
            if (check || skipFailback) {
                if (skipFailback) {
                    t = t.getCause();
                }
                throw new IllegalStateException("Failed to register " + url + " to registry " + getUrl().getAddress() + ", cause: " + t.getMessage(), t);
            } else {
                logger.error("Failed to register " + url + ", waiting for retry, cause: " + t.getMessage(), t);
            }

            // Record a failed registration request to a failed list, retry regularly
            addFailedRegistered(url);
        }
    }
```
在doRegister完成注册的逻辑:
```
 public void doRegister(URL url) {
        try {
            zkClient.create(toUrlPath(url), url.getParameter(DYNAMIC_KEY, true));
        } catch (Throwable e) {
            throw new RpcException("Failed to register " + url + " to zookeeper " + getUrl() + ", cause: " + e.getMessage(), e);
        }
    }
```
进入``org.apache.dubbo.remoting.zookeeper.support.AbstractZookeeperClient#create``:
```
 public void create(String path, boolean ephemeral) {
        if (!ephemeral) {
            if(persistentExistNodePath.contains(path)){
                return;
            }
            if (checkExists(path)) {
                persistentExistNodePath.add(path);
                return;
            }
        }
        int i = path.lastIndexOf('/');
        if (i > 0) {
            create(path.substring(0, i), false);
        }
        if (ephemeral) {
            createEphemeral(path);
        } else {
            createPersistent(path);
            persistentExistNodePath.add(path);
        }
    }
```
依次创建持久结点:
```
/dubbo
/dubbo/org.apache.dubbo.demo.DemoService
/dubbo/org.apache.dubbo.demo.DemoService/providers
```
最后创建临时结点:
```
/dubbo/org.apache.dubbo.demo.DemoService/providers/dubbo%3A%2F%2F192.168.1.220%3A20880%2Forg.apache.dubbo.demo.DemoService%3Fanyhost%3Dtrue%26application%3Ddubbo-demo-api-provider%26deprecated%3Dfalse%26dubbo%3D2.0.2%26dynamic%3Dtrue%26generic%3Dfalse%26interface%3Dorg.apache.dubbo.demo.DemoService%26methods%3DsayHello%26pid%3D19865%26release%3D%26side%3Dprovider%26timestamp%3D1569551377814
```
此时服务往注册中心已经注册完成.
#### 服务订阅
进入 ``org.apache.dubbo.registry.support.FailbackRegistry#subscribe``:
```
    public void subscribe(URL url, NotifyListener listener) {
        super.subscribe(url, listener);
        removeFailedSubscribed(url, listener);
        try {
            // Sending a subscription request to the server side
            doSubscribe(url, listener);
        } catch (Exception e) {
            Throwable t = e;

            List<URL> urls = getCacheUrls(url);
            if (CollectionUtils.isNotEmpty(urls)) {
                notify(url, listener, urls);
                logger.error("Failed to subscribe " + url + ", Using cached list: " + urls + " from cache file: " + getUrl().getParameter(FILE_KEY, System.getProperty("user.home") + "/dubbo-registry-" + url.getHost() + ".cache") + ", cause: " + t.getMessage(), t);
            } else {
                // If the startup detection is opened, the Exception is thrown directly.
                boolean check = getUrl().getParameter(Constants.CHECK_KEY, true)
                        && url.getParameter(Constants.CHECK_KEY, true);
                boolean skipFailback = t instanceof SkipFailbackWrapperException;
                if (check || skipFailback) {
                    if (skipFailback) {
                        t = t.getCause();
                    }
                    throw new IllegalStateException("Failed to subscribe " + url + ", cause: " + t.getMessage(), t);
                } else {
                    logger.error("Failed to subscribe " + url + ", waiting for retry, cause: " + t.getMessage(), t);
                }
            }

            // Record a failed registration request to a failed list, retry regularly
            addFailedSubscribed(url, listener);
        }
    }
```
继续进入方法``doSubscribe``:
```
    public void doSubscribe(final URL url, final NotifyListener listener) {
        try {
            if (ANY_VALUE.equals(url.getServiceInterface())) {
                String root = toRootPath();
                ConcurrentMap<NotifyListener, ChildListener> listeners = zkListeners.get(url);
                if (listeners == null) {
                    zkListeners.putIfAbsent(url, new ConcurrentHashMap<>());
                    listeners = zkListeners.get(url);
                }
                ChildListener zkListener = listeners.get(listener);
                if (zkListener == null) {
                    listeners.putIfAbsent(listener, (parentPath, currentChilds) -> {
                        for (String child : currentChilds) {
                            child = URL.decode(child);
                            if (!anyServices.contains(child)) {
                                anyServices.add(child);
                                subscribe(url.setPath(child).addParameters(INTERFACE_KEY, child,
                                        Constants.CHECK_KEY, String.valueOf(false)), listener);
                            }
                        }
                    });
                    zkListener = listeners.get(listener);
                }
                zkClient.create(root, false);
                List<String> services = zkClient.addChildListener(root, zkListener);
                if (CollectionUtils.isNotEmpty(services)) {
                    for (String service : services) {
                        service = URL.decode(service);
                        anyServices.add(service);
                        subscribe(url.setPath(service).addParameters(INTERFACE_KEY, service,
                                Constants.CHECK_KEY, String.valueOf(false)), listener);
                    }
                }
            } else {
                List<URL> urls = new ArrayList<>();
                for (String path : toCategoriesPath(url)) {
                    ConcurrentMap<NotifyListener, ChildListener> listeners = zkListeners.get(url);
                    if (listeners == null) {
                        zkListeners.putIfAbsent(url, new ConcurrentHashMap<>());
                        listeners = zkListeners.get(url);
                    }
                    ChildListener zkListener = listeners.get(listener);
                    if (zkListener == null) {
                        listeners.putIfAbsent(listener, (parentPath, currentChilds) -> ZookeeperRegistry.this.notify(url, listener, toUrlsWithEmpty(url, parentPath, currentChilds)));
                        zkListener = listeners.get(listener);
                    }
                    zkClient.create(path, false);
                    List<String> children = zkClient.addChildListener(path, zkListener);
                    if (children != null) {
                        urls.addAll(toUrlsWithEmpty(url, path, children));
                    }
                }
                notify(url, listener, urls);
            }
        } catch (Throwable e) {
            throw new RpcException("Failed to subscribe " + url + " to zookeeper " + getUrl() + ", cause: " + e.getMessage(), e);
        }
    }
```
上面主要是往zk服务端注册客户端的监听回调,当zk服务端结点发生变化时,会通知zk客户端,具体进入 ``org.apache.dubbo.registry.support.FailbackRegistry#notify``,该方法中调用 ``org.apache.dubbo.registry.support.FailbackRegistry#doNotify``处理,继续调用父类``org.apache.dubbo.registry.support.AbstractRegistry#notify``:
```
protected void notify(URL url, NotifyListener listener, List<URL> urls) {
        ...
        ...
        ...
        Map<String, List<URL>> categoryNotified = notified.computeIfAbsent(url, u -> new ConcurrentHashMap<>());
        for (Map.Entry<String, List<URL>> entry : result.entrySet()) {
            String category = entry.getKey();
            List<URL> categoryList = entry.getValue();
            categoryNotified.put(category, categoryList);
            // 调用监听器通知
            listener.notify(categoryList);
            // We will update our cache file after each notification.
            // When our Registry has a subscribe failure due to network jitter, we can return at least the existing cache URL.
            // 持久化到磁盘文件
            saveProperties(url);
        }
    }
```
首先看监听器的notify方法,该方法又调用doOverrideIfNecessary进行处理:
```
public synchronized void doOverrideIfNecessary() {
            final Invoker<?> invoker;
            if (originInvoker instanceof InvokerDelegate) {
                invoker = ((InvokerDelegate<?>) originInvoker).getInvoker();
            } else {
                invoker = originInvoker;
            }
            //The origin invoker
            URL originUrl = RegistryProtocol.this.getProviderUrl(invoker);
            String key = getCacheKey(originInvoker);
            ExporterChangeableWrapper<?> exporter = bounds.get(key);
            if (exporter == null) {
                logger.warn(new IllegalStateException("error state, exporter should not be null"));
                return;
            }
            //The current, may have been merged many times
            URL currentUrl = exporter.getInvoker().getUrl();
            //Merged with this configuration
            URL newUrl = getConfigedInvokerUrl(configurators, originUrl);
            newUrl = getConfigedInvokerUrl(providerConfigurationListener.getConfigurators(), newUrl);
            newUrl = getConfigedInvokerUrl(serviceConfigurationListeners.get(originUrl.getServiceKey())
                    .getConfigurators(), newUrl);
            if (!currentUrl.equals(newUrl)) {
                RegistryProtocol.this.reExport(originInvoker, newUrl);
                logger.info("exported provider url changed, origin url: " + originUrl +
                        ", old export url: " + currentUrl + ", new export url: " + newUrl);
            }
        }
```
上面主要就是比较当前与最新的URL,如果不相等,则根据最新的URL重新进行服务的暴露.再回到``org.apache.dubbo.registry.support.AbstractRegistry#notify``中,下一步会把URL信息持久化到本地磁盘,感兴趣可自己分析代码,具体保存的目录及文件信息如下:
```
➜  ~ cd .dubbo 
➜  .dubbo pwd
/Users/lioswong/.dubbo
➜  .dubbo cat dubbo-registry-dubbo-demo-api-provider-127.0.0.1:2181.cache 
#Dubbo Registry Cache
#Sun Sep 29 11:13:03 CST 2019
org.apache.dubbo.demo.DemoService=empty\://192.168.31.40\:20880/org.apache.dubbo.demo.DemoService?anyhost\=true&application\=dubbo-demo-api-provider&bind.ip\=192.168.31.40&bind.port\=20880&category\=configurators&check\=false&deprecated\=false&dubbo\=2.0.2&dynamic\=true&generic\=false&interface\=org.apache.dubbo.demo.DemoService&methods\=sayHello&pid\=8443&release\=&side\=provider&timestamp\=1569602514942
```
#### 总结
由于时间问题,分析的过程比较粗糙,上文主要介绍Wrapper和Invoker的创建、服务本地暴露、服务远程暴露、服务注册、服务订阅等,尤其理解Wrapper、Invoker的创建过程至关重要.

> 参考文档

1. [http://dubbo.apache.org/zh-cn/docs/source_code_guide/export-service.html](http://dubbo.apache.org/zh-cn/docs/source_code_guide/export-service.html)
