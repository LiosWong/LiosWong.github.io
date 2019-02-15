---
title: JWT
date: 2019-02-16 01:42:53
tags:
- java
- JWT
categories:
- java   
copyright: true #版权声明开启     
---
![https://note.youdao.com/yws/api/personal/file/WEBff086a9673fbfd80034914abfb78b656?method=download&shareKey=58577f840ca558fcb3d378123e53640d](https://note.youdao.com/yws/api/personal/file/WEBff086a9673fbfd80034914abfb78b656?method=download&shareKey=58577f840ca558fcb3d378123e53640d)
上图文字来自[https://jwt.io/introduction/](https://jwt.io/introduction/)  
现项目中的JWT来解析如下：
![https://note.youdao.com/yws/api/personal/file/WEBffd386ebffa4fa1b2aafc2ec086f332f?method=download&shareKey=9bc3aea3ffb8508f2093bf7d862a9513](https://note.youdao.com/yws/api/personal/file/WEBffd386ebffa4fa1b2aafc2ec086f332f?method=download&shareKey=9bc3aea3ffb8508f2093bf7d862a9513)
左边是生成的token,左边是其三部分的解析。
项目中的使用,
```
public class JWTSignerUtil {
    private static final String JWT_SECRET = "密钥字符串";
    private static JWTSigner signer = new JWTSigner(JWT_SECRET);
    /**
    ** 生成JWT
    **/
    public static String shouldSignStringOrURICollection(String uri, String userId) throws Exception {
        LinkedList<String> aud = new LinkedList<String>();
        aud.add(uri);
        aud.add(System.currentTimeMillis() + "");
        aud.add(userId);
        HashMap<String, Object> claims = new HashMap<String, Object>();
        claims.put("aud", aud);
        return signer.sign(claims);
    }
   /**
    ** 解析
    **/
    public static List verify(String token){
        Map<String, Object> decodedPayload;
        try {
            decodedPayload = new JWTVerifier(JWT_SECRET).verify(token);
            List<String> list = (List<String>) decodedPayload.get("aud");
            return list;
        } catch (Exception e) {
            return null;
        }
    }

    public static void main(String[] args) throws Exception {
        String token = JWTSignerUtil.shouldSignStringOrURICollection(
                "/user/login","304914");
        System.out.println(token);
        List tokenList = JWTSignerUtil.verify(token);
        Long userId = Long.parseLong(tokenList.get(2) + "");
        System.out.println(userId);
    }
}
```
交互流程如下：
![https://segmentfault.com/image?src=http://source.aicode.cc/markdown/jwt-diagram.png&objectId=1190000005047525&token=fc83f4c0cf107cabeafd6a449cd49762](https://segmentfault.com/image?src=http://source.aicode.cc/markdown/jwt-diagram.png&objectId=1190000005047525&token=fc83f4c0cf107cabeafd6a449cd49762)(图来自参考文章)  
客户端登录时，服务端根据JWT生成token,并返回给客户端，客户端再次请求时需要带上该token,服务端在拦截器中拿到token后使用JWT解析，如果拿到负载中的值后，会通过此次请求否则中断此次请求.  
目前项目中还没有设置token失效；当客户端注销时，服务端目前什么操作都没做，只需客户端清除本地中的token。
### 总结
1. 由于用户的状态在服务端的内存中是不存储的，所以这是一种无状态的认证机制;因为JWT并不使用Cookie，可以使用任何域名提供API服务而不需要担心跨域资源共享问题
2. 由于JSON比XML简洁，因此在编码时它的大小也更小，使得JWT比SAML更紧凑。这使得JWT成为在HTML和HTTP环境中传递的不错选择
2. 在安全方面，SWT只能使用HMAC算法通过共享密钥对称签名。但是，JWT和SAML令牌可以使用X.509证书形式的公钥/私钥对进行签名。与签名JSON的简单性相比，使用XML数字签名对XML进行签名而不会引入模糊的安全漏洞非常困难
> 参考文章  

[https://www.jianshu.com/p/2fdc20a42c41](https://www.jianshu.com/p/2fdc20a42c41)
