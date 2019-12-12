**async的一个坑**

```c++
#include<future>
#include<iostream>
#include<unistd.h>

void testsleep()
{
    std::cout << "testsleep" << std::endl;
    sleep(10);
    std::cout << "testsleep OK" << std::endl;
}

void testAsync()
{
    std::cout << "testAsync" << std::endl;
    //std::future<void> f2 = std::async(std::launch::async,testsleep); // 1
    std::async(std::launch::async,testsleep);    // 2
    std::cout << "testAsync OK" << std::endl;
}

int main()
{
    testAsync();
    return 0;
}
/* 当使用2语句的时候，打印结果为
*	testAsync
*	testsleep
*	testsleep OK
*	testAsync OK
*
* 当使用1语句的时候，打印结果为
*	testAsync
*	testAsync OK
*	testsleep
*	testsleep OK
*/
```

当使用2语句的时候，我们可以看到结果是同步的，因为`async`的文档上有这么一段话:

>If the `std::future` obtained from `std::async` is not moved from or bound to a reference, the destructor of the [std::future](https://en.cppreference.com/w/cpp/thread/future) will block at the end of the full expression until the asynchronous operation completes, essentially making code such as the following synchronous:

`async`在其内部内建有std::future的局部变量，而如果没有将`async`的future返回值存储到局部变量中，那么直到异步操作完成，`std::future`的析构函数都会导致`async`线程阻塞，导致其行为类似于同步的一样。

而使用1语句的时候就完全是异步的了。所以以下两者并不等同：

```c++
std::thread([]
 {
     //blablabla
 }).detach();
std::async([]
    {
      // blabla           
    }
);

```

如果没有设置`std::launch::async` 和 `std::launch::defered`, 那么`async`函数的行为是未定义的。

`volatile` 变量禁止编译器对其修饰的变量进行优化。



----

**`DCLP`(双重锁定检查模式的)风险**

1. 为什么单例模式是非线性安全的？

2. ` DCLP`是如何处理这个问题的？

3. 为什么`DCLP`在单处理器和多处理器架构下都可能失效？

4. 为什么我们很难为这个问题找到简便的解决办法？

   ```c++
   // singleton.h
   class Singleton{
   public:
   	static Singleton* instance();
   	...
   private:
   	static Singleton* pInstance;
   }
   
   // singleton.cpp
   Singleton* Singleton::pInstance = nullptr
   Singleton* Singleton::instance() {
       if(pInstance == 0)
       {
           pInstance = new Singleton;
       }
       return pInstance;
   }
   ```

   加锁的问题在于，其实只需要在初始化的时候才需要锁，而之后进入此函数付出的锁的代价都是不必要的。

   `DCLP`的经典代码：

   ```c++
   Singleton* Singleton::instance() {
       if(pInstance == 0)
       {
           Lock lock;
           if(pInstance == 0) {
               pInstance = new Singleton;
           }
       }
       return pInstance;
   }
   ```

   `DCLP`的指令执行顺序：

   `pInstance = new Singleton;`

   这条语句实际做了三件事情：

   第一步： 为`Singleton`对象分配一片内存。

   第二步： 构造一个`Singleton`对象，存入已分配的内存区

   第三步：将`pInstance`指向这篇内存区.

   编译器有时会交换步骤2和步骤3的执行顺序，那么当`pInstance != null`的情况下，有可能还是没有完成`Singleton`对象的创建。

   c++11引入了`std::call_once`来解决这个问题。

   ```c++
   class Singleton
   {
   public:
   	static Singleton& GetInstance() {
   		static std::Once_flag s_flag;
   		std::call_once(s,flag,[&](){
   			instance_.reset(new Singleon);
   		});
   		return *instance_;
   	}
   	~Singleton() = default;
   private:
   	Singleton() = default;
   	Singleton(const Singleton&) = delete;
   	Singleton& operator=(const Singleton&) = delete;
   	static std::unique_ptr<Singleton> instance_;
   };
   ```

   ----

   `std::future`可以用来获取异步任务的结果，因此可以把它当成一种简单的线程间同步的手段。`std:future`通常由以下`provider`创建:

   1. `std::async` 函数
   2. `std::promise::get_future` 函数
   3.  `std::packaged_task::get_future`函数

   ```c++
   #include<iostream>
   #include<future>
   #include<thread>
   int main()
   {
       std::packaged_task<int()> task([]{return 7;});
       std::future<int> f1 = task.get_future();
       std::thread t(std::move(task));
   
       std::future<int> f2 = std::async(std::launch::async,[]{return 8;});
   
       std::promise<int> p;
       std::future<int> f3 = p.get_future();
       std::thread([&p]{ p.set_value_at_thread_exit(9);}).detach();
   
       std::cout << "Waiting..." << std::flush;
       f1.wait();
       f2.wait();
       f3.wait();
       std::cout << "Done!\nResults are: "  << f1.get() << ' ' << f2.get() << ' ' << f3.get() << '\n';
       t.join();
       return 0;
   }
   ```
	
	lambda
   ```c++
   []  // 未定义变量，试图在Lambda内使用任何外部变量都是错误的。
   [x,&y]  // x按值捕获，y按引用捕获
[&] // 用到的任何外部变量都隐式按引用捕获
   [-]  // 用到的任何外部变量都按值捕获
[&,x]	// x显示地按值捕获，其他变量按引用捕获
   [=,&z] // z按引用捕获，其他变量按值捕获
   ```
   
   
   
   