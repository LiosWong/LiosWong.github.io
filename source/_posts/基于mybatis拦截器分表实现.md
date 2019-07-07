---
title: 基于mybatis拦截器分表实现
date: 2019-02-16 11:43:43
tags:
- java
- spring
- mybatis
categories:
- spring   
copyright: true #版权声明开启        
top: 200
---
mybatis提供了拦截器插件用来处理被拦截的方法的某些逻辑.下面会通过创建8张表,当用户注册时,根据对手机号取余数数据入不同的库.
#### 建表
![https://note.youdao.com/yws/api/personal/file/WEBfa5f294403e547b8de8f75ed5754a294?method=download&shareKey=fdf0fdffda7b82a83c763977e2420bad](https://note.youdao.com/yws/api/personal/file/WEBfa5f294403e547b8de8f75ed5754a294?method=download&shareKey=fdf0fdffda7b82a83c763977e2420bad)
#### 引入插件 
```
<property name="plugins">
    <array>
        <bean id="sharingInterceptor" class="com.lios.base.sharetable.SharingInterceptor"/>
    </array>
</property>
```
#### 拦截器
具体代码:
```
/**
 * @author LiosWong
 * @description
 * @date 2018/7/31 下午7:05
 */
@Intercepts(@Signature(type = StatementHandler.class,method = "prepare",args = {Connection.class,Integer.class}))
public class SharingInterceptor implements Interceptor{
    Logger logger = LoggerFactory.getLogger(SharingInterceptor.class);
    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        StatementHandler statementHandler = (StatementHandler) invocation.getTarget();
        ReflectorFactory reflectorFactory = new DefaultReflectorFactory();
        MetaObject metaObject = MetaObject.forObject(statementHandler,SystemMetaObject.DEFAULT_OBJECT_FACTORY,SystemMetaObject.DEFAULT_OBJECT_WRAPPER_FACTORY,reflectorFactory);
        MappedStatement mappedStatement = (MappedStatement) metaObject.getValue("delegate.mappedStatement");
        String id = mappedStatement.getId();
        id = id.substring(0,id.lastIndexOf("."));
        Class cls = Class.forName(id);
        SegmentTable segmentTable = (SegmentTable) cls.getAnnotation(SegmentTable.class);
        if(segmentTable!=null){
            String sql = (String) metaObject.getValue("delegate.boundSql.sql");
            BoundSql boundSql = statementHandler.getBoundSql();
            String tableKey = StrategyFactory.createShareStrategy(segmentTable.shareType()).setSegmentTable(segmentTable).setBoundSql(boundSql).getRouteValue();
            metaObject.setValue("delegate.boundSql.sql",sql.replaceFirst(segmentTable.tableName(),segmentTable.tableName()+tableKey));
        }
        return invocation.proceed();
    }
    @Override
    public Object plugin(Object target) {
        if(target instanceof StatementHandler){
            return Plugin.wrap(target,this);
        }
        return target;
    }
    @Override
    public void setProperties(Properties properties) {

    }
}

@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
public @interface SegmentTable {
    /**
     * 表名称
     * @return
     */
    String tableName()  default "";


    /**
     * 分表策略
     * @return
     */
    ShareType shareType() default ShareType.MOD;


    /**
     * 分表数量
     * @return
     */
    int tableNum() default 0;

    /**
     * 分表数量
     * @return
     */
    String shareBy() default "";
}
@Repository
@DataSource(value = DynamicDataSourceGlobal.LOCAL)
@SegmentTable(tableName = "user",shareType = ShareType.MOD,tableNum = 8,shareBy = "mobile")
public class UserInfoDaoImpl extends AbstractBaseMapper<UserInfoEntity> implements UserInfoDao{
    @Override
    public UserInfoEntity selectById(Long id) {
        return this.getSqlSession().selectOne(this.getStatement(".selectById"),id);
    }
    @Override
    public UserInfoEntity selectByMobile(String mobile) {
        return this.getSqlSession().selectOne(this.getStatement(".selectByMobile"),mobile);
    }
    @Override
    public UserInfoEntity insert(UserInfoEntity userInfoEntity){
        this.getSqlSession().insert(this.getStatement(".insert"),userInfoEntity);
        return null;
    }
}
```
StrategyFactory根据不同分表策略处理相应的逻辑,拦截器里主要思路就是拦截需要处理的方法,然后对拦截参数、拦截结果集处理,然后重新构建sql语句并执行.

#### 数据录入
![https://note.youdao.com/yws/api/personal/file/WEB4410d0e711f9f67487e43c97e7ac3d15?method=download&shareKey=e8ad78d0c2b9049391037b13738a955e](https://note.youdao.com/yws/api/personal/file/WEB4410d0e711f9f67487e43c97e7ac3d15?method=download&shareKey=e8ad78d0c2b9049391037b13738a955e)
