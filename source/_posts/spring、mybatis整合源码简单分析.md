---
title: spring、mybatis整合源码简单分析
date: 2019-02-16 01:42:16
tags:
- java
- spring
- mybatis
categories:
- mybatis   
copyright: true #版权声明开启        
---
### 配置
```
<bean id="localDataSource" class="com.alibaba.druid.pool.DruidDataSource" init-method="init" destroy-method="close">
        <property name="url" value="jdbc:mysql://192.168.31.14:3366/lios?characterEncoding=utf8"/>
        <property name="username" value="root"/>
        <property name="password" value="123456"/>
        ...
    </bean>
    <!-- 创建SqlSessionFactory，同时指定数据源-->
    <bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
        <property name="dataSource" ref="localDataSource"/>
        <property name="configLocation" value="classpath:sqlmap-config.xml"/>
        <property name="mapperLocations">
            <list>
               <value>classpath*:com/lios/mybatis/mapper/*.xml</value>
            </list>
        </property>
    </bean>
    <bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
        <property name="basePackage" value="com.lios.mybatis.dao"/>
        <property name="sqlSessionFactoryBeanName" value="sqlSessionFactory"/>
    </bean>
```
``MapperScannerConfigurer``这个bean有什么作用呢,MapperScannerConfigurer实现了BeanDefinitionRegistryPostProcessor接口，该接口可以让我们实现自定义并注册bean，具体可以参考关于BeanDefinitionRegistryPostProcessor接口[使用的文章](https://mp.weixin.qq.com/s?__biz=MzIxNDE2MTE3MA==&mid=2247483817&idx=1&sn=fd2be09dfaada65270ccb143bc0e491a&chksm=97aa83d4a0dd0ac2cfa5981685998c7557b9c0d4318c7c612f7602da26aac20bdf139e8fab6c&token=260922015&lang=zh_CN#rd),无疑分析入口还是从``org.springframework.context.support.AbstractApplicationContext#refresh``方法开始.
### 分析
> ##### 扫描basePackages,封装MapperFactoryBean,注册到spring容器

在``AbstractApplicationContext``类的``refresh``方法里,会调用：
```
invokeBeanFactoryPostProcessors(beanFactory);
```
调用BeanFactory的后置处理器，向容器中注册自定义Bean,一直跟到``PostProcessorRegistrationDelegate``类的``invokeBeanFactoryPostProcessors``方法中这段代码:
```
// Finally, invoke all other BeanDefinitionRegistryPostProcessors until no further ones appear.
boolean reiterate = true;
while (reiterate) {
	reiterate = false;
	postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
	for (String ppName : postProcessorNames) {
		if (!processedBeans.contains(ppName)) {
		    //getBean方法会初始化MapperScannerConfigurer
			BeanDefinitionRegistryPostProcessor pp = beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class);
			registryPostProcessors.add(pp);
			processedBeans.add(ppName);
			// 调用MapperScannerConfigurer的postProcessBeanDefinitionRegistry方法
			pp.postProcessBeanDefinitionRegistry(registry);
			reiterate = true;
		}
	}
}
```
跟到MapperScannerConfigurer的postProcessBeanDefinitionRegistry方法中,关键代码:
```
...
scanner.scan(StringUtils.tokenizeToStringArray(this.basePackage, ConfigurableApplicationContext.CONFIG_LOCATION_DELIMITERS));
```
这段代码用于扫描MapperScannerConfigurer中配置的basePackage路径下的文件.继续根进``ClassPathBeanDefinitionScanner``类的``scan``方法:
```
// Register annotation config processors, if necessary.
if (this.includeAnnotationConfig) {
	AnnotationConfigUtils.registerAnnotationConfigProcessors(this.registry);
}
return (this.registry.getBeanDefinitionCount() - beanCountAtScanStart);
```
``doScan``方法会调用``ClassPathMapperScanner#doScan``类中的doScan方法:
```
// 调用父类doScan方法,扫描basePackage下的mapper的接口文件,封装成Set<BeanDefinitionHolder>
doScan(basePackages);
Set<BeanDefinitionHolder> beanDefinitions = super.doScan(basePackages);
if (beanDefinitions.isEmpty()) {
  logger.warn("No MyBatis mapper was found in '" + Arrays.toString(basePackages) + "' package. Please check your configuration.");
} else {
  processBeanDefinitions(beanDefinitions);
}
return beanDefinitions;
```
``processBeanDefinitions``方法很重要:
```
GenericBeanDefinition definition;
for (BeanDefinitionHolder holder : beanDefinitions) {
  definition = (GenericBeanDefinition) holder.getBeanDefinition();
  // the mapper interface is the original class of the bean
  // but, the actual class of the bean is MapperFactoryBean
  definition.getConstructorArgumentValues().addGenericArgumentValue(definition.getBeanClassName()); // issue #59
  // 上面的注释其实说的很清楚了,mapper接口实际的实体为MapperFactoryBean
  definition.setBeanClass(this.mapperFactoryBean.getClass());
  // 设置MapperFactoryBean属性addToConfig元素
  definition.getPropertyValues().add("addToConfig", this.addToConfig);
  ...
  // 设置MapperFactoryBean属性sqlSessionTemplate元素
  definition.getPropertyValues().add("sqlSessionTemplate", this.sqlSessionTemplate);
}
```
经过上面的流程，basePackages下的mapper接口已经注册到容器中.
##### 实例化MapperFactoryBean中SqlSessionFactory,解析xml配置文件
继续回到``AbstractApplicationContext``类中的``refresh``中,会在该方法中初始化所有单例且是懒加载的bean,如果在应用中注入使用mapper接口时:
```
@Autowired
UserInfoDao userInfoDao;
```
就会初始化该mapper实例，其实就是初始化``MapperFactoryBean``,spring会检查该bean的属性是否为对象,依次初始化,由于
MapperFactoryBean中的属性SqlSessionTemplate、addToConfig，由于SqlSessionTemplate已经在配置文件配置,继而又会去初始化SqlSessionTemplate的属性``org.mybatis.spring.SqlSessionFactoryBean``,因为SqlSessionFactoryBean实现了``InitializingBean``接口，所以在初始化时会调用其``afterPropertiesSet``方法:
```
@Override
public void afterPropertiesSet() throws Exception {
notNull(dataSource, "Property 'dataSource' is required");
notNull(sqlSessionFactoryBuilder, "Property 'sqlSessionFactoryBuilder' is required");
state((configuration == null && configLocation == null) || !(configuration != null && configLocation != null),
          "Property 'configuration' and 'configLocation' can not specified with together");
this.sqlSessionFactory = buildSqlSessionFactory();
}
```
``buildSqlSessionFactory``方法非常关键,用来解析mppaer xml文件,关键代码:
```
XMLMapperBuilder xmlMapperBuilder = new XMLMapperBuilder(mapperLocation.getInputStream(),
configuration, mapperLocation.toString(), configuration.getSqlFragments());
xmlMapperBuilder.parse();
```
这里不作具体分析。
> ##### 生成mapper接口动态代理类

当MapperFactoryBean中的属性初始化完后,则继续执行MapperFactoryBean的初始化流程,在``AbstractBeanFactory``类的``doGetBean``方法中：
```
bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
```
调用了``AbstractBeanFactory``类的getObjectForBeanInstance方法：
```
object = getObjectFromFactoryBean(factory, beanName, !synthetic);
```
因为MapperFactoryBean实现了FactoryBean接口，所以才可以向下执行代码,
继续调用了``FactoryBeanRegistrySupport``类的getObjectFromFactoryBean方法:
```
Object object = doGetObjectFromFactoryBean(factory, beanName);
```
继续调用``FactoryBeanRegistrySupport``类中的doGetObjectFromFactoryBean方法:
```
...
object = factory.getObject();
...
```
原来调用了FactoryBean的getObject方法,这时则断点执行到了
``MapperFactoryBean``的getObject方法中:
```
return getSqlSession().getMapper(this.mapperInterface);
```
继续执行到``org.apache.ibatis.session.Configuration``的getMapper方法：
```
final MapperProxyFactory<T> mapperProxyFactory = (MapperProxyFactory<T>) knownMappers.get(type);
if (mapperProxyFactory == null) {
  throw new BindingException("Type " + type + " is not known to the MapperRegistry.");
}
try {
  return mapperProxyFactory.newInstance(sqlSession);
} catch (Exception e) {
  throw new BindingException("Error getting mapper instance. Cause: " + e, e);
}
```
上面代码是不是很熟悉，原来为mapper 接口创建了代理类``MapperProxy<T>``,当调用mapper接口中具体的方法操作数据库时，其实执行的的是``MapperProxy<T>``中的invoke方法:
```
try {
  if (Object.class.equals(method.getDeclaringClass())) {
    return method.invoke(this, args);
  } else if (isDefaultMethod(method)) {
    return invokeDefaultMethod(proxy, method, args);
  }
} catch (Throwable t) {
  throw ExceptionUtil.unwrapThrowable(t);
}
final MapperMethod mapperMethod = cachedMapperMethod(method);
return mapperMethod.execute(sqlSession, args);
```
上面还有一个关键点就是，xml中解析的配置如何与spring容器中mapper bean相关联呢,其实通过``DaoSupport``类中的``checkDaoConfig``方法,在``DaoSupport``类的``afterPropertiesSet``方法中调用,具体看MapperFactoryBean中的checkDaoConfig实现:
```
@Override
  protected void checkDaoConfig() {
    super.checkDaoConfig();
    notNull(this.mapperInterface, "Property 'mapperInterface' is required");
    // mybatis中配置类
    Configuration configuration = getSqlSession().getConfiguration();
    if (this.addToConfig && !configuration.hasMapper(this.mapperInterface)) {
      try {
        // 添加mapper关联
        configuration.addMapper(this.mapperInterface);
      } catch (Exception e) {
        logger.error("Error while adding the mapper '" + this.mapperInterface + "' to configuration.", e);
        throw new IllegalArgumentException(e);
      } finally {
        ErrorContext.instance().reset();
      }
    }
  }
```
到此为止，已经分析完了mybatis与spring结合的源码简单说明，省略了大量的细节，以及mapper xml文件解析、sql执行流程没有分析，后续文章会做分析。由于作者水平有限，文章存在错误之处，肯请斧正，谢谢！
