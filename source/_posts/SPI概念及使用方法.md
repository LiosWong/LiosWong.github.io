---
title: SPI概念及使用方法
date: 2019-02-16 01:43:07
tags:
- java
- SPI
categories:
- java   
copyright: true #版权声明开启     
---
### 简介
SPI全称Service Provider Interfaces,用于发现接口的实现。在jdbc、日志、dubbo的设计中都使用SPI用于服务的发现。简单的以jdbc为例:
![https://note.youdao.com/yws/api/personal/file/WEBbb7de4288a145ced6178308fe32d133b?method=download&shareKey=228a0e1b38725147810291fd9e72ba5a](https://note.youdao.com/yws/api/personal/file/WEBbb7de4288a145ced6178308fe32d133b?method=download&shareKey=228a0e1b38725147810291fd9e72ba5a)
jdbc Driver实现了java.sql.Driver接口，实现具体的功能,也就是Java SQL framework定义了用于数据库连接接口规范,不同的数据库厂商要想使用Java连接数据库必须实现该接口才可以，当厂商实现后，如何使用呢？也就是上图中的在``META-INF/services/``下,配置以接口``java.sql.Driver``为名称的文件，文件里加上具体的实现``com.mysql.jdbc.Driver``即可,在程序中注册注册驱动即可使用,如在使用jdbc时:
```
// Register JDBC driver
Class.forName("com.mysql.jdbc.Driver");
```
加载该jdbc驱动时,会执行静态块,并使用SPI机制在``java.sql.DriverManager``中加载``java.sql.Driver``的实现类:
```
// Register ourselves with the DriverManager
static {
    try {
        java.sql.DriverManager.registerDriver(new Driver());
    } catch (SQLException E) {
        throw new RuntimeException("Can't register driver!");
    }
}
static {
    loadInitialDrivers();
    println("JDBC DriverManager initialized");
}
private static void loadInitialDrivers() {
    String drivers;
    try {
        drivers = AccessController.doPrivileged(new PrivilegedAction<String>() {
            public String run() {
                return System.getProperty("jdbc.drivers");
            }
        });
    } catch (Exception ex) {
        drivers = null;
    }
    AccessController.doPrivileged(new PrivilegedAction<Void>() {
        public Void run() {
            try{
                while(driversIterator.hasNext()) {
                    driversIterator.next();
                }
            } catch(Throwable t) {
            // Do nothing
            }
            return null;
        }
    });

    println("DriverManager.initialize: jdbc.drivers = " + drivers);
    ...
}
```
### 项目中使用
在项目中我们会对外提供接口,为了在controller内内减少接口数量,使用SPI机制去实现相应的功能。
##### 首先定义接口
```
/**
 * @author wenchao.wang
 * @description
 * @date 2018/1/20 下午10:53
 */
public interface BaseApplication {
}
```
##### 接口实现
```
@Component
public class OpenOrderApplication implements BaseApplication {

    @MethodMapping("com.lios.test1")
    public ApiResponse filter(OpenApiJsonObject openApiJsonObject, String appId) {
        return null;
    }
    @MethodMapping("com.lios.test2")
    @CheckField(value = CheckEnum.JSON_OBJECT)
    public ApiResponse<DataVO> orderPush(OpenApiJsonObject openApiJsonObject, String appId) {
        return null;
    }

    @MethodMapping("com.lios.test3")
    public ApiResponse<DataVO> orderfeedback(OpenApiJsonObject openApiJsonObject, String appId) {
      return null;
    }

}
```
##### 使用SPI机制获取接口实现,并把注解值与方法绑定注册
```
public class MappingFactory {
private static ConcurrentHashMap<String, MethodApplication> methodMappings = new ConcurrentHashMap<String, MethodApplication>();
private volatile static boolean init = false;
private MappingFactory() {
}
private static void initHandlerMethod() {
    ServiceLoader<BaseApplication> applications = ServiceLoader.load(BaseApplication.class);
    for (BaseApplication application : applications) {
        Method[] methods = application.getClass().getDeclaredMethods();
        for (Method method : methods) {
            MethodMapping methodMapping = method.getAnnotation(MethodMapping.class);
            if (methodMapping != null && methodMapping.value() != null) {

                String mapping = methodMapping.value();
                addMethodMapping(mapping, new MethodApplication(StringUtils.uncapitalize(application.getClass().getSimpleName()), method));
            }
        }
    }
}
private static void addMethodMapping(String mapping, MethodApplication methodApplication) {
    methodMappings.put(mapping, methodApplication);
}
public static MethodApplication getMethodMapping(String url) {
    if (!init) {
        initHandlerMethod();
        init = true;
    }
    return methodMappings.get(url);
 }
}
```
##### 文件配置
在META-INF/services中添加文件com.lios.base.application.BaseApplication,写入:
```
com.lios.api.application.OpenApplication
```

##### controller中调用

```
@RestController
public class OpenController {
    private static final Logger LOGGER = LoggerFactory.getLogger(OpenController.class);
    @Autowired
    private Map<String, BaseApplication> baseApplications;
    @RequestMapping(value = "/open/gateway/{method:.+}", method = RequestMethod.POST)
    @ResponseBody
    public OpenApiResponse dispatcher(@PathVariable String method, @RequestBody OpenApiJsonObject openApiJsonObject) {
        ...
        MethodApplication methodApplication = MappingFactory.getMethodMapping(method);
        if (methodApplication != null && baseApplications.get(methodApplication.getApplicationName()) != null) {
            try {
                return (OpenApiResponse) methodApplication.getMethod().invoke(baseApplications.get(methodApplication.getApplicationName()), openApiJsonObject, appId);
            } catch (Exception e) {
               LOGGER.error(e.getMessage(), e);
            }
        }
        ...
    }
}
```
