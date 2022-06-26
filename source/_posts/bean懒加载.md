---
title: bean懒加载
date: 2019-02-16 01:42:16
tags:
- java
- spring
- bean
- 懒加载
categories:
- spring   
copyright: true #版权声明开启        
---
```
Indicates whether or not this bean is to be lazily initialized.
If false, it will be instantiated on startup by bean factories
that perform eager initialization of singletons. The default is
"false".
```
bean如果配置lazy-init="true"时,则在容器初始化过程中不会执行依赖注入,而当使用时才会去初始化bean,真的是这样么?下面就是深入源码探究,会分析以下三种情况:
1. bean A没有引用任何其他bean,且配置成懒加载
2. bean A引用了bean B,且bean A配置成懒加载
3. bean A引用了bean B,bean A没有配置为懒加载,bean B配置为懒加载
首先代码入口还是``AbstractApplicationContext#refresh``方法,其中在``AbstractApplicationContext#finishBeanFactoryInitialization``方法中会执行``DefaultListableBeanFactory#preInstantiateSingletons``:
```
for (String beanName : beanNames) {
            RootBeanDefinition bd = getMergedLocalBeanDefinition(beanName);
            if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
                if (isFactoryBean(beanName)) {
                    final FactoryBean<?> factory = (FactoryBean<?>) getBean(FACTORY_BEAN_PREFIX + beanName);
                    boolean isEagerInit;
                    if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {
                        isEagerInit = AccessController.doPrivileged(new PrivilegedAction<Boolean>() {
                            @Override
                            public Boolean run() {
                                return ((SmartFactoryBean<?>) factory).isEagerInit();
                            }
                        }, getAccessControlContext());
                    }
                    else {
                        isEagerInit = (factory instanceof SmartFactoryBean &&
                                ((SmartFactoryBean<?>) factory).isEagerInit());
                    }
                    if (isEagerInit) {
                        getBean(beanName);
                    }
                }
                else {
                    getBean(beanName);
                }
            }
        }
```
关键代码是``!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()``,会判断bean是否为抽象类、单例、懒加载,如果不符合就不会执行if里的代码,其实第一、二中情况都不符合的,所以不会执行到if语句里的代码.关键是第三种情况,分析思路之前[这篇](https://mp.weixin.qq.com/s/gduv_fAgB4-T13f6vsxkNw)(https://mp.weixin.qq.com/s/gduv_fAgB4-T13f6vsxkNw)分析是一样的,也就是在创建bean A的时候,在实例化其属性时,会创建bean B,有兴趣的朋友可以打断点调试,以下总结:
1. bean配置lazy-init="true"时,在容器初始化时不会创建该bean
2. 若一为单例且非懒加载的bean A引用了懒加载bean B时,在bean A被创建时,会创建bean B
3. 非单例或为抽象类或配置lazy-init="true"的bean,都不会在容器初始化时创建bean
