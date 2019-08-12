---
title: CountDownLatch
date: 2019-08-12 19:54:07
tags:
- clone
- java
- 并发包
categories:
- 并发包   
copyright: true #版权声明开启       
---

CountDownLatch是``java.util.concurrent``包下的线程同步类,并发环境下线程对计数值减1操作,当计数值为0时,被wait阻塞的线程将被唤醒,达到线程同步.
该类涉及到的主要方法:
```
// 当前线程在计数值减到0之前一直等待,除非当前线程被中断
void await()
// 当前线程在计数值减到0之前一直等待,除非当前线程被中断或者超过了指定的等待时间
boolean await(long timeout, TimeUnit unit)
// 减少计数值,当计数值减到0时,释放所有的等待线程
void countDown()
// 返回当前计数值
long getCount()
```
示例:
```
        CountDownLatch countDownLatch = new CountDownLatch(3);
        ExecutorService executorService = Executors.newFixedThreadPool(3);
        for (int i = 0; i < 3; i++) {
            int finalI = i;
            executorService.execute(new Runnable() {
                @Override
                public void run() {
                    System.out.println("任务执行结束啦,i:" + finalI + "," + "时间t" + finalI + ":" + System.currentTimeMillis());
                    countDownLatch.countDown();

                }
            });
        }
        try {
            countDownLatch.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
```
通过控制台可发现,输出时间几乎一致,把上面的代码改动如下:
```
 CountDownLatch countDownLatch = new CountDownLatch(3);
        ExecutorService executorService = Executors.newFixedThreadPool(3);
        for (int i = 0; i < 3; i++) {
            int finalI = i;
            executorService.execute(new Runnable() {
                @Override
                public void run() {
                    if (finalI == 0 || finalI == 1) {
                        try {
                            Thread.sleep(1000);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                    System.out.println("任务执行结束啦,i:" + finalI + "," + "时间t" + finalI + ":" + System.currentTimeMillis());
                    countDownLatch.countDown();
                }
            });
        }
        try {
            System.out.println("==========start,时间t3:" + System.currentTimeMillis());
            countDownLatch.await();
            System.out.println("==========end,,时间t4:" + System.currentTimeMillis());
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
```
当i=0或1时,线程休眠1mis,打印出来的时间 ``t3<t2<t0<=t1<=t4``,t2小于t0、t1很好理解,由于t0、t1所在线程休眠导致值变大,而t2、t1、t0为何处于(t3,t4]之间呢,原来由于子线程中任务完成时计数值减1操作,但是线程0、1休眠了1mis才完成任务并计数值减1,所以主线程一致等到线程0、1完成后才继续执行.将上面代码改动如下:
```
        CountDownLatch countDownLatch = new CountDownLatch(3);
        ExecutorService executorService = Executors.newFixedThreadPool(3);
        for (int i = 0; i < 3; i++) {
            int finalI = i;
            executorService.execute(new Runnable() {
                @Override
                public void run() {
                    if (finalI == 0 || finalI == 1) {
                        try {
                            Thread.sleep(1000);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }

                    System.out.println("任务执行结束啦,i:" + finalI + "," + "时间t" + finalI + ":" + System.currentTimeMillis());
                    countDownLatch.countDown();

                }
            });
        }
        try {
            System.out.println("==========start,时间t3:" + System.currentTimeMillis());
            countDownLatch.await(100,TimeUnit.MILLISECONDS);
            System.out.println("==========end,,时间t4:" + System.currentTimeMillis());
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
```
执行后发现,``t3<t2<t4<t0<=t1``,t2、t3的大小不能确定,这个很好理解,但是t4肯定是小于t0、t1的,因为使用了带超时时间的``await``,由于主线程等待的超时阈值是100毫秒,而线程t0、t1的休眠时间大于超时时间,所以主线程不会继续等待,超时后主线程继续执行.

> 本文参考

[https://www.cnblogs.com/skywang12345/p/3533887.html](https://www.cnblogs.com/skywang12345/p/3533887.html)  
[https://www.jianshu.com/p/7c7a5df5bda6](https://www.jianshu.com/p/7c7a5df5bda6)
