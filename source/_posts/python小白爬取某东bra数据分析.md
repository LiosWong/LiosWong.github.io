---
title: python小白爬取某东bra数据分析
date: 2019-02-15 19:02:02
categories:
- python    
tags:
- 爬虫
- python
- ECharts
top: 100 #文章置顶 越大越靠前

---
最近用python爬取了某东上的x款bra的用户评论,然后进行了size、color分析,直接上图:
![https://note.youdao.com/yws/api/personal/file/WEB4ca739a6d1f980eb0abd34b663486565?method=download&shareKey=bc493e1e2c90cbb1199cf42326cd1aea](https://note.youdao.com/yws/api/personal/file/WEB4ca739a6d1f980eb0abd34b663486565?method=download&shareKey=bc493e1e2c90cbb1199cf42326cd1aea)
从图表上分析初步得出该款bra黑色较受欢迎，购买的小姐姐size 75B最多～
下面通过数据爬取、数据解析、图表分析三方面分析。
### 数据爬取
```
def doPullData():
    # 设置请求头
    headers = {
        ":authority": "sclub.jd.com",
        ":method": "GET",
        ":path": "/comment/productPageComments.action?callback=fetchJSON_comment98vv1980&productId=10124144495&score=0&sortType=5&page=0&pageSize=10&isShadowSku=0&fold=1",
        ":scheme": "https",
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
        "accept-encoding": "gzip, deflate, br",
        "accept-language": "zh-CN,zh;q=0.9,en;q=0.8",
        "cookie": "shshshfpb=086b12d4e13b64d2ab454c0592b747059858aa0b2c965c7b25b1fef00d; shshshfpa=a9bc80bb-8fae-00ea-d688-7c060b026654-1545813312; ipLoc-djd=1-72-2799-0; user-key=a45a7f32-8d02-45c7-acdb-80586f8a75f4; cn=0; PCSYCityID=1213; __jdc=122270672; __jda=122270672.1960352535.1545662675.1547021613.1547045550.6; __jdu=1960352535; unpl=V2_ZzNtbRFRSkdwWBMBL0kLVWIFGwkSUkcVfQ5GUXNNCwZmVhcJclRCFX0UR1RnGFQUZAEZXkNcQx1FCEdkeBBVAWMDE1VGZxBFLV0CFSNGF1wjU00zQwBBQHcJFF0uSgwDYgcaDhFTQEJ2XBVQL0oMDDdRFAhyZ0AVRQhHZHsRWwRlBxFZQFNzJXI4dmRyHl8GZAoiXHJWc1chVEBQexlcBCoDGlpDVUcWcQpCZHopXw%3d%3d; shshshfp=b4d288e3959f3d57333ec63b277d246e; TrackID=1mqY28YiCc_QIPlhdl_yB-5MJfQNbi0MmMLJXAlsLuDy5vAImaiIuUujo18CehAJ9sVAmWOgexcWY8CXjfL-G1ydikjVAdUOf1Du5k2JHxrE0qBQ4fKPSSkYIW3etZQJO; thor=5FE438B5588118B03FF72C53690F219FECC569A54F2BBE0E20BDA38248047F07675EEEC90BBB86067FB102D042F95B66557CD207D7FC8F1CA2B9E1EA1BEA7BE1E9DE225C763524E7C65C35DF6062795323C8A69734796F1C721F9F5E1BACFC10864AAB9B51D5144D6FCE4ADF69D90AD86191A738C9E7C25A0BDD20B1F81B1170C2E9EE80E214E9A1A6A6C64DD7AD6AEC; pinId=kYCBFA88kKZe4tdMoc03gA; pin=2265532975_m; unick=diy_os; ceshi3.com=103; _tp=Oh5iHgb0BZF3J4ODGsToig%3D%3D; _pst=2265532975_m; __jdb=122270672.8.1960352535|6.1547045550; __jdv=122270672|baidu-pinzhuan|t_288551095_baidupinzhuan|cpc|0f3d30c8dba7459bb52f2eb5eba8ac7d_0_b78c4addeafa478ea45197149ef20d4e|1547047238917; shshshsID=f0c8a36bfc34b9d362a3827dcaed3cac_6_1547047239476; JSESSIONID=971C3D798C75A96132DA343FCB0EAB0C.s1",
        "referer": "https://item.jd.com/10124144495.html",
        "user-agent": "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Mobile Safari/537.36"
    }
    # 请求URL,通过某东网站抓包即可获取
    request_url = "https://sclub.jd.com/comment/productPageComments.action?callback=fetchJSON_comment98vv1980&productId=10124144495&score=0&sortType=5&pageSize=30&isShadowSku=0&rid=0&fold=1&page=%d"
    file = None
    for page in range(1, 5000):
        url = request_url % page
        r = requests.get(url, headers)
        time.sleep(2);
        try:
             # 正则获取所需数据
             rex = re.findall(r"fetchJSON_comment98vv1980\((.*)\);", r.text);
             comment = json.loads(rex[0]);
             comments = comment['comments']
        except Exception as e:
             print(e);
             continue;
        for comment in comments:
            item = {}
            item['content'] = comment['content']  # 评论正文
            item['guid'] = comment['guid']
            item['color'] = comment['productColor']  # 商品颜色
            item['size'] = comment['productSize']
            item['userClientShow'] = comment['userClientShow']  # 购物渠道
            file = open(
                '/Users/wenchao.wang/LiosWang/sublimetext/bra_jindong.json', mode='a+')
            # 换行写入文件
            # 写入json到本地磁盘,注意中文乱码处理
            file.write(json.dumps(item, ensure_ascii=False) + ",\n")
            print(json.dumps(item, ensure_ascii=False), ",")
        file.close()
```
由于调用request_url获取的数据不是json格式，所以上面使用了正则截取需要的json文本，然后把得的数据写入本地磁盘文件,在sublimetext3中打开bra_jindong.json文本,由于写入的文本有一定的格式，所以稍作处理就是一个格式规范的json啦

### 数据解析
以上已经得到数据，但是需要对bra的size、color进行统计，所以不得不对数据进行处理了，下面直接通过代码分析:
```
def parsingJSON():
    textJSON = None
    # 打开文件
    with open('/Users/wenchao.wang/LiosWang/sublimetext/bra_jindong.json', encoding='utf-8') as f:
        # print(f.read());
        textJSON = json.load(f)
        dataArray = textJSON['data']
        dataArray.sort(key=itemgetter('size'))
        sortDataArray = groupby(dataArray, itemgetter('size'))
        # dataArray.sort(key=itemgetter('color'))
        # sortDataArray = groupby(dataArray, itemgetter('color'))
        # 按照size或color统计
        sizeInfo = dict([(key, len(list(group)))
                         for key, group in sortDataArray])
        print(json.dumps(sizeInfo, ensure_ascii=False))
        # 打印出所有分组明细
        #for key, group in sortDataArray:
            #for g in group:
                #pass
               # print(key,g);
        # print(textJSON['data'][0]);
```
使用python内置模块operator、itertools可以很好的对数据进行分组统计,以上对大小、颜色统计的输出结果分别为:
![https://note.youdao.com/yws/api/personal/file/WEBa829f9231f752c33bfe4f8cf2c33a10c?method=download&shareKey=5cd08578de074cc96a315b8c3535e90c](https://note.youdao.com/yws/api/personal/file/WEBa829f9231f752c33bfe4f8cf2c33a10c?method=download&shareKey=5cd08578de074cc96a315b8c3535e90c)
![https://note.youdao.com/yws/api/personal/file/WEB75feae340a12247cd8d3d993ebdcde23?method=download&shareKey=cd58ad7fcff8f61989414e8b6a7472b1](https://note.youdao.com/yws/api/personal/file/WEB75feae340a12247cd8d3d993ebdcde23?method=download&shareKey=cd58ad7fcff8f61989414e8b6a7472b1)

### 图表分析
以上已经得到具体数据，下面使用echarts通过图片的方式直观的展示。使用echarts也非常简单，到其官网上下载js文件引入即可。具体代码如下:
```
<!DOCTYPE html>

<head>
    <meta charset="UTF-8">
    <title>ECharts</title>
</head>

<body>
    <!-- 为ECharts准备一个具备大小（宽高）的Dom -->
    <div id="bra_size" style="height:400px"></div>
    <div id="bra_color" style="height:400px"></div>
    <!-- ECharts单文件引入 -->
    <!--script src="http://echarts.baidu.com/build/dist/echarts.js"></script-->
    <script src="echarts.min.js"></script>
    <script src="esl.js"></script>
    <script src="https://code.jquery.com/jquery-3.1.1.min.js"></script>
    <script type="text/javascript">
    var myChartSize = echarts.init(document.getElementById('bra_size'));
    var myChartColor = echarts.init(document.getElementById('bra_color'));
    // 显示标题，图例和空的坐标轴
    option = {
        title: {
            text: '某东x款bra size统计',
            subtext: 'from LiosWong',
            x: 'center'
        },
        tooltip: {
            trigger: 'item',
            formatter: "{a} <br/>{b} : {c} ({d}%)"
        },
        legend: {
            orient: 'vertical',
            left: 'left',
            data: ['70A',
                '70B',
                '75A',
                '75B',
                '75C',
                '80A',
                '80B',
                '80C',
                '85B',
                '85C'
            ]
        },
        series: [{
            name: '访问来源',
            type: 'pie',
            radius: '55%',
            center: ['50%', '60%'],
            data: [
                { name: '70A', value: 16 },
                { name: '70B', value: 20 },
                { name: '75A', value: 55 },
                { name: '75B', value: 123 },
                { name: '75C', value: 9 },
                { name: '80A', value: 47 },
                { name: '80B', value: 85 },
                { name: '80C', value: 31 },
                { name: '85B', value: 60 },
                { name: '85C', value: 44 }
            ],
            itemStyle: {
                emphasis: {
                    shadowBlur: 10,
                    shadowOffsetX: 0,
                    shadowColor: 'rgba(0, 0, 0, 0.5)'
                }
            }
        }]
    };

    option1 = {
        title: {
            text: '某东x款bra 颜色统计',
            subtext: 'from LiosWong',
            x: 'center'
        },
        tooltip: {
            trigger: 'item',
            formatter: "{a} <br/>{b} : {c} ({d}%)"
        },
        legend: {
            orient: 'vertical',
            left: 'left',
            data: ['大红', '浅粉', '浅黄', '肤色', '黑色']
        },
        series: [{
            name: '访问来源',
            type: 'pie',
            radius: '55%',
            center: ['50%', '60%'],
            data: [
                { name: '大红', value: 105 },
                { name: '浅粉', value: 47 }, { name: '浅黄', value: 29 },
                { name: '肤色', value: 109 },
                { name: '黑色', value: 200 }
            ],
            itemStyle: {
                emphasis: {
                    shadowBlur: 10,
                    shadowOffsetX: 0,
                    shadowColor: 'rgba(0, 0, 0, 0.5)'
                }
            }
        }]
    };
    myChartSize.setOption(option);
    myChartColor.setOption(option1);
    </script>
</body>

</html>
```
为了方便使用,利用nginx搭建了web服务指向本地html、js静态资源,在浏览器中输入``http://localhost:8088/echarts_bra.html``即可得出文章开始的图表。笔者是一名python小白，有任何问题和建议欢迎随时交流，下面是我的wechat

![https://note.youdao.com/yws/api/personal/file/WEBc7c871f0e0cbc535314b9301cd39a1ef?method=download&shareKey=be641961ad14870b805fb689bcdec557](https://note.youdao.com/yws/api/personal/file/WEBc7c871f0e0cbc535314b9301cd39a1ef?method=download&shareKey=be641961ad14870b805fb689bcdec557)
