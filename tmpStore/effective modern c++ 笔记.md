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

```c++
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

```c++
class ThreadRAII
{
public:
    enum class DtorAction { join,detach};
    ThreadRAII(std::thread&& t, DtorAction a): action(a),t(std::move(t))
    {}
    ~ThreadRAII()
    {
        if(t.joinable())
        {
        	if(action == DctorAction::join)
        	{
        		t.join();
        	}
        	else
         	{
             	t.detach();
         	}
        }
    }
    ThreadRAII(ThreadRAII&&) = default;
    ThreadRAII& operator=(ThreadRAII&&) = default;
    std::thread& get() {return t;}
private:
 	DtorAction action;
    std::thread t;
};

```

注意事项：

1.  `DctorAction`的初始化在`std::thread`之前，因为`std::thread`一旦初始化完成，就可能马上运行，而此时可能`DctorAction`还没有初始化完成。
2.  可能会担心析构的时候，在判断完`t.joinable()`后，另外一个线程改变了它的状态。但这是不可能的，因为仅有通过调用成员方法能改变线程的状态。而在调用`join(),detach(),move()`之后，该线程马上进入析构状态，而此时其他线程不能在其上调用成员方法。

---

**Item 38 : Be aware of varying thread handle destructor behavior**

​	  异步编程中，caller和callee通过future这一**communications channel**来传递数据，通常的手段是通过  `std::promsise`对象来进行。那么callee产生的对象保存在哪里？

​	   如果保存在callee中，那么当callee结束时，结果肯定会被销毁，不能通过`std::future::get()`来获取结果。如果保存在caller中，那么`std::future`有可能用来创建`std::shared_future`对象，将callee结果的所有权从`std::future`转移到`std::shared_future`中。那么callee结果在最初`std::future`被销毁后依然存在。所以它储存在一个叫 `shared state`的`heap-based object`中。

>The destructor for the last future referring to a shared state for a non-deferred task launched via std::async blocks until the task completes.

---

**Item 39: Consider void futures for one-shot event communication.**	

​	有两个线程, 一个是producer,一个是consumer。现在的情境是需要producer生产完资源，再通知consumer线程进行任务。可以采用条件变量，但问题是：

1.  如果producer在consumer线程wait之前就发出信号，那么consumer线程将永远错过这个信号。

2.  虚假唤醒的问题。consumer线程可能没有办法检测是否条件成功了。

另一种解决办法是利用atomic变量:

```c++
std::atomic<bool> flag(false);
// tell reacting task
flag = true;
// prepare to react
while(!flag)
```

唯一的问题是 reacting task在分给它的时间片里面一直在做无意义的空转，消耗CPU资源。

可以用`void future`来解决这个问题 。 它是有`one-shot`（一次性）的限制的。

```c++
std::promise<void> p;           // promise for communications channel
p.set_value();					// tell reacting task
p.get_future().wait();  		// wait on future    react to event
```

假设你想要在创造一个线程之后，但在运行它线程方法之前挂起这个线程, 可以用如下的线程：

```c++
std::promise<void> p;
void react();                        // func for reacting task
void detect()
{
	std::thread t([]
                  {
                     p.get_future().wait();
                     react();
                  });
    p.set_value();
    t.join();
}
```

---

**Item 40: Use std::atomic for concurrency, volatile for special memory**

>Once a std::atomic object has been constructed, operations on it behave as if they were inside a mutex-protected critical section, but the operations are generally implemented using special machine instructions that are more efficient than would be the case if a mutex were employed.
>
>**volatile**: In a nutshell, it's for telling compilers that they're dealing with memory that doesn't behave normally.

普通内存的读写有如下的特性：如果你在一个内存的区域写了个值，却从未读取它，然后又第二次对其赋值，那么第一个赋值的行为将被清除。

特殊内存中最常见的就是内存映射I/O，对内存的读写也是一种输入输出，可以控制外部诸如传感器，雷达的行为。

所以, `volatile`的意思是告诉编译器，不要在这段内存上进行任何的优化， 它指向的是特殊的内存。

---

**Item 1 : Understand template type deduction.**

**case 1 : ParamType is a Reference or Pointer, but not a Universal Reference**

1.  如果`expr`是引用类型，那么忽略掉引用部分。

2.  `expr`的类型相对于ParamType的匹配之处来决定T的类型。

**Example:**

```c++
template<typename T>
void f(T& param);
int x = 27;
const int cx = x;
const int& rx = x;
f(x);		//  T int ; paramType  int&
f(cx);		//  T  const int ; paramType const int&
f(rx);		//  T  const int ; paramType const int&
// 传引用时将保留其本身的const属性。
```

带有右值参数的函数只接受右值，但类型推断没有这方面的限制。

```c++
template<typename T>
void f(const T& param);
int x = 27;
const int cx = x;
const int& rx = x;
f(x);         // T : int   ; paramType: const int&
f(cx);		  // T : int   ; paramType: const int&
f(rx);	      // T : int   ; paramType: const int&
```

**Case 2 :  ParamType is a Universal Reference**

万能引用通常被声明为 `T&&` 。

1.  如果`expr`是左值，那么T 和 ParamType的类型都将被推断为左值引用。

2.   如果`expr`是右值，那么Case 1的规则将被应用。

```c++
template<typename T>
void f(T&& param);
int x = 27;
const int cx = x;
const int& rx = x;
f(x);           // T: int& ; paramType: int&
f(cx);		    // T: const int& ; paramType: const int&
f(rx);          // T: const int& ; paramType: const int&
f(27);			// T: int  ; paramType: int&& 
```

**Case 3: ParamType is neither a pointer nor a reference**

1.  如果`expr`是引用，忽略引用部分。
2.   如果`expr`是const 和 volatile， 也要忽略。因为是传值，即使修改也是在新的副本上进行修改。

```c++
template<typename T>
void f(T param);
int x = 27;
const int cx = x;
const int& rx = x;
f(x);                   // both int
f(cx);					// both int
f(rx);					// both int

