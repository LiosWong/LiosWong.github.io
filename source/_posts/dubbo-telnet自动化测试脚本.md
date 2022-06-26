---
title: dubbo_telnet自动化测试脚本
date: 2020-05-28 16:53:17
tags:
- python
- dubbo
categories:
- useful-scripts
copyright: true #版权声明开启
---
该脚本使用dubbo telnet方式（dubbo官网提供的dubbo python client目前只支持jsonrpc协议，目前环境不支持）,可以根据该脚本实现dev、test环境的接口自动化、压力测试，根据具体需求填补脚本即可。
```
#!/usr/bin/python
# -*- coding:utf-8 -*-
import json
import telnetlib
import unittest
import time
import re


class Dubbo(telnetlib.Telnet):

    prompt = 'dubbo>'
    coding = 'utf-8'

    def __init__(self, host=None, port=0):
        super().__init__(host, port)
        self.write(b'\n')

    def command(self, flag, str_=""):
        data = self.read_until(flag.encode())
        self.write(str_.encode() + b"\n")
        return data

    def invoke(self, service_name, method_name, args):
        command_str = "invoke {0}.{1}({2})".format(
            service_name, method_name, args)
        self.command(Dubbo.prompt, command_str)
        data = self.command(Dubbo.prompt, "")
        data = json.loads(data.decode(
            Dubbo.coding, errors='ignore').split('\n')[0].strip())
        return data


class DcTest(unittest.TestCase):
    #setUp 用于设置初始化的部分，在测试用例执行前，这个方法中的函数将先被调用 #
    def setUp(self):
        '''
        33: Dubbo('301.57.79.01', 27075)
        44: Dubbo('106.12.59.915', 7075)
        dev: Dubbo('121.36.108.215', 6666)
        '''
        self.dubbo_conn = Dubbo('127.0.0.1', 6666)
        self.verificationErrors = []  # 脚本运行时，错误的信息将被打印到这个列表中#
        self.accept_next_alert = True  # 是否继续接受下一个警告#
    # 更改司机状态
    def test_update_driver_status(self):
        data = {"class":"com.caocao.dc.api.dto.input.DriverStatusDTO","driverNo":1003019,"status":1}
        result = self.dubbo_conn.invoke(
            "com.caocao.dc.api.app.DriverCenterApi", "updateDriverStatus", data)
        print(result)
        time.sleep(2)
    # 司机开始服务
    def test_start_service(self):
        data = {"class": "com.caocao.dc.api.dto.input.DriverStartServiceParam", "driverNo": 1003019,"lat": 30.206907552083333, "lng": 120.22090521918403, "orderLabel": 128, "orderNo": 74602113541, "bizType": 1}
        result = self.dubbo_conn.invoke(
            "com.caocao.dc.api.app.response.DriverOrderResponseApi", "startService", data)
        print(result)
        time.sleep(2)
    def tearDown(self):
        '''
        tearDown 方法在每个测试方法执行后调用，这个地方做所有清理工作，如退出浏览器等。
        self.assertEqual([], self.verificationErrors) 是个难点，
        对前面verificationErrors方法获得的列表进行比较；如查verificationErrors的列表不为空，输出列表中的报错信息。
        '''
        self.assertEqual([], self.verificationErrors)

class DriverSupportTest(unittest.TestCase):
    #setUp 用于设置初始化的部分，在测试用例执行前，这个方法中的函数将先被调用 #
    def setUp(self):
        '''
        33: Dubbo('17.46.148.208', 7071)
        44: Dubbo('19.22.19.25', 7075)
        '''
        self.dubbo_conn = Dubbo('97.92.238.218', 7071)
        self.verificationErrors = []  # 脚本运行时，错误的信息将被打印到这个列表中#
        self.accept_next_alert = True  # 是否继续接受下一个警告#

    # 虚拟号AX预绑定
    def test_pre_bind_phone(self):
        data = {"class":"com.caocao.driver.support.dto.phone.BindPhoneAxPreParam","customerPhone":"4141241","orderNo":4141241,"bizType":80,"expireTime":1,"areaCode":"0571"}
        result = self.dubbo_conn.invoke(
            "com.caocao.driver.support.api.VirPhoneAxApi", "preBindPhone", data)
        print(result)
        time.sleep(2)
    def tearDown(self):
        '''
        tearDown 方法在每个测试方法执行后调用，这个地方做所有清理工作，如退出浏览器等。
        self.assertEqual([], self.verificationErrors) 是个难点，
        对前面verificationErrors方法获得的列表进行比较；如查verificationErrors的列表不为空，输出列表中的报错信息。
        '''
        self.assertEqual([], self.verificationErrors)

'''
driver-order
'''
class DriverOrderTest(unittest.TestCase):
    #setUp 用于设置初始化的部分，在测试用例执行前，这个方法中的函数将先被调用 #
    def setUp(self):
        '''
        33: Dubbo('101.159.59.142', 7071)
        44: Dubbo('106.2.9.25', 7071)
        '''
        self.dubbo_conn = Dubbo('111.32.49.515', 7071)
        self.verificationErrors = []  # 脚本运行时，错误的信息将被打印到这个列表中#
        self.accept_next_alert = True  # 是否继续接受下一个警告#
    # 订单流程校验
    def test_check_serve_flow(self):
        data = {"class": "com.caocao.driver.order.param.ServeFlowCheckParam", "bizType": 1, "cityCode": "0571",
                "driverNo": 3500035951, "driverType": 1, "orderLabel": 0, "orderNo": 8361805001163, "orderType": 1, "serveFlow": 1}
        result = self.dubbo_conn.invoke(
            "com.caocao.driver.order.api.DriverServeActionSupportApi", "checkServeFlow", data)
        print(result)
        time.sleep(2)
    # 司机开始服务订单(实时单确认接单/预约单开始服务)
    def test_start_service(self):
        print(self.dubbo_conn)

    def tearDown(self):
        '''
        tearDown 方法在每个测试方法执行后调用，这个地方做所有清理工作，如退出浏览器等。
        self.assertEqual([], self.verificationErrors) 是个难点，
        对前面verificationErrors方法获得的列表进行比较；如查verificationErrors的列表不为空，输出列表中的报错信息。
        '''
        self.assertEqual([], self.verificationErrors)

'''
local
'''
class LocalTest(unittest.TestCase):
    #setUp 用于设置初始化的部分，在测试用例执行前，这个方法中的函数将先被调用 #
    def setUp(self):
        '''
        local1: Dubbo('127.0.0.1', 20880)
        '''
        self.dubbo_conn = Dubbo('127.0.0.1', 20880)
        self.verificationErrors = []  # 脚本运行时，错误的信息将被打印到这个列表中#
        self.accept_next_alert = True  # 是否继续接受下一个警告#
    # 测试sayHello
    def test_say_hello(self):
        for x in range(0,1):
            data = {"class":"com.alibaba.dubbo.demo.BeanParam","name":"lios","age":25+x}
            result = self.dubbo_conn.invoke(
            "com.alibaba.dubbo.demo.DemoService", "hello", data)
            print(result)
            pass
        time.sleep(2)

    def test_2(self):
        print(self.dubbo_conn)

    def tearDown(self):
        '''
        tearDown 方法在每个测试方法执行后调用，这个地方做所有清理工作，如退出浏览器等。
        self.assertEqual([], self.verificationErrors) 是个难点，
        对前面verificationErrors方法获得的列表进行比较；如查verificationErrors的列表不为空，输出列表中的报错信息。
        '''
        self.assertEqual([], self.verificationErrors)


'''
dc suite
'''
def dc_suite():
    suite = unittest.TestSuite()
    suite.addTest(DcTest("test_update_driver_status"))
    suite.addTest(DcTest("test_start_service"))
    return suite
    pass

'''
driver-support suite
'''
def driver_support_suite():
    suite = unittest.TestSuite()
    suite.addTest(DriverSupportTest("test_pre_bind_phone"))
    return suite
    pass

'''
driver-order suite
'''
def driver_order_suite():
    suite = unittest.TestSuite()
    suite.addTest(DriverOrderTest("test_check_serve_flow"))
    suite.addTest(DriverOrderTest("test_start_service"))
    return suite
    pass
'''
local suite
'''
def local_suite():
    suite = unittest.TestSuite()
    suite.addTest(LocalTest("test_say_hello"))
    return suite
    pass

if __name__ == "__main__":
    ## 指定suite套件
    unittest.main(defaultTest='dc_suite')

```
