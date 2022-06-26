---
title: ThreadLocal
date: 2019-02-16 01:42:27
tags:
- java
- ThreadLocal
categories:
- java   
copyright: true #版权声明开启       
---
#### ThreadLocal是什么
```
* This class provides thread-local variables.  These variables differ from
 * their normal counterparts in that each thread that accesses one (via its
 * {@code get} or {@code set} method) has its own, independently initialized
 * copy of the variable.  {@code ThreadLocal} instances are typically private
 * static fields in classes that wish to associate state with a thread (e.g.,
 * a user ID or Transaction ID).
```
简单的说ThreadLocal是本地线程副本变量工具类
#### ThreadLocal类图
![https://note.youdao.com/yws/api/personal/file/WEB5ff6ccabc6d9ea2db3f3274a45e73eca?method=download&shareKey=aa0a0cee764a2090798d2bbffc76e2d1](https://note.youdao.com/yws/api/personal/file/WEB5ff6ccabc6d9ea2db3f3274a45e73eca?method=download&shareKey=aa0a0cee764a2090798d2bbffc76e2d1)
上图可以看出ThreadLocal类中通过ThreadLocalMap去存储,ThreadLocalMap中的存储结构为Entry数组.
#### ThreadLocal核心方法
1. set(T value)
```
public void set(T value) {
Thread t = Thread.currentThread();
ThreadLocalMap map = getMap(t);
if (map != null)
    map.set(this, value);
else
    createMap(t, value);
}
```
该方法用来保存当前线程的副本所对应的变量值;首先通过``Thread.currentThread()``获取当前线程,然后获取ThreadLocalMap,调用ThreadLocalMap的set方法,把值存进去,key为ThreadLocal,再看ThreadLocalMap的set方法的代码:
```
private void set(ThreadLocal<?> key, Object value) {

    // We don't use a fast path as with get() because it is at
    // least as common to use set() to create new entries as
    // it is to replace existing ones, in which case, a fast
    // path would fail more often than not.

    Entry[] tab = table;
    int len = tab.length;
    int i = key.threadLocalHashCode & (len-1);

    for (Entry e = tab[i];
         e != null;
         e = tab[i = nextIndex(i, len)]) {
        ThreadLocal<?> k = e.get();

        if (k == key) {
            e.value = value;
            return;
        }

        if (k == null) {
            replaceStaleEntry(key, value, i);
            return;
        }
    }

    tab[i] = new Entry(key, value);
    int sz = ++size;
    if (!cleanSomeSlots(i, sz) && sz >= threshold)
        rehash();
}
```
通过传入的ThreadLocal获取hashCode,用作数组Entry的下标,``tab[i]!=null``时,则获取数组下一个位置也比较简单,就是下i+1:
```
private static int nextIndex(int i, int len) {
    return ((i + 1 < len) ? i + 1 : 0);
}
```
2. get()
```
public T get() {
Thread t = Thread.currentThread();
ThreadLocalMap map = getMap(t);
if (map != null) {
    ThreadLocalMap.Entry e = map.getEntry(this);
    if (e != null) {
        @SuppressWarnings("unchecked")
        T result = (T)e.value;
        return result;
    }
}
return setInitialValue();
}
```
get方法获取比较简单,通过当前线程获取到ThreadLocalMap,然后再获取Entry,就可以获取到变量了.
3. remove()
```
public void remove() {
 ThreadLocalMap m = getMap(Thread.currentThread());
 if (m != null)
     m.remove(this);
}
```
remove方法用于移除当前线程的副本所对应的变量值,remove方法源码:
```
private void remove(ThreadLocal<?> key) {
    Entry[] tab = table;
    int len = tab.length;
    int i = key.threadLocalHashCode & (len-1);
    for (Entry e = tab[i];
         e != null;
         e = tab[i = nextIndex(i, len)]) {
        if (e.get() == key) {
            e.clear();
            expungeStaleEntry(i);
            return;
        }
    }
}
```
Entry调用了clear方法,用于清除该对象,继续跟进去,发现调用的clear方法是Reference的方法,Entry实现了WeakReference.关于ThreadLocal内存泄漏的问题指Entry是弱引用,当ThreadLocal没有被外部对象引用时,发生GC时会回收Entry,但是Entry中保存的值不会被回收,这个值随着该ThreadLocal线程一直存活着,占用内存,导致内存泄漏,解决的方法就是使用完ThreadLocal调用remove方法,清除变量值.

参考:
[https://www.jianshu.com/p/98b68c97df9b](https://www.jianshu.com/p/98b68c97df9b)
