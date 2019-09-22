---
title: Dubbo SPI实现原理
date: 2019-09-17 14:07:56
tags:
- java
- dubbo
- RPC
categories:
- Dubbo   
copyright: true #版权声明开启       
---
Dubbo 并未使用 Java 原生的 SPI 机制,而是对其进行了增强,使其能够更好的满足需求,在 Dubbo 中，SPI 是一个非常重要的模块。基于 SPI,我们可以很容易的对 Dubbo 进行拓展.  
本篇文章通过示例说明,先 [download](https://github.com/apache/dubbo) 代码，然后在 ``demo-dubbo --》 dubbo-demo-api --》 dubbo-demo-api-provider`` 下新建类:
```
@SPI("robot")
public interface Robot {
    @Adaptive
    void sayHello();
}

public class Bumblebee implements Robot{
    @Override
    public void sayHello() {
        System.out.println("Hello, I am Bumblebee.");
    }
}

public class OptimusPrime implements Robot{
    @Override
    public void sayHello() {
        System.out.println("Hello, I am Optimus Prime.");
    }
}
```
然后在 ``resources`` 文件夹下创建 ``META-INF/dubbo/internal`` ,再在该文件夹下创建文件 ``org.apache.dubbo.demo.provider.Robot``,并写入:
```
optimusPrime = org.apache.dubbo.demo.provider.OptimusPrime
bumblebee = org.apache.dubbo.demo.provider.Bumblebee
```
测试方法如下:
```
public class Test {
    public static void main(String[] args) throws Exception {
        ExtensionLoader<Robot> extensionLoader =
                ExtensionLoader.getExtensionLoader(Robot.class);
        Robot optimusPrime = extensionLoader.getExtension("optimusPrime");
        optimusPrime.sayHello();
        Robot bumblebee = extensionLoader.getExtension("bumblebee");
        bumblebee.sayHello();
    }
}
```
#### ExtensionLoader#getExtensionLoader 实现原理
然后运行该 ``Test`` 类的main方法,从断点进入 ``org.apache.dubbo.common.extension.ExtensionLoader#getExtensionLoader`` 方法,用于获取 ``ExtensionLoader`` 实例:
```
public static <T> ExtensionLoader<T> getExtensionLoader(Class<T> type) {
        // type为空抛出异常
        if (type == null) {
            throw new IllegalArgumentException("Extension type == null");
        }
        // 不是接口抛出异常
        if (!type.isInterface()) {
            throw new IllegalArgumentException("Extension type (" + type + ") is not an interface!");
        }
        // 若没有SPI注解抛出异常
        if (!withExtensionAnnotation(type)) {
            throw new IllegalArgumentException("Extension type (" + type +
                    ") is not an extension, because it is NOT annotated with @" + SPI.class.getSimpleName() + "!");
        }
        // 从缓存EXTENSION_LOADERS获取
        ExtensionLoader<T> loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
        if (loader == null) {
            EXTENSION_LOADERS.putIfAbsent(type, new ExtensionLoader<T>(type));
            loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
        }
        return loader;
    }
```
首选会检查type是否为空、type是否为接口、type是否有SPI注解(Robot必须有SPI注解,否则会报错),再从缓存中获取 ``ExtensionLoader``,如果为空,从新创建ExtensionLoader实例,断点进入 ``ExtensionLoader`` 构造函数:
```
  private ExtensionLoader(Class<?> type) {
        this.type = type;
        objectFactory = (type == ExtensionFactory.class ? null : ExtensionLoader.getExtensionLoader(ExtensionFactory.class).getAdaptiveExtension());
    }
```
如果type是 ``ExtensionFactory.class`` 时,objectFactory初始化为null,否则执行 ``ExtensionLoader.getExtensionLoader(ExtensionFactory.class).getAdaptiveExtension()`` ,断点继续进入,还是会进入 ``org.apache.dubbo.common.extension.ExtensionLoader#getExtensionLoader`` 方法,这里就不做分析,由于此时type为 ``ExtensionFactory.class`` ,所以objectFactory为null,这里分析``org.apache.dubbo.common.extension.ExtensionLoader#getAdaptiveExtension`` ,断点进入:
```
        // cachedAdaptiveInstance
        Object instance = cachedAdaptiveInstance.get();
        if (instance == null) {
            // createAdaptiveInstanceError不为null则报错
            if (createAdaptiveInstanceError != null) {
                throw new IllegalStateException("Failed to create adaptive instance: " +
                        createAdaptiveInstanceError.toString(),
                        createAdaptiveInstanceError);
            }
            // dubbo里常出现的双重检查
            synchronized (cachedAdaptiveInstance) {
                instance = cachedAdaptiveInstance.get();
                if (instance == null) {
                    try {
                        // instance为空,则创建
                        instance = createAdaptiveExtension();
                        cachedAdaptiveInstance.set(instance);
                    } catch (Throwable t) {
                        createAdaptiveInstanceError = t;
                        throw new IllegalStateException("Failed to create adaptive instance: " + t.toString(), t);
                    }
                }
            }
        }

        return (T) instance;
```
断点进入 ``org.apache.dubbo.common.extension.ExtensionLoader#createAdaptiveExtension``:
```
 private T createAdaptiveExtension() {
        try {
            return injectExtension((T) getAdaptiveExtensionClass().newInstance());
        } catch (Exception e) {
            throw new IllegalStateException("Can't create adaptive extension " + type + ", cause: " + e.getMessage(), e);
        }
    }
```
``injectExtension`` 负责扩展点的依赖注入，``getAdaptiveExtensionClass`` 方法为了获取自适应扩展类,断点进入``org.apache.dubbo.common.extension.ExtensionLoader#getAdaptiveExtensionClass`` :
```
  private Class<?> getAdaptiveExtensionClass() {
        getExtensionClasses();
        if (cachedAdaptiveClass != null) {
            return cachedAdaptiveClass;
        }
        return cachedAdaptiveClass = createAdaptiveExtensionClass();
    }
```
无疑继续进入方法 ``getExtensionClasses`` ,获取扩展类:
```
private Map<String, Class<?>> getExtensionClasses() {
        Map<String, Class<?>> classes = cachedClasses.get();
        if (classes == null) {
            synchronized (cachedClasses) {
                classes = cachedClasses.get();
                if (classes == null) {
                    classes = loadExtensionClasses();
                    cachedClasses.set(classes);
                }
            }
        }
        return classes;
    }
```
这里也没什么好说的,首先从缓存里获取,缓存里没有则调用 ``loadExtensionClasses`` 加载,断点进入:
```
private Map<String, Class<?>> loadExtensionClasses() {
        cacheDefaultExtensionName();

        Map<String, Class<?>> extensionClasses = new HashMap<>();
        loadDirectory(extensionClasses, DUBBO_INTERNAL_DIRECTORY, type.getName());
        loadDirectory(extensionClasses, DUBBO_INTERNAL_DIRECTORY, type.getName().replace("org.apache", "com.alibaba"));
        loadDirectory(extensionClasses, DUBBO_DIRECTORY, type.getName());
        loadDirectory(extensionClasses, DUBBO_DIRECTORY, type.getName().replace("org.apache", "com.alibaba"));
        loadDirectory(extensionClasses, SERVICES_DIRECTORY, type.getName());
        loadDirectory(extensionClasses, SERVICES_DIRECTORY, type.getName().replace("org.apache", "com.alibaba"));
        return extensionClasses;
    }
```
会从目录
```
META-INF/dubbo/internal/
META-INF/dubbo/
META-INF/services/
```
中根据type名称加载文件,此时type.getName为 ``org.apache.dubbo.common.extension.ExtensionFactory`` ,继续进入 ``loadDirectory`` :
```
private void loadDirectory(Map<String, Class<?>> extensionClasses, String dir, String type) {
        String fileName = dir + type;
        try {
            Enumeration<java.net.URL> urls;
            ClassLoader classLoader = findClassLoader();
            if (classLoader != null) {
                urls = classLoader.getResources(fileName);
            } else {
                urls = ClassLoader.getSystemResources(fileName);
            }
            if (urls != null) {
                while (urls.hasMoreElements()) {
                    java.net.URL resourceURL = urls.nextElement();
                    loadResource(extensionClasses, classLoader, resourceURL);
                }
            }
        } catch (Throwable t) {
            logger.error("Exception occurred when loading extension class (interface: " +
                    type + ", description file: " + fileName + ").", t);
        }
    }
```
和上面所说一样,根据名称获取资源文件,然后调用 ``loadResource`` 加载,进入该方法:
```
private void loadResource(Map<String, Class<?>> extensionClasses, ClassLoader classLoader, java.net.URL resourceURL) {
        try {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(resourceURL.openStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    final int ci = line.indexOf('#');
                    if (ci >= 0) {
                        line = line.substring(0, ci);
                    }
                    line = line.trim();
                    if (line.length() > 0) {
                        try {
                            String name = null;
                            int i = line.indexOf('=');
                            if (i > 0) {
                                name = line.substring(0, i).trim();
                                line = line.substring(i + 1).trim();
                            }
                            if (line.length() > 0) {
                                loadClass(extensionClasses, resourceURL, Class.forName(line, true, classLoader), name);
                            }
                        } catch (Throwable t) {
                            IllegalStateException e = new IllegalStateException("Failed to load extension class (interface: " + type + ", class line: " + line + ") in " + resourceURL + ", cause: " + t.getMessage(), t);
                            exceptions.put(line, e);
                        }
                    }
                }
            }
        } catch (Throwable t) {
            logger.error("Exception occurred when loading extension class (interface: " +
                    type + ", class file: " + resourceURL + ") in " + resourceURL, t);
        }
    }
```
上面代码获取到文件流后,然后读取解析得到key、value值,继续调用 ``loadClass`` 方法,断点进入:  
```
 private void loadClass(Map<String, Class<?>> extensionClasses, java.net.URL resourceURL, Class<?> clazz, String name) throws NoSuchMethodException {
        if (!type.isAssignableFrom(clazz)) {
            throw new IllegalStateException("Error occurred when loading extension class (interface: " +
                    type + ", class line: " + clazz.getName() + "), class "
                    + clazz.getName() + " is not subtype of interface.");
        }
        // 判断类上是否带Adaptive注解,如果带的话,把clazz赋值给cachedAdaptiveClass
        if (clazz.isAnnotationPresent(Adaptive.class)) {
            cacheAdaptiveClass(clazz);
        } else if (isWrapperClass(clazz)) {
            // cache wrapper class
            cacheWrapperClass(clazz);
        } else {
            clazz.getConstructor();
            if (StringUtils.isEmpty(name)) {
                name = findAnnotationName(clazz);
                if (name.length() == 0) {
                    throw new IllegalStateException("No such extension name for the class " + clazz.getName() + " in the config " + resourceURL);
                }
            }

            String[] names = NAME_SEPARATOR.split(name);
            if (ArrayUtils.isNotEmpty(names)) {
                // 如果类带有Activate注解,则缓存
                cacheActivateClass(clazz, names[0]);
                for (String n : names) {
                    cacheName(clazz, n);
                    // 保存扩展类
                    saveInExtensionClass(extensionClasses, clazz, n);
                }
            }
        }
    }
```
到这里扩展类已经加载完了,并且保存,回到 ``org.apache.dubbo.common.extension.ExtensionLoader#getAdaptiveExtensionClass``方法中,调用完 ``getExtensionClasses`` 后，会判断 ``cachedAdaptiveClass`` 是否为空,如果不为空直接返回,也就是如果类上有 ``Adaptive``注解,此时会直接返回,注意结合 ``org.apache.dubbo.common.extension.ExtensionLoader#loadClass`` 方法中的判断分析,否则继续执行调用 ``createAdaptiveExtensionClass`` ,但是此时 ``cachedAdaptiveClass`` 是不为空的,所以直接返回.为什么不为空呢,由于 ``ExtensionFactory`` 的实现类 ``org.apache.dubbo.common.extension.factory.AdaptiveExtensionFactory`` 加上了 ``Adaptive`` 注解,在 ``org.apache.dubbo.common.extension.ExtensionLoader#loadClass`` 方法中,初始化了 ``cachedAdaptiveClass`` ,dubbo中的类上被 ``Adaptive`` 修饰的非常少,仅有两个: ``AdaptiveCompiler`` 、``AdaptiveExtensionFactory``.  
回到 ``org.apache.dubbo.common.extension.ExtensionLoader#createAdaptiveExtension`` 方法中, ``getAdaptiveExtensionClass`` 获取到扩展类后,通过反射创建对象,然后再调用 ``injectExtension`` ,断点进入:  
```
private T injectExtension(T instance) {
        // 若objectFactory为null,直接返回instance
        if (objectFactory == null) {
            return instance;
        }
        try {
            for (Method method : instance.getClass().getMethods()) {
                if (!isSetter(method)) {
                    continue;
                }
                /**
                 * Check {@link DisableInject} to see if we need auto injection for this property
                 */
                if (method.getAnnotation(DisableInject.class) != null) {
                    continue;
                }
                Class<?> pt = method.getParameterTypes()[0];
                if (ReflectUtils.isPrimitives(pt)) {
                    continue;
                }
                try {
                    String property = getSetterProperty(method);
                    Object object = objectFactory.getExtension(pt, property);
                    if (object != null) {
                        method.invoke(instance, object);
                    }
                } catch (Exception e) {
                    logger.error("Failed to inject via method " + method.getName()
                            + " of interface " + type.getName() + ": " + e.getMessage(), e);
                }
            }
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
        }
        return instance;
    }
```
首先判断 objectFactory 是否为空，为空则直接返回，前面分析的 ExtensionLoader 构造方法的时若扩展点类型是 ExtensionFactory ,则 objectFactory 为null，否则为 objectFactory 的自适应扩展,如果 objectFactory 不为空,则遍历所有的 ``setter`` 方法，如果方法上有 ``@DisableInject`` 则直接跳过，否则通过 objectFactory 获取对应的属性,不为空则调用 ``setter`` 方法，如果为 SPI 扩展点注入属性值.  
回到 ``org.apache.dubbo.common.extension.ExtensionLoader#getExtensionLoader`` 方法中, ``ExtensionLoader`` 实例已创建完成,并放入
 ``EXTENSION_LOADERS``  中,key是 ``interface org.apache.dubbo.demo.provider.Robot.class`` ,value是 ``ExtensionLoader`` 对象.  

#### ExtensionLoader#getExtension实现
回到 ``org.apache.dubbo.demo.provider.Test#main`` 中,即 ``ExtensionLoader`` 对象已经创建成功,下一步获取扩展对象:  
```
Robot optimusPrime = extensionLoader.getExtension("optimusPrime");
```
断点进入 ``org.apache.dubbo.common.extension.ExtensionLoader#getExtension`` 中:  
```
public T getExtension(String name) {
        // 若扩展名称为空,则抛出异常
        if (StringUtils.isEmpty(name)) {
            throw new IllegalArgumentException("Extension name == null");
        }
        // 若扩展名为true,返回默认扩展对象
        if ("true".equals(name)) {
            return getDefaultExtension();
        }
        // 获取Holder对象,如果从缓存获取为空,则重新创建
        final Holder<Object> holder = getOrCreateHolder(name);
        Object instance = holder.get();
        if (instance == null) {
            synchronized (holder) {
                instance = holder.get();
                if (instance == null) {
                    instance = createExtension(name);
                    holder.set(instance);
                }
            }
        }
        return (T) instance;
    }
```
上面代码主要看 ``org.apache.dubbo.common.extension.ExtensionLoader#createExtension`` 方法,断点进入:  
```
private T createExtension(String name) {
        Class<?> clazz = getExtensionClasses().get(name);
        if (clazz == null) {
            throw findException(name);
        }
        try {
            T instance = (T) EXTENSION_INSTANCES.get(clazz);
            if (instance == null) {
                EXTENSION_INSTANCES.putIfAbsent(clazz, clazz.newInstance());
                instance = (T) EXTENSION_INSTANCES.get(clazz);
            }
            // 依赖注入属性
            injectExtension(instance);
            Set<Class<?>> wrapperClasses = cachedWrapperClasses;
            // Wrapper包装
            if (CollectionUtils.isNotEmpty(wrapperClasses)) {
                for (Class<?> wrapperClass : wrapperClasses) {
                    instance = injectExtension((T) wrapperClass.getConstructor(type).newInstance(instance));
                }
            }
            return instance;
        } catch (Throwable t) {
            throw new IllegalStateException("Extension instance (name: " + name + ", class: " +
                    type + ") couldn't be instantiated: " + t.getMessage(), t);
        }
    }
```
明显继续进入 ``org.apache.dubbo.common.extension.ExtensionLoader#getExtensionClasses`` 方法:
```
private Map<String, Class<?>> getExtensionClasses() {
        Map<String, Class<?>> classes = cachedClasses.get();
        if (classes == null) {
            synchronized (cachedClasses) {
                classes = cachedClasses.get();
                if (classes == null) {
                    classes = loadExtensionClasses();
                    cachedClasses.set(classes);
                }
            }
        }
        return classes;
    }
```
双重检查判断,继续断点进入 ``org.apache.dubbo.common.extension.ExtensionLoader#loadExtensionClasses`` :
```
private Map<String, Class<?>> loadExtensionClasses() {
        cacheDefaultExtensionName();

        Map<String, Class<?>> extensionClasses = new HashMap<>();
        loadDirectory(extensionClasses, DUBBO_INTERNAL_DIRECTORY, type.getName());
        loadDirectory(extensionClasses, DUBBO_INTERNAL_DIRECTORY, type.getName().replace("org.apache", "com.alibaba"));
        loadDirectory(extensionClasses, DUBBO_DIRECTORY, type.getName());
        loadDirectory(extensionClasses, DUBBO_DIRECTORY, type.getName().replace("org.apache", "com.alibaba"));
        loadDirectory(extensionClasses, SERVICES_DIRECTORY, type.getName());
        loadDirectory(extensionClasses, SERVICES_DIRECTORY, type.getName().replace("org.apache", "com.alibaba"));
        return extensionClasses;
    }
```
这段代码是不是似曾相识,不错,就是上面创建 ``ExtensionLoader`` 时加载自适应扩展类时调用的方法,思路和上面的一样,就不再次分析了,解析完得到
的 Map 里存放的是:
```
optimusPrime -> {Class@1527} "class org.apache.dubbo.demo.provider.OptimusPrime"
bumblebee -> {Class@1569} "class org.apache.dubbo.demo.provider.Bumblebee"
```
回到 ``org.apache.dubbo.common.extension.ExtensionLoader#createExtension``方法内,此时根据 ``optimusPrime`` 就可以从 Map 中获取到 ``org.apache.dubbo.demo.provider.OptimusPrime.class``,判断 ``EXTENSION_INSTANCES`` 中是否有缓存,没有的话会根据反射创建该类对象,并放入到 ``EXTENSION_INSTANCES`` ,然后调用方法``org.apache.dubbo.common.extension.ExtensionLoader#injectExtension``,依赖注入属性,这个不作分析,与上文一致.至此对象 ``OptimusPrime`` 已生成了,然后返回到 ``Test`` 类测试方法中,可调用具体的方法了.  
通过``ExtensionLoader#getExtension``获取扩展点的实现,并不能体现自适应特性,和java SPI 并没有多大的差别,下面介绍``ExtensionLoader#getAdaptiveExtension`` 的实现.

#### ExtensionLoader#getAdaptiveExtension的实现
下面的分析需要注册中心 ``zookeeper`` ,关于安装和配置就不多分析.首先在 ``org.apache.dubbo.config.ServiceConfig#protocol`` 处打上断点:
```
private static final Protocol protocol = ExtensionLoader.getExtensionLoader(Protocol.class).getAdaptiveExtension();
```
在加载类 ``ServiceConfig`` 时,会先初始化静态变量 ``protocol`` , 而此时会获取自适应扩展类.到模块 ``demo-dubbo --》 dubbo-demo-api --》 dubbo-demo-api-provider`` 中运行 ``Application`` 类的main方法:
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
从断点进入,关于 ``ExtensionLoader#getExtensionLoader`` 的实现上文已经分析,这里不多作分析,断点直接进入 ``org.apache.dubbo.common.extension.ExtensionLoader#getAdaptiveExtensionClass`` 方法内: 
```
private Class<?> getAdaptiveExtensionClass() {
        getExtensionClasses();
        if (cachedAdaptiveClass != null) {
            return cachedAdaptiveClass;
        }
        return cachedAdaptiveClass = createAdaptiveExtensionClass();
    }
```
由上文分析可知,由于 ``Protocol`` 的实现类上都没有注解 ``Adaptive`` ,所以 ``cachedAdaptiveClass`` 为空,此时会调用方法 ``org.apache.dubbo.common.extension.ExtensionLoader#createAdaptiveExtensionClass`` ,断点进入: 
```
 private Class<?> createAdaptiveExtensionClass() {
        // 获取扩展类字符串
        String code = new AdaptiveClassCodeGenerator(type, cachedDefaultName).generate();
        ClassLoader classLoader = findClassLoader();
        org.apache.dubbo.common.compiler.Compiler compiler = ExtensionLoader.getExtensionLoader(org.apache.dubbo.common.compiler.Compiler.class).getAdaptiveExtension();
        return compiler.compile(code, classLoader);
    }
```
断点进入 ``org.apache.dubbo.common.extension.AdaptiveClassCodeGenerator#generate``  :
```
public String generate() {
        // no need to generate adaptive class since there's no adaptive method found.
        // type中至少一个方法被注解Adaptive修饰
        if (!hasAdaptiveMethod()) {
            throw new IllegalStateException("No adaptive method exist on extension " + type.getName() + ", refuse to create the adaptive class!");
        }

        StringBuilder code = new StringBuilder();
        // 拼接包名
        code.append(generatePackageInfo());
        // 拼接依赖包
        code.append(generateImports());
        // 拼接类名
        code.append(generateClassDeclaration());

        Method[] methods = type.getMethods();
        // 拼接方法
        for (Method method : methods) {
            code.append(generateMethod(method));
        }
        code.append("}");

        if (logger.isDebugEnabled()) {
            logger.debug(code.toString());
        }
        return code.toString();
    }
```
首先会校验 扩展类的接口中至少有一个方法被 ``Adaptive`` 注解修饰,具体代码不作分析了,看生成的类字符串信息:  
```
    package org.apache.dubbo.rpc;
    import org.apache.dubbo.common.extension.ExtensionLoader;
    public class Protocol$Adaptive implements org.apache.dubbo.rpc.Protocol {
        public void destroy() {
            throw new UnsupportedOperationException("The method public abstract void org.apache.dubbo.rpc.Protocol.destroy() of interface org.apache.dubbo.rpc.Protocol is not adaptive method!");
        }

        public int getDefaultPort() {
            throw new UnsupportedOperationException("The method public abstract int org.apache.dubbo.rpc.Protocol.getDefaultPort() of interface org.apache.dubbo.rpc.Protocol is not adaptive method!");
        }

        public org.apache.dubbo.rpc.Invoker refer(java.lang.Class arg0, org.apache.dubbo.common.URL arg1) throws org.apache.dubbo.rpc.RpcException {
            if (arg1 == null) {
                throw new IllegalArgumentException("url == null");
            }
            org.apache.dubbo.common.URL url = arg1;
            String extName = (url.getProtocol() == null ? "dubbo" : url.getProtocol());
            if (extName == null) {
                throw new IllegalStateException("Failed to get extension (org.apache.dubbo.rpc.Protocol) name from url (" + url.toString() + ") use keys([protocol])");
            }
            org.apache.dubbo.rpc.Protocol extension = (org.apache.dubbo.rpc.Protocol) ExtensionLoader.getExtensionLoader(org.apache.dubbo.rpc.Protocol.class).getExtension(extName);
            return extension.refer(arg0, arg1);
        }

        public org.apache.dubbo.rpc.Exporter export(org.apache.dubbo.rpc.Invoker arg0) throws org.apache.dubbo.rpc.RpcException {
            if (arg0 == null) {
                throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument == null");
            }
            if (arg0.getUrl() == null) {
                throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument getUrl() == null");
            }
            org.apache.dubbo.common.URL url = arg0.getUrl();
            String extName = (url.getProtocol() == null ? "dubbo" : url.getProtocol());
            if (extName == null) {
                throw new IllegalStateException("Failed to get extension (org.apache.dubbo.rpc.Protocol) name from url (" + url.toString() + ") use keys([protocol])");
            }
            org.apache.dubbo.rpc.Protocol extension = (org.apache.dubbo.rpc.Protocol) ExtensionLoader.getExtensionLoader(org.apache.dubbo.rpc.Protocol.class).getExtension(extName);
            return extension.export(arg0);
        }
    }
```
上面生成了类Protocol的子类 ``Protocol$Adaptive`` ,仔细观察发发现, ``export`` 、``refer`` 方法都被注解  ``Adaptive`` 修饰,生成的 ``Protocol$Adaptive`` 中这两个方法都有具体的实现,而 ``destroy`` 、``getDefaultPort`` 没有被注解修饰,生成的类中直接抛出 ``UnsupportedOperationException`` 异常.
回到  ``org.apache.dubbo.common.extension.ExtensionLoader#createAdaptiveExtensionClass`` 方法中,
由于 ``org.apache.dubbo.common.compiler.Compiler`` 的子类 ``org.apache.dubbo.common.compiler.support.AdaptiveCompiler`` 被 注解  ``Adaptive`` 修饰,所以变量 ``compiler`` 的值是 ``AdaptiveCompiler`` 实例,断点进入 ``org.apache.dubbo.common.compiler.support.AdaptiveCompiler#compile``: 
```
    public Class<?> compile(String code, ClassLoader classLoader) {
        Compiler compiler;
        // 获取ExtensionLoader
        ExtensionLoader<Compiler> loader = ExtensionLoader.getExtensionLoader(Compiler.class);
        String name = DEFAULT_COMPILER; // copy reference
        if (name != null && name.length() > 0) {
            compiler = loader.getExtension(name);
        } else {
            compiler = loader.getDefaultExtension();
        }
        return compiler.compile(code, classLoader);
    }
```
上面首先或获取 ``ExtensionLoader``, 根据 ``name`` 判断去加载具体的扩展实现,这里由于name为空,所以会调用 ``org.apache.dubbo.common.extension.ExtensionLoader#getDefaultExtension``,断点进入:  
```
 public T getDefaultExtension() {
        // 获取扩展类
        // 上一步已经获取到并且放入缓存,如下:
        // jdk -> {Class@1244} "class org.apache.dubbo.common.compiler.support.JdkCompiler"
        // javassist -> {Class@1245} "class org.apache.dubbo.common.compiler.support.JavassistCompiler"
        // 
        getExtensionClasses();
        if (StringUtils.isBlank(cachedDefaultName) || "true".equals(cachedDefaultName)) {
            return null;
        }
        // 默认获取 javassist
        return getExtension(cachedDefaultName);
    }
```
``org.apache.dubbo.common.extension.ExtensionLoader#getExtension`` 的具体实现不作分析,上文已经分析过,经过该方法后,可以得到
``org.apache.dubbo.common.compiler.support.JavassistCompiler`` 实例.  
然后回到  ``org.apache.dubbo.common.compiler.support.AdaptiveCompiler#compile`` 方法内,执行 ``org.apache.dubbo.common.compiler.support.AbstractCompiler#compile`` 方法,该方法是父类方法,做一些检验处理,然后再调用模版方法 ``doCompile`` 由子类  ``AdaptiveCompiler#doCompile`` 去处理,底层由 ``Javassist`` 生成类 ``Protocol$Adaptive``,到此自适应扩展类的生成已分析完毕.但是生成完如何使用呢?  
#### 自适应扩展按需加载
回到``org.apache.dubbo.config.ServiceConfig``中,在此处打上断点:  
```
Exporter<?> exporter = protocol.export(wrapperInvoker);
```
wrapperInvoker对象包装着invoker,具体可以看截图:  
<center> ![http://ww1.sinaimg.cn/thumbnail/ed2b6246ly1g72g7qib07j224w0se49f.jpg](http://ww1.sinaimg.cn/thumbnail/ed2b6246ly1g72g7qib07j224w0se49f.jpg)</center>
我们主要关注URL对象里的 ``string`` :
```
registry://127.0.0.1:2181/org.apache.dubbo.registry.RegistryService?application=dubbo-demo-api-provider&dubbo=2.0.2&export=dubbo%3A%2F%2F10.200.190.156%3A20880%2Forg.apache.dubbo.demo.DemoService%3Fanyhost%3Dtrue%26application%3Ddubbo-demo-api-provider%26bind.ip%3D10.200.190.156%26bind.port%3D20880%26deprecated%3Dfalse%26dubbo%3D2.0.2%26dynamic%3Dtrue%26generic%3Dfalse%26interface%3Dorg.apache.dubbo.demo.DemoService%26methods%3DsayHello%26pid%3D21663%26release%3D%26side%3Dprovider%26timestamp%3D1568697592181&pid=21663&registry=zookeeper&timestamp=1568697592172
```
很明显使用的协议: ``registry``,回到生成的自适应扩展类 ``Protocol$Adaptive`` 中的 ``export`` 方法:
```
public org.apache.dubbo.rpc.Exporter export(org.apache.dubbo.rpc.Invoker arg0) throws org.apache.dubbo.rpc.RpcException {
            if (arg0 == null) {
                throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument == null");
            }
            if (arg0.getUrl() == null) {
                throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument getUrl() == null");
            }
            org.apache.dubbo.common.URL url = arg0.getUrl();
            String extName = (url.getProtocol() == null ? "dubbo" : url.getProtocol());
            if (extName == null) {
                throw new IllegalStateException("Failed to get extension (org.apache.dubbo.rpc.Protocol) name from url (" + url.toString() + ") use keys([protocol])");
            }
            org.apache.dubbo.rpc.Protocol extension = (org.apache.dubbo.rpc.Protocol) ExtensionLoader.getExtensionLoader(org.apache.dubbo.rpc.Protocol.class).getExtension(extName);
            return extension.export(arg0);
        }
```
首先会判断传入参数是否为空,然后再判断 ``org.apache.dubbo.common.URL`` 是否为空, 然后获取协议, 所以这里``extName`` 为 ``registry``,后面就是根据  ``extName`` 获取具体的自适应扩展类,很明显 ``extension`` 会被 ``org.apache.dubbo.registry.integration.RegistryProtocol`` 初始化.
#### 总结
DUBBO SPI解决了什么问题呢,官方文档给出了解释:  

* JDK 标准的 SPI 会一次性实例化扩展点所有实现，如果有扩展实现初始化很耗时，但如果没用上也加载，会很浪费资源
* 如果扩展点加载失败，连扩展点的名称都拿不到了。比如：JDK 标准的 ScriptEngine，通过 getName() 获取脚本类型的名称，但如果 RubyScriptEngine 因为所依赖的 jruby.jar 不存在，导致 RubyScriptEngine 类加载失败，这个失败原因被吃掉了，和 ruby 对应不起来，当用户执行 ruby 脚本时，会报不支持 ruby，而不是真正失败的原因
* 增加了对扩展点 IoC 和 AOP 的支持，一个扩展点可以直接 setter 注入其它扩展点

> 参考文章  

1. [http://dubbo.apache.org/zh-cn/docs/source_code_guide/dubbo-spi.html](http://dubbo.apache.org/zh-cn/docs/source_code_guide/dubbo-spi.html)  
2. [http://dubbo.apache.org/zh-cn/docs/source_code_guide/adaptive-extension.html](http://dubbo.apache.org/zh-cn/docs/source_code_guide/adaptive-extension.html)  
3. [http://dubbo.apache.org/zh-cn/docs/dev/SPI.html](http://dubbo.apache.org/zh-cn/docs/dev/SPI.html)  
4. [http://dubbo.apache.org/zh-cn/docs/source_code_guide/adaptive-extension.html](http://dubbo.apache.org/zh-cn/docs/source_code_guide/adaptive-extension.html)  
5. [https://cxis.me/2017/02/18/Dubbo%E4%B8%ADSPI%E6%89%A9%E5%B1%95%E6%9C%BA%E5%88%B6%E8%AF%A6%E8%A7%A3/](https://cxis.me/2017/02/18/Dubbo%E4%B8%ADSPI%E6%89%A9%E5%B1%95%E6%9C%BA%E5%88%B6%E8%AF%A6%E8%A7%A3/)  
6. [https://kexianjun.github.io/2019/08/19/spi/#more](https://kexianjun.github.io/2019/08/19/spi/#more)