const char* const ptr = "Fun with pointers";   //ptr is const pointer to const object
f(ptr);                      // pass arg of type const char* const 
```

`void myFunc(int param[]);` 和 `void myFunc(int* param);`是等效的。

```c++
const char name[] = "J.p.Briggs";
const char* ptrToName = name;
template<typename T>
void f(T param);
f(name);			  // T 被推断为 const char*

template<typename T>
void f1(T& param);		// T 被推断为 const char[13], paramType推断为 const char(&)[13]
f1(name);
```

所以在template中可以指明参数为array。

```c++
template<typename T, std::size_t N>
constexpr std::size_t arraySize(T (&)[N]) noexcept
{
   return N;
}
```

---

**Item 2:  Understand auto type dedution.**

auto 推断和template推断几乎等同。

```c++
auto x  = 27;
const auto cx = x;
const auto& rx = x;

// 可等同于
template<typename T>
void func_for_x(T param);
func_for_x(27);

template<typename T>
void func_for_cx(const T param);
func_for_cx(x);

template<typename T>
void func_for_rx(const T& param);
func_for_rx(x);


auto&& uref1 = x;       // x是左值int , 所以 uref1类型为 int&
auto&& uref2 = cx;      //  cx是左值const int, 所以 uref2类型为const int&
auto&& uref3 = 27;		// 27是右值， 所以 uref3 类型为 int&&

const char name[] = "R.N.Briggs";       // 类型为 const char[13]
auto arr1 = name;						// arr1's type is const char*
auto& arr2 = name;                      // arr2's type is const char (&)[13]

void someFunc(int ,double);         
auto func1 = someFunc;                  // func1's type is void(*)(int,double)
auto& func2 = someFunc;					// func2's type is void(&)(int,double)
```

**例外:**

```c++
auto x1 = 27;					// type is int , value is 27
auto x2(27);					// ditto
auto x3 = {27};				    // type is std::initializer_list<int> value is {27}
auto x4{27};                    // ditto
```

当用统一初始化声明变量时，即用{}来声明变量时，推断类型为`std::initializer_list`.

```c++
auto createInitList()
{
  return {1,2,3};         // error : can't deduce type for {1,2,3}
}
```



---

**Item 3 : Understand decltype.**

``` c++
template<typename Container,typename Index>
auto authAndAccess(Container& c, Index i) -> decltype(c[i])
{ 
   authenticateUser();
   return c[i];
}

// 如果写成 decltype(param) test(T param)
// 那么就会提示错误，因为此时 param 此时还是 undeclared

//
auto authAndAccess(Container& c, Index i)
{
    return c[i];
}
authAndAccess(d,5) = 10;    // error, 不能对右值赋值

// 可看成  auto ret = c[i];    那么 auto的推断类型为int, 而c[i]的类型为int&

