---
title: SpringMVC启动加载、请求分析
date: 2019-02-16 11:42:52
tags:
- java
- spring
- springmvc
categories:
- spring   
copyright: true #版权声明开启        
---
#### 简介
springmvc项目会在web.xml文件中配置servlet:
```
<servlet>
    <servlet-name>dispatcher</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <init-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>classpath:dispatcher-servlet.xml</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>
```
下面看下DispatcherServlet的继承关系:  
![https://note.youdao.com/yws/api/personal/file/WEBcbda6aa3e25fb29b50796b036cc5ebcf?method=download&shareKey=2cfc5655b93a037fea8311c54e4c6416](https://note.youdao.com/yws/api/personal/file/WEBcbda6aa3e25fb29b50796b036cc5ebcf?method=download&shareKey=2cfc5655b93a037fea8311c54e4c6416)  
DispatcherServlet其实是一个Servlet,用于初始化各个功能的实现类,比如异常处理、视图处理、请求映射等;且继承了FrameworkServlet类,FrameworkServlet是Spring的基础Servlet,提供集成一个基于JavaBean的整体解决方案的Spring上下文;FrameworkServlet又继承了HttpServletBean,HttpServletBean主要做一些初始化的工作,如将web.xml中的配置参数设置到Servlet中.  
再直观感受下DispatcherServlet上下文层次结构关系:  
![https://note.youdao.com/yws/api/personal/file/WEBa8f04859417bba9bd52131d2567d6b73?method=download&shareKey=c1c6ee425df9c89566c24d3546acacb7](https://note.youdao.com/yws/api/personal/file/WEBa8f04859417bba9bd52131d2567d6b73?method=download&shareKey=c1c6ee425df9c89566c24d3546acacb7)  
该图有助于下面分析启动、请求的分析理解,图片来自[https://docs.spring.io/spring/docs/current/spring-framework-reference/web.html#mvc](https://docs.spring.io/spring/docs/current/spring-framework-reference/web.html#mvc)
#### 启动源码分析
由于DispatcherServlet是一个Servlet,启动时初始化首先调用init方法,进入其父类的``org.springframework.web.servlet.HttpServletBean#init``方法中:
```
PropertyValues pvs = new ServletConfigPropertyValues(getServletConfig(), this.requiredProperties);
```
获取了配置文件dispatcher-servlet.xml,跟进``  initServletBean()``方法,此处用了委派方式,具体实现交给子类FrameworkServlet去实现,主要看方法里这段代码:
```
this.webApplicationContext = initWebApplicationContext();
initFrameworkServlet();
```
跟进第一段代码,由于第一次启动,wac为nul,再进入初始化方法代码,``org.springframework.web.servlet.FrameworkServlet#createWebApplicationContext(org.springframework.web.context.WebApplicationContext)``,再进入``org.springframework.web.servlet.FrameworkServlet#createWebApplicationContext(org.springframework.context.ApplicationContext)``方法:
```
Class<?> contextClass = getContextClass();
if (this.logger.isDebugEnabled()) {
    this.logger.debug("Servlet with name '" + getServletName() +
            "' will try to create custom WebApplicationContext context of class '" +
            contextClass.getName() + "'" + ", using parent context [" + parent + "]");
}
if (!ConfigurableWebApplicationContext.class.isAssignableFrom(contextClass)) {
    throw new ApplicationContextException(
            "Fatal initialization error in servlet with name '" + getServletName() +
            "': custom WebApplicationContext class [" + contextClass.getName() +
            "] is not of type ConfigurableWebApplicationContext");
}
ConfigurableWebApplicationContext wac =
        (ConfigurableWebApplicationContext) BeanUtils.instantiateClass(contextClass);
wac.setEnvironment(getEnvironment());
wac.setParent(parent);
wac.setConfigLocation(getContextConfigLocation());
configureAndRefreshWebApplicationContext(wac);
```
上面主要创建了ConfigurableWebApplicationContext对象,然后调用了configureAndRefreshWebApplicationContext方法用来做初始化工作,再进入到``org.springframework.web.servlet.FrameworkServlet#configureAndRefreshWebApplicationContext``方法:
```
if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
    // The application context id is still set to its original default value
    // -> assign a more useful id based on available information
    if (this.contextId != null) {
        wac.setId(this.contextId);
    }
    else {
        // Generate default id...
        wac.setId(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
                ObjectUtils.getDisplayString(getServletContext().getContextPath()) + "/" + getServletName());
    }
}
wac.setServletContext(getServletContext());
wac.setServletConfig(getServletConfig());
wac.setNamespace(getNamespace());
wac.addApplicationListener(new SourceFilteringListener(wac, new ContextRefreshListener()));
// The wac environment's #initPropertySources will be called in any case when the context
// is refreshed; do it eagerly here to ensure servlet property sources are in place for
// use in any post-processing or initialization that occurs below prior to #refresh
ConfigurableEnvironment env = wac.getEnvironment();
if (env instanceof ConfigurableWebEnvironment) {
    ((ConfigurableWebEnvironment) env).initPropertySources(getServletContext(), getServletConfig());
}
postProcessWebApplicationContext(wac);
applyInitializers(wac);
wac.refresh();
```
最后一句``wac.refresh()``代码,跟进去发现调用的是``org.springframework.context.support.AbstractApplicationContext#refresh``的方法,ConfigurableWebApplicationContext没有重写refresh方法,所以调用了父类的默认实现方法,进入这个方法,正是spring解析配置文件、加载bean的方法,这里不作分析,具体可参考之前的文章.

####  请求分析

服务起来后,在浏览器中输入``http://localhost:8082/ok``,由于FrameworkServlet重写了Servlet的service方法,无疑会进入到该方法中:
```
protected void service(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {

if (HttpMethod.PATCH.matches(request.getMethod())) {
    processRequest(request, response);
}
else {
    super.service(request, response);
}
}
```
该方法会判断请求的方式,无论哪种都会调用processRequest方法,进入该方法会看到这么一段代码:
```
doService(request, response);
```
直觉告诉我们,这个方法就是用来处理请求的,再跟进去,调用的是子类DispatcherServlet中的doService方法,该方法开始会设置请求头信息,下面有这么一段代码:
```
doDispatch(request, response);
```
同上,直接跟进去,摘取部分代码:
```
ModelAndView mv = null;
Exception dispatchException = null;
// Determine handler for the current request.
//获取MappedHandler
mappedHandler = getHandler(processedRequest);
// Determine handler adapter for the current request.
//获取HandlerAdapter
HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());
// Process last-modified header, if supported by the handler.
// Actually invoke the handler.
mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
mappedHandler.applyPostHandle(processedRequest, response, mv);
processDispatchResult(processedRequest, response, mappedHandler, mv, dispatchException);
triggerAfterCompletion(processedRequest, response, mappedHandler, ex);
```
进入HandlerAdapter的处理方法,``ha.handle(processedRequest, response, mappedHandler.getHandler())``,发现这么一段代码:
```
invocableMethod.invokeAndHandle(webRequest, mavContainer);
```
进入``org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod#invokeAndHandle``:
```
//根据HandlerMapping中请求路径使用反射调用Controller中的求方法
Object returnValue = invokeForRequest(webRequest, mavContainer, providedArgs);
setResponseStatus(webRequest);
if (returnValue == null) {
    if (isRequestNotModified(webRequest) || hasResponseStatus() || mavContainer.isRequestHandled()) {
        mavContainer.setRequestHandled(true);
        return;
    }
}
else if (StringUtils.hasText(this.responseReason)) {
    mavContainer.setRequestHandled(true);
    return;
}
mavContainer.setRequestHandled(false);
try {
    //处理返回结果
    this.returnValueHandlers.handleReturnValue(
            returnValue, getReturnValueType(returnValue), mavContainer, webRequest);
}
catch (Exception ex) {
    if (logger.isTraceEnabled()) {
        logger.trace(getReturnValueHandlingErrorMessage("Error handling return value", returnValue), ex);
    }
    throw ex;
}
```
进入到``org.springframework.web.method.support.InvocableHandlerMethod#invokeForRequest``方法:
```
// 
Object[] args = getMethodArgumentValues(request, mavContainer, providedArgs);
if (logger.isTraceEnabled()) {
    StringBuilder sb = new StringBuilder("Invoking [");
    sb.append(getBeanType().getSimpleName()).append(".");
    sb.append(getMethod().getName()).append("] method with arguments ");
    sb.append(Arrays.asList(args));
    logger.trace(sb.toString());
}
Object returnValue = doInvoke(args);
if (logger.isTraceEnabled()) {
    logger.trace("Method [" + getMethod().getName() + "] returned [" + returnValue + "]");
}
return returnValue;
```
getMethodArgumentValues方法用于获取请求时所带的参数,doInvoke方法使用反射调用Controller中的方法,所以当断点执行到该方法中时,会调用OkController类中的ok方法,returnValue是ok方法的返回值,此时请求已经完成,下面再看响应.再回到``org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod#invokeAndHandle``中,``this.returnValueHandlers.handleReturnValue(returnValue,getReturnValueType(returnValue),mavContainer,webRequest)``方法用于处理响应,进入该方法``org.springframework.web.method.support.HandlerMethodReturnValueHandlerComposite#handleReturnValue``:
```
//根据returnValue、returnType获取不同的HandlerMethodReturnValueHandler
HandlerMethodReturnValueHandler handler = selectHandler(returnValue, returnType);
Assert.notNull(handler, "Unknown return value type [" + returnType.getParameterType().getName() + "]");
//handler有很多子类,会调用不同的实现类
handler.handleReturnValue(returnValue, returnType, mavContainer, webRequest);
```
由于OkController中的ok方法返回的是一个对象,所以进入到的handler的子类是``org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor#handleReturnValue``:
```
ModelAndViewContainer mavContainer, NativeWebRequest webRequest)
    throws IOException, HttpMediaTypeNotAcceptableException, HttpMessageNotWritableException {
mavContainer.setRequestHandled(true);
// Try even with null return value. ResponseBodyAdvice could get involved.
writeWithMessageConverters(returnValue, returnType, webRequest);
```
继续跟进writeWithMessageConverters方法,继续跟进``org.springframework.web.servlet.mvc.method.annotation.AbstractMessageConverterMethodProcessor#writeWithMessageConverters(T, org.springframework.core.MethodParameter, org.springframework.http.server.ServletServerHttpRequest, org.springframework.http.server.ServletServerHttpResponse)``方法,在该方法中会把响应写入到流中返回给客户端.
至此服务端的响应也简单的介绍完毕.
#### 总结
实际的流程远比笔者介绍的复杂的太多,感兴趣的朋友可以打断点调试去探索,其中涉及到很多知识点都没有去过多的分析,后面的文章笔者会涉及;笔者非常想从tomcat容器启动,到Servlet的加载,再到Spring中bean初始化,然后tomcat容器处理请求,分配给Servlet去处理,再到DispatcherServlet前端控制器分发、处理,整个过程,限于笔者目前水平,没有把整个串联起来,形成一条完整的调用链,希望有朋友可以分享.
