---
title: Elasticsearch API简单使用
tags:
- Elasticsearch
- elk    
categories:
- elk    
copyright: true #版权声明开启
---
笔者喜欢做一些小工具，给PM或者组内同学使用，不仅仅可以提高工作效率，而且也可以学一些前端方面的知识。之前使用Elasticsearch API做过管理后台的小工具，一直没有总结，最近给PM哥们又做了一个小工具，而且也使用到了Elasticsearch API，正好做个简单分享。
> #### 需求

PM最近经常让我统计每家机构调用某个接口的失败记录信息，虽然接口调用记录已经打到日志了，但是没有关键字信息所以很难去统计，显然之前做过根据一个或多个关键字查询我们平台所有日志的后台管理小工具不适用了。

> #### 方案

1. 业务底层必须把三方返回信息返回到上层
2. 业务上层统一处理,按照固定格式把信息打到日志里
3. 管理后台根据条件筛选查找,通过es根据关键字查找

> #### 编码

1. 业务代码日志打印
```
JSONObject jsonObject = new JSONObject();
jsonObject.put("time", new Date());
jsonObject.put("companyId", companyId);
jsonObject.put("companyName", CompanyAppIdEnum.getCompanyAppIdEnum(companyId).getDesc());
jsonObject.put("orderNo", "暂不展示敏感信息");
jsonObject.put("orderStatus", -1);
jsonObject.put("type",FilterFailEnum.FILTER.getName());
// 关键字
jsonObject.put("keyword", CompanyAppIdEnum.getCompanyAppIdEnum(companyId).getDesc() + FilterFailEnum.FILTER.getDesc());
jsonObject.put("fail", response.getErrorMsg());
thirdLogger.info(jsonObject.toJSONString());
```
2. Elasticsearch Client构建
因为是Java程序员，所以用的Java客户端   
构建TransportClient
```
 /**
     * elasticsearch集群
     * TransportClient获取
     *
     * @return
     */
    protected TransportClient getTransportClient() {
        if (transportClient == null) {
            synchronized (ElkLogSearchServiceImpl.class) {
                if (transportClient == null) {
                    //ES集群地址
                    String[] ESHosts = configUtil.getEsClientHosts().split(",");
                    //设置es实例名称
                    Settings settings = Settings.builder().put("cluster.name", configUtil.getEsClusterName())
                            //自动嗅探整个集群的状态，把集群中其他ES节点的ip添加到本地的客户端列表中、
                            .put("client.transport.sniff", true)
                            .put("xpack.security.user", configUtil.getEsClientUser())
                            .put("xpack.security.transport.ssl.verification_mode", "certificate")
                            .put("xpack.security.transport.ssl.enabled", "true")
                            .put("xpack.security.transport.ssl.keystore.path", configUtil.getEsCertificates())
                            .put("xpack.security.transport.ssl.truststore.path", configUtil.getEsCertificates()).build();
                    TransportClient preBuiltTransportClient = new PreBuiltXPackTransportClient(settings);
                    for (String esHost : ESHosts) {
                        preBuiltTransportClient.addTransportAddress(new TransportAddress(new InetSocketAddress(esHost, 9300)));
                    }
                    return preBuiltTransportClient;
                }
            }
        }
        return transportClient;
    }
```
3. 根据时间获取索引、构建查询条件
```
/**
 * 根据时间范围获得索引
 * @param startDate
 * @param endDate
 * @return
 */
protected String[] getIndices(long startDate, long endDate,String indiceName) {
    int days = (int) (endDate - startDate) / 86400000 + 1;
    String[] indices = new String[days];
    for (int i = 0; i < days; i++) {
        String dayIndex = simpleDateFormat.format(new Date(startDate + i * 86400000));
        indices[i] = indiceName + dayIndex;
    }
    return indices;
}
```

```
protected QueryBuilder getFilterQueryBuilder(String keywords){
    BoolQueryBuilder queryBuilder = QueryBuilders.boolQuery();
    // 可以添加多个查询条件
    queryBuilder.must(QueryBuilders.matchPhraseQuery("message.params",keywords));
    return queryBuilder;
}
```
4. 查询
```
 public ResponseVo getFilterFailByES(Long companyId, int pageNo, FilterFailEnum filterFailEnum, long startDate, long endDate) {
        ResponseVo vo = new ResponseVo();
        LinkedList linkedList = new LinkedList();
        transportClient = getTransportClient();
        String regexp = CompanyAppIdEnum.getCompanyAppIdEnum(companyId).getDesc() + filterFailEnum.getDesc();
        String[] indices = getIndices(startDate, endDate, IndiceTypeEnum.JKZJ_API_THIRD_SERVER_LOG.getIndiceName());
        QueryBuilder queryBuilder = getFilterQueryBuilder(regexp);
        try {
            SearchResponse searchResponse = transportClient.prepareSearch(indices).setQuery(queryBuilder).addSort("logdate", SortOrder.DESC).setSize(10).setFrom((pageNo - 1) * 10).execute().actionGet();
            SearchHits searchHits = searchResponse.getHits();
            if (searchHits.getTotalHits() > 0) {
                for (SearchHit searchHit : searchHits) {
                    JSONObject paramsDetailsJO = JSONObject.parseObject(searchHit.getSourceAsString());
                    JSONObject messapgeParam = paramsDetailsJO.getJSONObject("message").getJSONObject("params");
                    Long time = messapgeParam.getLong("time");
                    String companyIds = messapgeParam.getString("companyId");
                    String companyName = messapgeParam.getString("companyName");
                    String orderNo = messapgeParam.getString("orderNo");
                    String orderStatus = messapgeParam.getString("orderStatus");
                    String fail = messapgeParam.getString("fail");
                    String type = messapgeParam.getString("type");
                    Map map = new HashMap();
                    map.put("companyId", companyIds);
                    Date times = new Date(Long.valueOf(time));
                    map.put("time", DateUtils.getDate(times));
                    map.put("companyName", companyName);
                    map.put("orderNo", orderNo);
                    map.put("orderStatus", orderStatus);
                    map.put("fail", fail);
                    map.put("type", type);
                    linkedList.add(map);
                }
            }
            vo.setVoList(linkedList);
            //总条数
            vo.setMsg(searchHits.getTotalHits() + "");
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
            vo.setCode(204);
            vo.setMsg("查询失败");
        }
        return vo;
    }
```
> #### 页面展示
> 
![https://note.youdao.com/yws/api/personal/file/WEB8821157b1044b8b70dee777027aa7258?method=download&shareKey=f47bc85a3780b5f5343ddddb75743be5](https://note.youdao.com/yws/api/personal/file/WEB8821157b1044b8b70dee777027aa7258?method=download&shareKey=f47bc85a3780b5f5343ddddb75743be5)
好啦，再也不用被PM老哥烦了。
    
