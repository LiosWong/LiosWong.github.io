---
title: CyclicBarrier
date: 2019-08-19 10:39:40
tags:
- java
- 并发包
categories:
- 并发包   
copyright: true #版权声明开启       
---
``java.util.concurrent.CyclicBarrier``字面意思是循环屏障,可实现一组线程等待至某种状态(屏障点)后,然后再一起同时执行,该屏障可循环使用,这一点和``CountDownLatch``不同,下面简单介绍下``CyclicBarrier``用法,对原理不作说明.  
> CyclicBarrier两个构造函数:

```
给定数量的线程（线程）等待栅栏,且当屏障跳闸时不执行预定义的动作
CyclicBarrier(int parties)
给定数量的线程（线程）等待栅栏,当屏障跳闸时执行给定的屏障动作,由最后一个进入屏障的线程执行
CyclicBarrier(int parties, Runnable barrierAction)
```
一个栗子:
```
import java.util.concurrent.*;
/**
 * @author LiosWong
 * @description
 * @date 2019-08-12 23:49
 */
public class BarrierTest {

    public static void main(String[] args) {
        CyclicBarrier cyclicBarrier = new CyclicBarrier(3, new Runnable() {
            @Override
            public void run() {
                System.out.println("当前线程名:" + Thread.currentThread().getName() + "," + "全部集合完毕:" + +System.currentTimeMillis());
            }
        });

        ExecutorService executorService = Executors.newFixedThreadPool(3);

        for (int i = 0; i < cyclicBarrier.getParties(); i++) {
            int finalI = i;
            executorService.execute(new Runnable() {
                @Override
                public void run() {
                    System.out.println("当前线程名:" + Thread.currentThread().getName() + "," + finalI + "就位啦" + ",time:" + System.currentTimeMillis());
                    try {
                        // 等待
                        cyclicBarrier.await();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    } catch (BrokenBarrierException e) {
                        e.printStackTrace();
                    }
                    System.out.println("当前线程名:" + Thread.currentThread().getName() + "," + finalI + "出发啦" + ",time:" + System.currentTimeMillis());
                }

            });
        }

    }
}
```
上面的三个线程全部到栅栏点时,然后一起往下继续运行,简单的修改上面的代码:
```
import java.util.concurrent.*;

/**
 * @author LiosWong
 * @description
 * @date 2019-08-12 23:49
 */
public class BarrierTest {

    public static void main(String[] args) {
        CyclicBarrier cyclicBarrier = new CyclicBarrier(3);

        ExecutorService executorService = Executors.newFixedThreadPool(3);

        for (int i = 0; i < cyclicBarrier.getParties(); i++) {
            int finalI = i;
            executorService.execute(new Runnable() {
                @Override
                public void run() {
                    System.out.println("当前线程名:" + Thread.currentThread().getName() + "," + finalI + "就位啦" + ",time:" + System.currentTimeMillis());
                    try {
                        if (finalI == 0) {
                            Thread.sleep(200);
                        }
                        // 栅栏等待超时时间为100毫秒,超时后不再等待未到达栅栏的线程,继续往下执行
                        cyclicBarrier.await(100, TimeUnit.MILLISECONDS);
=                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    } catch (BrokenBarrierException e) {
                        e.printStackTrace();
                    } catch (TimeoutException e) {
                        e.printStackTrace();
                    }
                    System.out.println("当前线程名:" + Thread.currentThread().getName() + "," + finalI + "出发啦" + ",time:" + System.currentTimeMillis());
                }

            });
        }

    }
}
```
上面执行结果报代码超时异常,发现finalI=0的线程是最后执行完成,也就是设置了栅栏等待超时后,如果有线程在超时时间内还未到达栅栏时,其他线程不再等待,继续往下执行