//--------------------------------------------------------------
// 可用 decltype(auto) 来进行赋值
Widget w;
const Widget& cw = w;
auto myWidget1 = cw;          // myWidget1的类型为Widget
decltype(auto) myWidget2 = cw;   // myWidget2的类型是 const Widget&
```

如果我们需要传入的参数无论为左值还是右值均可，而返回值根据传入参数的类型而变化的话，可以用完美转发：

```c++
template<typename Container, typename Index>
decltype(auto) authAndAccess(Container&& c, Index i)
{
    authenticateUser();
    return std::forward<Container>(c)[i];
}
```

```c++
decltype(auto) f2()
{
	int x = 0;
	return (x);
}
// (x)返回的是本地变量的引用。
```

除了变量名之外的类型为`T`的左值表达式，`decltype`推断的类型总是`T&`。

---

**Item 4 :  Know how to view deduced types.**

1.   通过IDE 

2.   利用编译器来进行诊断。

   ```c++
   template<typename T>               // 仅仅有TD的声明，没有实现
   class TD;  
   TD<decltype(x)> xType;
   TD<decltype(y)> yType;
   
   // 然后编译器提示错误，从错误中，我们可以看到x,y的类型
   /* deduceTest.cpp:24:21: error: implicit instantiation of undefined template 'TD<int>'
       TD<decltype(x)> xType;
                       ^
   deduceTest.cpp:13:7: note: template is declared here
   class TD;
         ^
   */
   ```

   3.   运行时的输出。

      可以利用boost库

      ```c++
      #include<boost/type_index.hpp>
      template<typename T>
      void f(const T& param)
      {
         using std::cout;
         using boost::typeindex::type_id_with_cvr;
         cout <<　"T = "
             	<< type_id_with_cvr<T>().pretty_name()
              << '\n';
         cout << "param = "
              << type_id_with_cvr<decltype(param)>().pretty_name()
              << '\n';
      }
      ```

      ---

      **Item 5: Prefer auto to explicit type declarations**

      `auto`变量必须被初始化。

      `std::function`和`auto`声明的`lambada`函数，如果都关联同一个函数，`auto-declared object`总是比较快和比较小。

      ```c++
      auto derefUPLess = 
      	[](const std::unique_ptr<Widget>& p1,
      	   const std::unique_ptr<Widget>& p2)
      	   { return *p1 < *p2; }
      ```

      ```c++
      std::unordered_map<std::string,int> m;
      for(const std::pair<std::string,int>& p : m)
      { 
      }
      /* unordered_map的key值是const的，所以在hash table中的变量为 std::pair<const   std::string,int>, 而声明的变量为std::pair<string,int>。所以运行过程中会创建一个临时变量，然后将引用P绑定到这个变量上。
       */
      ```

      auto 在重构代码的时候可能有用，比如将返回值从int改为double, 仅仅需要改动`return`语句就可以了。

---

**Item 6: Use the explicitly typed initializer idiom when auto deduces undesired types**

>std::vector::operator[] returns for every type except bool. Instead, it returns an object of type std::vector<bool>::reference.

因为vector中每个bool值用1位来表示，而`vector<T>`的`[]`操作符用来返回一个`T&`值,而c++禁止对bit位的引用。

```c++
std::vector<bool> features(const Widget& w);
bool highPriority = features(w)[5];  // 从std::vector<bool>::reference隐式转化为bool
auto highPriority = features(w)[5];	 // 类型为std::vector<bool>::reference
```

auto的问题在于有些使用了代理类，例如`shared_ptr`对原始指针进行了包装，但`shared_ptr`比较明显地使用了代理类，而其他则不那么明显。

```c++
Matrix sum = m1 + m2 + m3 + m4
// 为了高效的计算，m1 + m2 的返回值类型可能为 sum<Matrix,Matrix>, 所以类似的sum<sum<sum<Matrix,Matrix>,Matrix>,Matrix>, 最后在=的时候隐式转换为 Matrix
```

```c++
double calcEpsilon();           // return tolerance value
float ep = calcEpsilon();       // implicitly convert   double->float
auto ep = static_cast<float>(calcEpsilon());
```



+ 不可见的代理类会导致auto推断出错误的类型。
+  显示类型转化可以强制auto推断出你想要的类型。

---

**Item 7 : Distinguish between () and {} when creating objects.**

```c++
Widget w1;          // call default constructor
Widget w2 = w1;     // not an assignment; calls copy ctor
w1 = w2;            // an assignment; calls copy operator=
```

大括号也可以用来初始化非静态成员变量的默认值。

```c++
class Widget {
private:
	int x{0};				  // fine, x's default value is 0
	int y = 0;			      // fine
	int z(0);                 // error
};

// uncopyable objects can be initialized using braces or parentheses
std::atomic<int> ai1{0};      // fine
std::atomic<int> ai2(0);      // fine
std::atomic<int> ai3 = 0;     // error!
```

braced initialization禁止隐式的缩窄转换。

```c++
double x,y,z;
int sum1{ x + y + z};
// most vexing parse
Widget w2();     // a function returns Widget or initialize an object w2
// braced initialization can forbid it 
Widget w3{};
```

如果有多个重载函数，其中有一个重载参数为`std::initializer_list`的话，braced initialization优先使用`std::initializer_list`的。甚至通常的拷贝构造和移动构造都会被`std::initializer_list`所劫持。

```c++
class Widget {
public:
    Widget(int i,bool b);             
    Widget(int i,double b);
    Widget(std::initializer_list<long double> il);
    operator float() const;
};

Widget w8{std::move(w4)};        // calls std::initializer_list ctor
```

有个边缘情况是，如果变量初始化为空的大括号，而且构造函数中包含默认构造函数和`std::initializer_list`构造函数，那么它代表没有参数，还是空的`std::initializer_list`, 也就是说调用哪个构造函数？ 规则是你将调用默认构造函数。如果你想要调用空的`std::initializer_list`的话，那么请用如下的方式：

```c++
Widget w4({});
Widget w5{{}};
```

---

**Item 8: Prefer nullptr to 0 and NULL.**

```c++
void f(int);        // three overloads of f
void f(bool);
void f(void*);

f(0);
f(NULL);           // 我们本意是想调用f(void*),但是因为NULL被定义为0,所以它实际上调用的是f(int)
```

nullptr shines especially brightly when  templates enter the picture.

---

**Item 9: Prefer alias declarations to typedefs**





---



**Item 23: Understand std::move and std::forward.**

>**Move semantics**  makes it possible for compilers to replace expensive copying operations with less expensive moves.