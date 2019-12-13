**Item 31: Avoid default capture modes**

1.  捕捉临时变量的引用，当临时变量失效时，就变成了空悬指针。问题就是临时变量的lifetime和 lambda的lifetime不一致。

   ```c++
   using FilterContainer = std::vector<std::function<bool(int)>>;
   FilterContainer filters;
   void adDivisorFilter()
   {
       auto calc1 = computeSomeValue1();
       auto calc2 = computeSomeValue2();
       
       auto divisor = computeDivisor(calc1,calc2);
       filters.emplace_back(
           [&](int value) {return value % divisor == 0;} // ref to divisor will dangle
       );
   }
   ```

   通过值捕捉的话，可以正常运行。

   ``` c++ 
   #include<iostream>
   #include<functional>
   #include<vector>
   
   using namespace std;
   using filters = std::vector<std::function<int()>>;
   filters filt;
   
   void test1()
   {
       int a = 1;
       filt.emplace_back(
           [=]() {return a;}
       );
   }
   
   void test2()
   {
       int a = 2;
       filt.emplace_back(
           [=]() { return a;}
       );
   }
   
   int main()
   {
       test1();
       test2();
       for(auto func : filt)
       {
           std::cout << func() << std::endl;
       }
       return 0;
   }
   ```

   2 .  成员变量如何被lambda表达式捕获？
   
   lambda只能捕获非static本地变量，成员变量不在其范围内。

         ```
class Widget {
public:
    void addFilter() const;
private:
    int divisor = 2;
};

void Widget::addFilter() const 
{
    filt.emplace_back(
        [divisor] {
            return divisor;
        } 
    );
}

/*  当lambda表达式为 [=] { return divisor;} 时可以。
*   而当lambda表达式为[divisor] {return divisor;} 时 clang 编译的错误提示为:
*	`this` cannot be implicitly captured in this context
*
*/
         ```

由上面的例子可以看出，当捕获为 =时，其实我们是捕获了this指针，通过this指针才能访问成员变量。而当捕获this指针时，又可能引发第一个问题。可以的方式为:

```c++
void Widget::addFilter() const
{
  auto divisorCopy = divisor;
  filters.emplace_back(
   [divisorCopy](){ return divisorCopy;}
  );
}
// c++ 14
void Widget::addFilter() const
{
	filters.emplace_back(
		[divisor = divisor]()
		{ return divisor;}
	);
}
```

全局变量和static变量不需要捕获也可以在内部使用。

lambda表达式为将捕获变量存储到函数内部的一个普通函数。

---

**Item 32 ：Use init capture to move objects into closures**

例子如下:

```c++
std::unique_ptr<int> pw = make_unique<int>(123);
auto f = [pw = std::move(pw)] { std::cout << *pw << std::endl;};
f();
```

init capture 在 c++ 14得到支持，所以如果想在c++11中实现类似的效果，可以用如下的方式:

```c++
std::unique_ptr<int> pw = make_unique<int>(123);
    auto func = std::bind(
        [](std::unique_ptr<int>& pw) {
            std::cout << *pw << std::endl;
        } ,std::move(pw));
    func(pw)
```



**Item 33: use decltype on auto&& parameters to std::forward them**

```c++
auto f = [](auto x) { return func(normalize(x));};
// the closure class's function call operator looks like this
class SomeCompilerGaneratedClassName {
public:
    template<typename T>
    auto operator()(T x) const
    {
        return func(normalize(x));
    }
};
```

```c++
auto f = [](auto&& x)
{ return func(normalize(std::forward<???>(x)));};
// 泛化lambda如果要支持forward完美转发的话，类型应该填什么，x可以传入左值，右值
```

```c++
auto f =
 [](auto&& param)
 {
 	return 
 		func(normalize(std::forward<decltype(param)>(param)));
 };

auto f = 
   [](auto&& ... params)
{
    return 
        func(normalize(std::forward<decltype(params)>(params)...));
}
```



**Item34: Prefer lambdas to std::bind**

lambdas更易读。

```c++
// 在调用setAlarm过后一个半小时alarm 闹钟
auto setSoundL = 
	[](Sound s)
	{
		using namespace std::chrono;
		using namespace std::literals;
		setAlarm(steady_clock::now() + 1h, s, 30s);	
	};

// same function in bind
using namespace std::chrono;
using namespace std::literals;
using namespace std::placeholders;

auto setSoundB = std::bind(setAlarm,steady_clock::now() + 1h, _1, 30s);
```

以上的bind形式，`_1`显得优先魔幻，我们需要知道这个参数代表的意义。而且上述bind中，`steady_clock::now() + 1h`是调用bind函数过后一个小时，而非调用setAlarm后一个小时。

为了延缓参数的evaluation，需要在bind里面内嵌一个bind

```c++
auto setSoundB = 
    	std::bind(setAlarm,
                 	std::bind(std::plus<>(),steady_clock::now(),1h),
                    _1, 30s);
```

例如setAlarm有多个重载函数，那么std::bind绑定setAlarm时会编译出错。而lambda可以正常应对。而且大部分lambda表达式可以被inline。

std::bind如果需要传引用的话，需要调用std::ref ，没有lambda那么直观。

通过bind绑定多态函数对象:

```c++
class polymorphic 
{
public:
template<typename T>
void operator()(T data)
{
    std::cout << data << std::endl;
}
};
polymorphic test;
auto func = std::bind(test,_1);
```



**Item35 : Prefer task-based programming to thread-based.**

​	   一般来说, `std::async`比`std::thread`更易于使用，且`std::async`可以获取返回值，而且当方法抛出异常时，使用`std::async`的程序不会被terminated。

​		而**thread-based programming**需要对线程耗尽，负载均衡进行管理。

​		c++ thread库比较简陋，没有提供线程优先级和调度策略的方法，可以利用 `native_handle`成员方法来调用平台特定的方法。



---

**Item 36: Specify std:launch::async if asynchronicity is essential.**

`std::async`的默认launch策略没有采用`async`或者`defered`中的任何一种, 允许同步或者异步的运行。甚至其可能都没有执行。

当launch策略为deferred时，调用`wait_for`或者`wait_until`将会设置share_state为`std::launch::deferred`

```c++
auto fut = std::async(std::launch::deferred,f);
while(fut.wait_for(100ms) != std::future_statue::ready) 
{
    // loop forever
}
```

可以将launch策略进行封装一下：

```c++
template<typename F, typename ... Ts>
inline auto reallyAsync(F&& f, Ts&& ... params)
{
    return std::async(std::launch::async,std::forward<F>(f),std::forward<Ts>(params)...);
}
```

---

**Item 37: Make std::threads unjoinable on all paths.**

>unjoinable std::thread objects include:
>
>**Default-constructed std::threads.** Such std::threads have no function to execute.
>
>**std::thread objects that have been moved from.**
>
>**std::thread that have been joined or been detached.**

