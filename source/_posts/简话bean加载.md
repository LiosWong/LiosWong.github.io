---
title: 简话bean加载
date: 2019-02-16 01:42:16
tags:
- java
- spring
- bean
categories:
- spring   
copyright: true #版权声明开启        
---
首先看示例代码:
```
<!--no-lazy-init   scope=singleton-->
<bean class="com.lios.service.test.LiosTestA" id="liosTestA"/>
<bean class="com.lios.service.test.LiosTestB" id="liosTestB"/>
<bean class="com.lios.service.test.LiosServiceServiceImpl" id="liosServiceService"/>

ClassPathXmlApplicationContext resource = new ClassPathXmlApplicationContext("app.xml");
BeanFactory beanFactory = resource.getBeanFactory();
LiosServiceServiceImpl liosServiceService = (LiosServiceServiceImpl) beanFactory.getBean("liosServiceService");
liosServiceService.t();
```
LiosServiceServiceImpl:
```
@Service
public class LiosServiceServiceImpl {
    private int i = 1;
    @Autowired
    LiosTestA liosTestA;
    public void t(){
        try {
            liosTestA.testA();
        } catch (Exception e) {
            e.printStackTrace();
        }
        System.out.println("===========>");
    }
}
```
LiosTestA:
```
@Service
public class LiosTestA {
    @Autowired
    LiosTestB liosTestB;
    public void testA(){
        liosTestB.testB();
    }
}
```
以上代码就是LiosServiceServiceImpl类中引用了LiosTestA,LiosTestA类中引用了LiosTestB,今天的问题是LiosServiceServiceImpl如何引用LiosTestA,LiosTestA如何引用LiosTestB?
看过源码的同学肯定知道,``org.springframework.context.support.AbstractApplicationContext#refresh``是spring解析xml、初始化bean的入口,该方法里会调用:
```
// Instantiate all remaining (non-lazy-init) singletons.
finishBeanFactoryInitialization(beanFactory);
```
这个方法会实例化所有的non-lazy-init单例的bean,毫无疑问,这个方法是分析问题的入口,紧跟进去:
```
// Instantiate all remaining (non-lazy-init) singletons.
beanFactory.preInstantiateSingletons();
```
再跟进去,调用了``org.springframework.beans.factory.support.DefaultListableBeanFactory#preInstantiateSingletons``方法,再跟进去``getBean(beanName);``方法,调用了
``org.springframework.beans.factory.support.AbstractBeanFactory#getBean(java.lang.String)``方法:
```
@Override
public Object getBean(String name) throws BeansException {
    return doGetBean(name, null, null, false);
}
```
进入doGetBean方法中,绕了那么多,这个方法才是会真正干事:
```
//获取beanName
final String beanName = transformedBeanName(name);
//从缓存里获取bean,第一次时毫无疑问,sharedInstance为null
Object sharedInstance = getSingleton(beanName);
//获取RootBeanDefinition,其实用BeanDefinition初始化
final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
创建bean
createBean(beanName, mbd, args)
```
下面分析``org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBean(java.lang.Class<T>)``方法,明显这是把具体实现委托给子类实现了,继续跟:``org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBean(java.lang.String, org.springframework.beans.factory.support.RootBeanDefinition, java.lang.Object[])``,该方法里有一段这样的代码:
```
instanceWrapper = createBeanInstance(beanName, mbd, args);
```
继续跟:
```
// Make sure bean class is actually resolved at this point.
Class<?> beanClass = resolveBeanClass(mbd, beanName);
//.... 后面省略
```
继续跟``resolveBeanClass()``方法,其实该方法里利用反射创建了bean实例,createBeanInstance()方法主要是返回BeanWrapper对象,该对象用bean实例初始化,getWrappedInstance()即可返回bean对象:
```
/**
 * Return the bean instance wrapped by this object, if any.
 * @return the bean instance, or {@code null} if none set
 */
Object getWrappedInstance();
```
所以上面的LiosServiceServiceImpl、LiosTestA、LiosTestB都是通过resolveBeanClass()方法创建实例,但是里面的引用的属性如何创建呢,那回到``doCreateBean()``方法,继续看下面的代码:
```
// Initialize the bean instance.
Object exposedObject = bean;
try {
    //初始化bean属性的值
    populateBean(beanName, mbd, instanceWrapper);
    if (exposedObject != null) {
        exposedObject = initializeBean(beanName, exposedObject, mbd);
    }
}
```
首先分析``populateBean(beanName, mbd, instanceWrapper)``,为了直接点,直接看后置处理器BeanPostProcessor:
```
for (BeanPostProcessor bp : getBeanPostProcessors()) {
if (bp instanceof InstantiationAwareBeanPostProcessor) {
    InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
    pvs = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
    if (pvs == null) {
        return;
    }
  }
}
```
再看InstantiationAwareBeanPostProcessor的实现类,``org.springframework.context.annotation.CommonAnnotationBeanPostProcessor#postProcessPropertyValues``:
```
InjectionMetadata metadata = findResourceMetadata(beanName, bean.getClass(), pvs);
metadata.inject(bean, beanName, pvs);
```
一直跟进去到``org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor.AutowiredFieldElement#inject``:
```
value = beanFactory.resolveDependency(desc, beanName, autowiredBeanNames, typeConverter);
```
再跟进去:
```
result = doResolveDependency(descriptor, beanName, autowiredBeanNames, typeConverter);
```
继续跟进去:
```
Map<String, Object> matchingBeans = findAutowireCandidates(beanName, type, descriptor);
```
doResolveDependency方法会根据属性的属性类型去获取引用,继续跟,可以看到``org.springframework.beans.factory.support.DefaultListableBeanFactory#findAutowireCandidates``方法里的这段代码:
```
result.put(candidateName, getBean(candidateName));
```
getBean(candidateName)这个不是调用``org.springframework.beans.factory.support.AbstractBeanFactory#getBean(java.lang.String)``么,没错,是的!  
回到``org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor.AutowiredFieldElement#inject``中:
```
if (value != null) {
ReflectionUtils.makeAccessible(field);
field.set(bean, value);
}
```
这段代码会设置bean中的属性的值,一个真正的bean已经完成了.
再回到``org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#doCreateBean``方法中,看这句代码:
```
initializeBean(beanName, exposedObject, mbd);
```
跟进后再进入``org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#invokeInitMethods``方法:
```
boolean isInitializingBean = (bean instanceof InitializingBean);
        if (isInitializingBean && (mbd == null || !mbd.isExternallyManagedInitMethod("afterPropertiesSet"))) {
            if (logger.isDebugEnabled()) {
                logger.debug("Invoking afterPropertiesSet() on bean with name '" + beanName + "'");
            }
            if (System.getSecurityManager() != null) {
                try {
                    AccessController.doPrivileged(new PrivilegedExceptionAction<Object>() {
                        @Override
                        public Object run() throws Exception {
                            ((InitializingBean) bean).afterPropertiesSet();
                            return null;
                        }
                    }, getAccessControlContext());
                }
                catch (PrivilegedActionException pae) {
                    throw pae.getException();
                }
            }
            else {
                ((InitializingBean) bean).afterPropertiesSet();
            }
        }
```
看到InitializingBean、afterPropertiesSet()是否会想起什么呢,如果一个bean实现了InitializingBean接口后,在bean被容器加载时,自动调用afterPropertiesSet()方法,现在明白是咋回事了吧.  
说了那么多,总结下LiosServiceServiceImpl类的加载过程,首先容器会加载LiosServiceServiceImpl或者LiosTestA或者LiosTestB,默认是没有明确顺序之分,如果按照先加载LiosTestA的话,会先创建LiosTestA实例,里面的属性LiosTestB值还是为空,然后设置其属性的值,其实就是调用getBean方法,完成LiosTestA的实例创建后,创建LiosServiceServiceImpl套路完全一样,其属性LiosTestA已经在缓存有了,直接获取即可.  
最后,bean的加载远远不止这么复杂,文中有错误之处,麻烦指正!
