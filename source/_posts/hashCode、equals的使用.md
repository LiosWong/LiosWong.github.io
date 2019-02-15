---
title: hashCode、equals的使用
date: 2019-02-16 01:41:08
tags:
- hashCode
- equals
- java
categories:
- java   
copyright: true #版权声明开启    
---
### 问题
这篇文章由之前的[并行执行任务]()发展而来,如何生成task,在之前的文章中,生成task方式如下:
```
Abstract Task: 
public abstract class BasicUserFilter implements Callable<UserFilterDto> {
private static final Log logger = LogFactory.getLog(BasicUserFilter.class);
@Autowired
UserService userService;
public Long companyId;
public Long userId;
@Override
public UserFilterDto call() throws Exception {
    try {
        //每个执行任务调用同一个方法,只是入参不同
        Response<Boolean> response = userService.filter(getUserId(), getCompanyId());
        if (response.isSuccess() && response.getResult()) {
            return new UserFilterDto().setCompanyId(getCompanyId()).setUserId(getUserId()).setFilterResultEnum(FilterResultEnum.TRUE);
        }
    } catch (Exception e) {
        logger.error(e.getMessage(), e);
    }
    return new UserFilterDto().setCompanyId(getCompanyId()).setUserId(getUserId()).setFilterResultEnum(FilterResultEnum.FALSE);
}
@PostConstruct
abstract void init();
// ... 篇幅关系,省略属性setter、getter方法
}
}

Task1:
public class Task1 extends BasicUserFilter{
    @Override
    public void init() {
        FilterConfigManager.register(CompanyAppIdEnum.GEI_NI_HUA.getCompanyId(),this);
    }
    @Override
    public UserFilterDto call() throws Exception {
        return super.call();
    }
}
```
上面生成任务类时，使用了策略模式,添加每一个任务都必须新增一个实体类,且实现BasicUserFilter或者重写自己的``call``方法,有木有比较好的方法解决这种繁琐的任务类构建呢。
### 方案
解决切入点，就是所有的任务类都执行了相同的逻辑，且调用了入参不同的方法而已，无疑使用代理模式去动态生成任务类,思路有了，代码实现也边的简单起来。下面使用java InvocationHandler创建动态代理类.
```
ProxyHandler：
/**
 * @author LiosWong
 * @description
 * @date 2018/10/27 上午1:10
 */
public class ProxyHandler<T> implements InvocationHandler, Serializable {
    private static final long serialVersionUID = -6424540398559729838L;
    private final ProxyInterface<T> proxyInterface;

    public ProxyHandler(ProxyInterface<T> proxyInterface) {
        this.proxyInterface = proxyInterface;
    }
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        // 根据方法名,执行不同逻辑
        if ("call".equals(method.getName())) {
            return proxyInterface.call();
        }
        return null;
    }
}
ProxyInterface：为了使代理模版通用,添加接口约束
/** 
 * @author LiosWong
 * @description 可扩展代理接入点
 * @date 2018/10/27 上午1:11
 */
public interface ProxyInterface<T> extends Callable<T> {

}
ProxyFactory：代理工厂
public class ProxyFactory<T> {
private final Class<T> mapperInterface;

public ProxyFactory(Class<T> mapperInterface) {
    this.mapperInterface = mapperInterface;
}
public Class<T> getMapperInterface() {
    return mapperInterface;
}
@SuppressWarnings("unchecked")
protected T newInstance(ProxyHandler<T> mapperProxy) {
    return (T) java.lang.reflect.Proxy.newProxyInstance(mapperInterface.getClassLoader(), new Class[]{mapperInterface}, mapperProxy);
}
public T newInstance(ProxyInterface proxyInterface) {
    final ProxyHandler<T> mapperProxy = new ProxyHandler<T>(proxyInterface);
    return newInstance(mapperProxy);
}
}
```
完成了上面的动态代理类构建，下面就是在业务代码中使用:
```
 ProxyFactory proxyFactory = new ProxyFactory<Callable>(Callable.class);
        List<Callable<UserFilterDto>> callableList = new ArrayList<>();
        List<UserFilterDto> filterDtosResult = new ArrayList<>();
        // 动态生成代理类
        list.forEach(p -> {
            Callable<UserFilterDto> callable = null;
            // 复用代理模版
            switch (concurrencyType) {
                case FILTER:
                    callable = (Callable<UserFilterDto>) proxyFactory.newInstance(new ProxyFilterCallable(xjUserService, userId, p.getCompanyId()));
                    break;
                case SATISFY:
                    callable = (Callable<UserFilterDto>) proxyFactory.newInstance(new ProxySatisfyCallable(companyUserGroupService, userId, p.getCompanyId()));
                    break;
                default:
                    break;
            }
            callableList.add(callable);
        });
```
ProxyFilterCallable:
```
public class ProxyFilterCallable<T> implements ProxyInterface<T> {
    private static final Log logger = LogFactory.getLog(ProxyFilterCallable.class);
    private UserService userService;
    private Long userId;
    private Long companyId;

    public ProxyFilterCallable(XjUserService xjUserService, Long userId, Long companyId) {
        this.xjUserService = xjUserService;
        this.userId = userId;
        this.companyId = companyId;
    }
    @Override
    public T call() throws Exception {
        try {
            Response<Boolean> response = userService.filter(getUserId(), getCompanyId());
            if (response.isSuccess() && response.getResult()) {
                return (T) new UserFilterDto().setCompanyId(getCompanyId()).setUserId(getUserId()).setFilterResultEnum(FilterResultEnum.TRUE);
            }
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
        }
        return (T) new UserFilterDto().setCompanyId(getCompanyId()).setUserId(getUserId()).setFilterResultEnum(FilterResultEnum.FALSE);
    }
    // ...
}
```
ProxySatisfyCallable：
```
public class ProxySatisfyCallable<T> implements ProxyInterface<T> {
    private static final Log logger = LogFactory.getLog(ProxyFilterCallable.class);
    private CompanyUserGroupService companyUserGroupService;
    private Long userId;
    private Long companyId;

    public ProxySatisfyCallable(CompanyUserGroupService companyUserGroupService, Long userId, Long companyId) {
        this.companyUserGroupService = companyUserGroupService;
        this.userId = userId;
        this.companyId = companyId;
    }

    @Override
    public T call() throws Exception {
        try {
            XjFilterUserResultVo xjFilterUserResultVo = companyUserGroupService.checkUserInfoIsSatisfyCompany(getUserId(), getCompanyId());
            if (Objects.nonNull(xjFilterUserResultVo) && xjFilterUserResultVo.getResult()) {
                return (T) new UserFilterDto().setCompanyId(getCompanyId()).setUserId(getUserId()).setFilterResultEnum(FilterResultEnum.TRUE);
            }
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
        }
        return (T) new UserFilterDto().setCompanyId(getCompanyId()).setUserId(getUserId()).setFilterResultEnum(FilterResultEnum.FALSE);
    }
    // ...
}

```
