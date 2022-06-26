---
title: interface注入及报错分析
date: 2019-02-16 01:42:16
tags:
- java
- spring
- bean
categories:
- spring   
copyright: true #版权声明开启        
---
![https://note.youdao.com/yws/api/personal/file/WEBfdaf58ac1dc8c2a883297003a4db402c?method=download&shareKey=fffbd764872b91bae807de4755fb5bc7](https://note.youdao.com/yws/api/personal/file/WEBfdaf58ac1dc8c2a883297003a4db402c?method=download&shareKey=fffbd764872b91bae807de4755fb5bc7)
### 一个小case
上面错误原因我想大家开发中都遇到过,大致错误原因是注入bean时，spring找到2个实例userServiceImplTest、userServiceImpl，无法确认到底使用哪个。问题出在这，原因是什么呢，在说明前，看下面的代码：
```
@RestController
public class OkController {
@Autowired
UserService userService;
@ResponseBody
@GetMapping(value = "/ok")
public String ok(){
    UserInfoEntity userInfoEntity = userService.selectByTel("lioswang");
}
//此时项目中UserService的实现类只有UserServiceImpl
@Service
public class UserServiceImpl implements UserService{
    @Override
    public UserInfoEntity selectByTel(String tel) {
        return  null;
    }
}
```
在OkController中为什么可以直接注入接口，当项目启动时，调用了UserServiceImpl类中的selectByTel方法,由于在OkController中引用了UserService，所以锁定在OkController初始化时Spring到底干了些什么，根据之前源码分析的经验，在``org.springframework.beans.factory.support.AbstractBeanFactory#doGetBean``方法中打上条件断点，首先看方法``org.springframework.beans.factory.support.AbstractBeanFactory#createBean``，调用了方法org.springframework.beans.factory.support.AbstractBeanFactory#createBean,继续跟进方法``org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#doCreateBean``,
再跟进去方法``org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#populateBean``,继续跟进去``org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor#postProcessPropertyValues``，在方法中找到OkController注入的元数据UserService,调用了``org.springframework.beans.factory.annotation.InjectionMetadata#inject``,跟进去``org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor.AutowiredFieldElement#inject``，继续跟``org.springframework.beans.factory.support.DefaultListableBeanFactory#resolveDependency``，其中代码片段：
```
//获取接口的依赖
result = doResolveDependency(descriptor, beanName, autowiredBeanNames, typeConverter);
```
调用了
``org.springframework.beans.factory.support.DefaultListableBeanFactory#doResolveDependency``,该方法的代码片段
```
Map<String, Object> matchingBeans = findAutowireCandidates(beanName, type, descriptor);
```
继续跟
``
org.springframework.beans.factory.support.DefaultListableBeanFactory#findAutowireCandidates``,其中获取UserService所有的实现类:
```
//获取到UserService的实现类
String[] candidateNames = BeanFactoryUtils.beanNamesForTypeIncludingAncestors(this, requiredType, true, descriptor.isEager());
//获取到实现类后，并初始化，保存在Map<String, Object>
result.put(candidateName, getBean(candidateName));
``` 
再看``org.springframework.beans.factory.support.DefaultListableBeanFactory#doResolveDependency``方法中代码片段：
```
Map<String, Object> matchingBeans = findAutowireCandidates(beanName, type, descriptor);
if (matchingBeans.isEmpty()) {
    if (descriptor.isRequired()) {
        raiseNoSuchBeanDefinitionException(type, "", descriptor);
    }
    return null;
}
//获取匹配到的bean数大于1时的逻辑处理
if (matchingBeans.size() > 1) {
    String primaryBeanName = determineAutowireCandidate(matchingBeans, descriptor);
    if (primaryBeanName == null) {
        throw new NoUniqueBeanDefinitionException(type, matchingBeans.keySet());
    }
    if (autowiredBeanNames != null) {
        autowiredBeanNames.add(primaryBeanName);
    }
    return matchingBeans.get(primaryBeanName);
}
// We have exactly one match.
Map.Entry<String, Object> entry = matchingBeans.entrySet().iterator().next();
if (autowiredBeanNames != null) {
    autowiredBeanNames.add(entry.getKey());
}
return entry.getValue();
}
```
由于目前项目中UserService的实现类只有UserServiceImpl，所以最终获取到的只有一个。
再回到``org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor.AutowiredFieldElement#inject``中，已经找到UserService的实现类，所以执行:
```
ReflectionUtils.makeAccessible(field);
field.set(bean, value);
```     
即把UserServiceImpl的实例设置到属性UserService中。
所以当再OkController中调用UserService的selectByTel方法，其实调用的是UserServiceImpl的selectByTel方法。
### 报错
上面分析那么多，其实就是为了说明我们注入接口时，为什么会调用实现类的方法。为了报错，很简单，再写一个类实现UserService接口即可，OkController中不需要修改，其实由上面的分析知道，报错的就是上面的这段代码：
```
if (matchingBeans.size() > 1) {
    String primaryBeanName = determineAutowireCandidate(matchingBeans, descriptor);
    if (primaryBeanName == null) {
        throw new NoUniqueBeanDefinitionException(type, matchingBeans.keySet());
    }
    if (autowiredBeanNames != null) {
        autowiredBeanNames.add(primaryBeanName);
    }
    return matchingBeans.get(primaryBeanName);
}
```
也就是在UserService的实现类中找到多个bean实例，这个明显是错误的，
### 错误解决
如何解决这个问题呢，很简单:
```
@Autowired
@Qualifier("userServiceImpl")
UserService userService;
```
或
```
@Resource(name = "userServiceImpl")
UserService userService;
```
因为在``org.springframework.beans.factory.support.DefaultListableBeanFactory#findAutowireCandidates``方法中的
```
for (String candidateName : candidateNames) {
    if (!isSelfReference(beanName, candidateName) && isAutowireCandidate(candidateName, descriptor)) {
        result.put(candidateName, getBean(candidateName));
    }
}
```
会根据注解过滤bean，所以加上上面的注解后会解决错误,具体代码就不分析了，感兴趣的同学可打断点调试。
### 思考拓展
```
@RestController
public class OkController {
@Autowired
Map<String,UserService> userServiceMap;
@ResponseBody
@GetMapping(value = "/ok")
public String ok(){
   ...
}
```
若OkController中代码修改如上，项目启动后，发现没有报错，而且userServiceMap中有两个key-value元素，无疑是UserServiceImpl、UserServiceImplTest,我想原因不难看出，``org.springframework.beans.factory.support.DefaultListableBeanFactory#findAutowireCandidates``返回了Map<String, Object>，其值和userServiceMap相同，不难看出spring功能非常强大。
