---
title: Mac Sublime Text3 Nodejs环境搭建
date: 2019-02-28 01:02:25
tags:
- Sublime Text3
- nodejs
- npm
categories:
- Sublime Text3   
copyright: true #版权声明开启
---
工作中会接触到管理后台的页面开发,之前用的IDE工具是IntelliJ IDEA,虽然功能强大,本身却很沉重,今天介绍使用sublimetext3搭建Nodejs运行环境.
##### 安装插件SublimeText-Nodejs及配置
关于node、npm、sublimetext3的安装不做介绍,下载SublimeText-Nodejs([https://github.com/tanepiper/SublimeText-Nodejs ](https://github.com/tanepiper/SublimeText-Nodejs)),并解压到Packages目录中,通过查找node、npm的路径,在``/Packages/SublimeText-Nodejs/Nodejs.sublime-settings``中配置:
```
{
  // if present, use this command instead of plain "node"
  // e.g. "/usr/bin/node" or "C:\bin\node.exe"
  "node_command": "/usr/local/bin/node",
  // Same for NPM command
  "npm_command": "/usr/local/bin/npm"
}
```
通过``Tools -> Build System -> New Build System``创建Nodejs.sublime-settings文件,并copy``/Packages/SublimeText-Nodejs/Nodejs.sublime-settings/Nodejs.sublime-settings``中的配置信息,修改:
```
{
  ...
  "encoding": "utf8",
  ...
    "osx":
    {
     ## "shell_cmd": "killall node; /usr/local/bin/node  $file" 也可以这样配置
    "shell_cmd": "killall node; /usr/local/bin/npm start $file"
    }
}
```
##### 导入项目,并执行
sublimetext可以建立多个project,不同project可以快速切换,非常棒的功能,通过``File -> open``打开项目,然后``Project -> Save Project As``,这时会新建``*.sublime-project``文件,保存在该Project中,然后需要在``*.sublime-project``中配置Project的目录信息:
```

{
    "folders":
    [
        {
            "path": "/Users/wenchao.wang/IdeaProjects/work/hzfd-dashboard"
        },
        {
            "path": "/Users/wenchao.wang/IdeaProjects/work/hzfd-dashboard"
        }
    ]
}
```
项目已经添加好了,此时可以通过``control+command+p``切换Project啦,通过``control+b``执行,会选择build文件,选择``Nodejs.sublime-settings``即可,如图:
![在这里插入图片描述](https://img-blog.csdnimg.cn/20190228005934486.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0JBVF9vcw==,size_16,color_FFFFFF,t_70)
sublimetext提供大量的插件,用起来十分方便,笔者是一名sublimetext控,sublimetext不仅仅是文本编辑器,可以打造出强大功能的IDE,后续会继续分享sublimetext相关用法.

> 参考文章  

[https://www.jianshu.com/p/032a9867b3cb](https://www.jianshu.com/p/032a9867b3cb)
