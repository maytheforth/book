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

别名声明可用于模板，而`typedef`不行。



---



**Item 23: Understand std::move and std::forward.**

>**Move semantics**  makes it possible for compilers to replace expensive copying operations with less expensive moves.

`std::move`和`std::forward`没有产生任何可执行代码，他们仅仅是做了类型转换。`std::move`无条件将它的参数转化成右值，而`std::forward`只有当条件满足时才执行这个转化。

下面有一个`std::move`的样例实现:

```c++
template<typename T>
typename remove_reference<T>::type&&  move(T&& param)
{
    using ReturnType = typename remove_reference<T>::type&&;
    return static_cast<ReturnType>(param);
}
```

注意： 1.  如果你想要对一个对象做move操作，不要将其声明为`const`。 

​			  2.  `std::move`不仅不做移动操作，而且它也不保证会将对象类型转化成适宜移动的类型。

```c++
class Annotation {
public:
	explicit Annotation(const std::string text): value(std::move(test)) {}
private:
    std::string value;
};


class string {
public:
   	string(const string& rhs);  //1
    string(string&& rhs);
}
/*
move函数将test的类型转化为了一个const std::string的右值。因为string的move构造函数只支持非const变量的move操作，所以string调用了第一个左值的构造函数，所以尽管使用了move，依然有拷贝操作。

*/
```
> Neither std::move nor std::forward do anything at runtime.
---

**Item 24: Distinguish universal references from rvalue references.**

万能引用和右值引用的形式都类似于`T&&` 。万能引用通常都出现在有类型推断的场合。

```c++
template<typename T>
void test(T&& param);    // a universal reference

auto&& var2 = var1;      // a universal reference

template<typename T>
void f(std::vector<T>&& param);      // param is an rvalue reference.
```

一个引用如果想成为万能引用，类型推断是必要的，但却不是充足条件。引用的声明形式必须正确，必须精确的类似于`T&&`。

```c++
auto timeFuncInvocation = 
  [](auto&& func,auto&& ... params)
  {
  	start timer;
    std::forward<decltype(func)>(func)(
        std::forward<decltype(params)>(params)...
    );
    stop timer and record elapsed time;
  }
```



---

**Item 25: Use std::move on rvalue references, std::forward on universal references**

```c++
class Widget{
public:
	template<typename T>
	void setName(T&& newName)
	{
		name = std::move(newName);
	}
private:
	std::string name;
	std::shared_ptr<SomeDataStructure> p;
};

auto n = getWidgetName();         // n is local variable
w.setName(n);                     // moves n into w!  n's value now unknown;
```

所以当参数为万能引用的时候，不应该用`std::move`。

任何的函数内部，对形参的直接使用，都是按照左值进行的。

如果某个函数返回值而非引用的话，可以返回右值引用来减少开销：

```c++
Matrix operator+(Matrix&& lhs,const Matrix& rhs)
{
    lhs += rhs;
    return std::move(lhs);
}
```

即使可能返回的类型不支持`moving`操作，将它转成右值也不会有什么后遗症，因为这个右值会被拷贝到拷贝构造函数中，进行拷贝构造。

**RVO和std::move的关系**

[RVO VS std::move](https://www.ibm.com/developerworks/community/blogs/5894415f-be62-4bc0-81c5-3956e82276f3/entry/RVO_V_S_std_move?lang=en)

RVO是一种编译器优化的技术，它要把返回的局部变量直接构造在返回区域的技术, 用来减少拷贝的消耗。

```c++
class BigObject {
public:
	BigObject() {
	    cout << "constructor " << endl;
	}
    ~BigObject() {
        cout <<　"destructor." << endl;
    }
    BigObject(const BigObject&) {
        cout << "copy constructor." << endl;
    }
    BigObject(BigObject&&)
    {
        cout << "move constructor" << endl;
    }
};

BigObject foo() {
    BigObject localObj;
    return localObj;
}
BigObject foo1(int n) {
    BigObject localObj,anotherLocalObj;
    if(n > 2)
    {
        return localObj;
    }
    else
    {
        return anotherLoalObj;
    }
}

int main()
{
    BigObject obj = foo();
    BigObject obj1 = fool(1);
    return 0;
}
```

如果有了if-else语句以后，编译器就不知道返回区域要放哪个值了。

而如果方法改为:

```c++
BigObject foo() {
    BigObject localObj;
    return std::move(localObj);
}
```

编译器将不会触发RVO操作。因为触发RVO的要求是返回语句的类型与定义的方法返回值类型一致。而此时定义的返回值类型为`BigObject`，真正返回值的类型为`BigObject&&`,所以没有触发RVO, 但会触发拷贝构造函数。

c++ 标准规定，如果RVO条件满足的话，要么`copy elision`会发生要么隐式地调用`std::move`。所以显示地调用`std::move`是不必须的。

---

**Item 26: Avoid overloading on universal references.**

```c++
template<typename T>
void logAndAdd(T&& name);
void logAndAdd(int index);

short nameIndex;
logAndAdd(nameIndex);      // 它实际上匹配的是万能引用。
```

万能引用比较贪婪，它可以匹配绝大多数的参数。如果给一个除了`int`以外的整数形参数，例如(`std::size_t`,`short`,`long`), 那么将会匹配万能引用，而非`int`型重载。

```c++
class Person{
public:
    template<typename T>
    explict Person(T&& n)
    : name(std::forward<T>(n)){}
    Person(const Person& rhs);
    Person(Person&& rhs);
}

Person p("Nancy");
auto cloneOfP(p);        // compile error
/*
 如果调用copy ctor, 需要在Person p上加上const来进行匹配，而调用万能引用无需这种限制。所以万能引用是一个更好的匹配，调用万能引用而非copy ctor.
*/
```

完美转发构造函数尤其有问题，它比 non-const左值构造函数能获得更好的匹配，而且会劫持派生类的copy ctor 和 move ctor. 

---

**Item 27: Familiarize yourself with alternatives to overloading on universal references.**

**use tag dispatch**

```c++
template<typename T>
void logAndAdd(T&& name)
{
  logAndAddImpl(
  	 std::forward<T>(name),
     // 因为有些可能传入的是引用，导致is_integral返回false_type,需要去除引用
  	 std::is_integral<typename std::remove_reference<T>::type>()
  );
}

template<typename T>
void logAndAddImpl(T&& name,std::false_type)
{
    names.emplace(std::forward<T>(name));
}

std::string nameFromIdx(int idx);
void logAndAddImpl(int idx,std::true_type)
{
    logAddAdd(nameFromIdx(idx));
}
```

在上述代码中，使用`std::true_type`和`std::false_type`来当做tags区分调用不同的方法。



**Constraining templates that take universal references**

接下来的例子，我们仅仅在参数类型不为Person的时候才完美转发。

>std::decay<T>::type is the same as T,  except that references and cv-qualifiers(i.e., const or volatile qualifiers) are removed  .

参数不与Person相同的表达式为:

!std::is_same<Person, typename std::decay<T>::type>::value

所以代码如下:

```c++
class Person {
public:
	template<typename T, typename = typename std::enable_if<!std::is_same<Person,
		typename std::decay<T>::type
		>::type
		>
		explicit Person(T&& n);
};
```

**enable_if:**

```c++
// template<bool Cond, class T = void> struct enable_if;
// Enable type if condition if met
// The type T is enable as member type enable_if::type if Cond is true.
// otherwise, enable_if::type is not defined.
// example
#include<type_traits>
#include<iostream>

template<typename T>
typename std::enable_if<std::is_integral<T>::value,bool>::type 
is_odd(T i) { return bool(i%2);}

template<typename T, typename = typename std::enable_if<std::is_integral<T>::value>::type>
bool is_even(T i) { return !bool(i%2);}

int main()
{
    short int i = 1;
    std::cout << std::boolalpha;
    std::cout << "i is odd: " << is_odd(i) << std::endl;
    std::cout << "i is even: " << is_even(i) << std::endl;
}
```

​        在某些复杂的系统中，可能万能引用不只传递了一次，而且在参数的层层转发中，只有当到了最后一层，才会匹配出错，由此提示的出错信息就不是那么直观了。

​		可以使用`static_assert`配合`is_constructible`来检测使用能将某一类型转化成另一类型。

```c++
explici Person(T&& n): name(std::forward<T>(n))
{
   static_assert(
   	std::is_constructible<std::string,T>::value,
   	"Parameter n can't be used to construct a std::string"
   );
}
```

---

**Item 28: Understand  reference collapsing.**

c++在声明变量的时候不可以定义引用的引用。如 `auto& &rx = x` 不被允许。但是在将参数类型代入`template`进行替换的时候，可能会出现引用的引用。例如:

```c++
template<typename T>
void test(T&& param);
int a = 21;
int b = &a;
test(b);
```

之前提及，此时T的类型推断为`int&`，代入模板则是`int& &&`。而编译器在处理这个问题的时候，会把引用的引用最终折叠到单个引用，这就是引用折叠。引用折叠的规则为:  如果有左值引用存在，那么结果为左值引用。否则都为右值引用。

```c++
& && -> &                     & & -> &
&& & -> &				      && && -> &&
```

引用折叠出现在四种场景中：

1.  模板实例化。

2.  auto变量的类型生成。

   ```c++
   auto&& a = 5;  //  a的类型为int&&
   auto& b = a; // --> int& && b   -->  int& b 
   ```

3.   `typedef`和别名声明的使用过程中。

      ```c++
template<typename T>
class Widget{
public:
   typedef T&& RvalueRefToT;
};
Widget<int&> w;
typedef int& && RvalueRefToT;
typedef int& RvalueRefToT;
    ```

4.  `decltype`的使用过程中。



---

**Item 29: Assume that move operations are not persent, not cheap, and not used**

​       不是所有的移动操作都很便宜，需要查看该对象的内部构造。就像对于容器来说，大部分的容器内容储存在堆上，而容器中仅仅保留了指向该堆区域的指针。所以`move`操作很便宜，只需要更新指针就可以了，移动操作仅仅需要常量时间。

​	   但`std::array`对象的元素都储存在对象的内部，所以移动操作需要耗费线性时间，不是那么便宜。

​       另一方面，`std::string `   offers constant-time moves and linear-time copies .  听起来似乎移动操作更便宜。但是许多`string`的实现使用了一种叫`small string optimization(SSO)` 的技术。容量不超过15个字符的短字符串直接储存内容于`string`的内部，而非堆上。此时移动操作并不便宜。

​       有些容器的操作需要确保强异常安全，而`move`操作没有声明`noexcept`，所以`move`操作不可使用。

----

**Item 30: Familiarize yourself with perfect forwarding failure cases.**

```c++
template<typename... Ts>
void fwd(Ts&&... params)
{
   f(std::forward<Ts>(params)...);
}
```

完美转发失败的情况有：

1.  **编译器不能推断出参数的类型**，例如参数为{1,2,3}这种形式。

   如果参数的模板类型没有显示声明`std::initializer_list`的情况下，c++标准禁止推断这种形式。

```c++
#include<iostream>
#include<vector>
using namespace std;

void f(const vector<int>& v)
{
    std::cout << "in f" << std::endl;
}

template<typename T>
void fwd(T&& param)
{
    f(std::forward<T>(param));
}

int main()
{
    /* 
    使用auto时，li被推断为std::initializer_list,可以完美转发
    auto li = {1,2,3};
    fwd(li);
    */
    // 下面形式的参数,c++标准禁止推断它的类型。
    fwd({1,2,3});
    return 0;
}
```

2.  **0或者NULL被当做null pointers传入模板**。

   3. **仅仅声明的整型静态const成员函数**。

      ```c++
      class Widget {
      public:
      	static const std::size_t MinVals = 28;    // MinVal's declaration
      };
      std::vector<int> widgetData;
      widgetData.reserve(Widget::MinVals);
      ```

      在上述的代码中，`MinVal`仅仅声明了，却没有在类外进行定义。编译器会进行类似预处理的操作，在所有使用到`MinVals`的地方，用28来代替。那么一旦对`Widget::MinVals`进行取地址的操作，会导致`MinVals`去寻找定义，从而链接失败。那么在以下的代码中：

      ```c++
      void f(std::size_t val);
      f(Widget::MinVals);			  // find, treated as f(28)
      fwd(Widget::MinVals);         // error! shouldn't link
      ```

      完美转发是通过万能引用来转发参数的，万能引用本质上是指针，所以如上调用时会出错。
      
      4. **函数参数和模板**
      
         ```c++
         #include<iostream>
         #include<vector>
         using namespace std;
         
         void test(int val)
         {
             std::cout << "in test int" << std::endl;
         }
         
         void test(double val)
         {
             std::cout << "in test double" << std::endl;
         }
         
         void f(void (*fp)(int))
         {
             std::cout << "in f " << std::endl;
         }
         
         template<typename T>
         void fwd(T&& param)
         {
             f(std::forward<T>(param));
         }
         
         int main()
         {
             //f(test);
             fwd(test);
             return 0;
         }
         ```
      
         函数f的声明让编译器知道它需要哪个重载函数。但函数fwd的参数是个万能引用，它对需要的参数一无所知，所以不知道需要哪个重载函数，编译出错。

​                             可以人为地指定函数和函数模板的类型。

```c++
using Func = void (*)(int);
Func funcPtr = test;

void f(void (*fp)(int))
{
    std::cout << "in f " << std::endl;
}

template<typename T>
void fwd(T&& param)
{
    f(std::forward<T>(param));
}

int main()
{
    //f(test);
    fwd(funcPtr);
    return 0;
}
```

5. **位域**

   c++标准规定一个非const的引用无法引用一个位域字段。可以通过拷贝位域的值再进行完美转发。

---

**Item 18: Use std::unique_ptr for exclusive-ownership resource management.**

unique_ptr自带deleter的例子如下:

```c++
#include<iostream>
#include<memory>

using namespace std;

/*
*	 unique_ptr<int[]> p(new int[3]());
*
*
*/

auto intDeleter = [](int* p)
{
    std::cout << "in special delete " << std::endl;
    delete p; 
};

int main()
{
    unique_ptr<int,decltype(intDeleter)> p{new int(5) , intDeleter};
    std::cout << *p << std::endl;
    return 0;
}
```

---

**Item 19: Use std::shared_ptr for shared-ownership resource management.**

修改引用计数的操作是原子的，所以虽然引用计数通常只有一个字节的大小，但是修改它的代价却很昂贵。

`std::shared_ptr`的`move ctor`因为并没有修改引用计数，所以它比`copy ctor`更快和更便宜。

`std::shared_ptr`和 `std::unique_ptr`类似，可以自定义`dtor` ,但是略微不同。`unique_ptr`的`dtor`是其智能指针的一部分，会改变智能指针的大小，而 `std::shared_ptr`却不是。可以有如下的行为：

```c++
auto customDeleter1 = [](Widget* pw) {};
auto customDeleter2 = [](Widget* pw) {};
std::shared_ptr<Widget> pw1(new Widget,customDeleter1);
std::shared_ptr<Widget> pw2(new Widget,customDeleter2);
// 虽然有着不同的deleters,但是被视为同一类型
std::vector<std::shared_ptr<Widget>> vpw{pw1,pw2};
```

`std::shared_ptr`结构如下所示:

```c++
/*
	   std::shared_ptr<T>
	   ---------------------|               ------------|
	   |  Ptr to T	        |-------------->| T Object  |  
	   |--------------------|               | -----------
	   |ptr to control block|
       |--------------------
                |                              Control Block
                |--------------------------->|-----------------|
                                             | Reference Count |
                                             |-----------------|
                                             |  Weak Count     |
                                             |-----------------|
                                             |  Other Data     |
                                             | (custom deleter,|
                                             |  allocator,etc.)|
                                             |-----------------|
*/
```

一个对象的`control block`是指向这个对象的第一个`std::shared_ptr`所创建的。创建`control block`的规则如下：

>+ std::make_shared always creates a control block.
>
>+ A control block is created when a std::shared_ptr is constructed from a unique-ownership pointer( i.e.  a std::unique_ptr or std::auto_ptr).
>+ When a std::shared_ptr constructor is called with a raw pointer , it creates a control block.

所以从原始指针构造一个以上的`shared_ptr`会导致不可预知的后果，因为有多个`control block`控制着同一个原始指针。

```c++
std::vector<std::shared_ptr<Widget>> processedWidgets;
class Widget: public std::enable_shared_from_this<Widget> {
 public:
    void process();
};
void Widget::process()
{
    processedWidgets.emplace_back(shared_from_this());
}
```

`shared_from_this`查看指向当前对象的`control block`，然后创建一个指向当前`control block`的`std::shared_ptr` 。文中提到`shared_ptr`没有针对数组的操作。如果我们需要用类似于`vector<std::shared_ptr<int>>`的形式，那么容器中保存中`shared_ptr`，意味着shared_ptr不会得到释放，陈硕专门讲过这个问题。

---

**Item 20: Use std::weak_ptr for std::shared_ptr  -- like pointers that can dangle**

`weak_ptr`可用于观察指针指向的对象是否已经被摧毁。

`weak_ptr`不是一个能单独存在的只能指针，他是`shared_ptr`的附庸。用法如下:

```c++
auto spw = std::make_shared<Widget>();   
std::weak_ptr<Widget> wpw(spw);       
spw = nullptr;
if(wpw.expired())   // std::weak_ptrs that dangle are said to have expired
{
}

// The std::shared_ptr is null if the std::weak_ptr has expired
std::shared_ptr<Widget> spw1 = wpw.lock();
// if wpw's expired, throw std::bad_weak_ptr
std::shared_ptr<Widget> spw3(wpw);
```

观察者模式下也用`std::weak_ptr`。

>In strictly hierarchal data structures such as trees, child nodes are typically owned only by their parents. When a parent node is destroyed, its child nodes should be destroyed,too . Links from parents to children are thus generally best represented by std::unique_ptrs.  Back-links from children to parents can be safely implemented as raw pointers, because a child node should never have a lifetime longer than its parent.

`std::weak_ptr对象的大小与`std::shared_ptr`的大小相同，他们使用相同的`control blocks`。

---

**Item 21:  Prefer std::make_unique and std::make_shared to direct use of new**

因为`make`方法是异常安全的。

```c++
void processWidget(std::shared_ptr<Widget> spw, int priority);
// 如果以如下的方式进行调用
processWidget(std::shared_ptr<Widget>(new Widget), computePriority());
/* 上述的调用方式中，仅仅要求(new Widget)在 shared_ptr之前运行，而其他的运行顺序没有确定
   所以可能会有如下的方式：
   1. new Widget
   2. computePriority()
   3. std::shared_ptr的构造函数。
   当运行computePriority时出现异常，那么就会有内存泄漏的问题出现。
   std::shared_ptr<Widget> spw(new Widget); 会导致两次的内存申请，一次给Widget，一次给control block.
   而 auto spw = std::make_shared<Widget>(); 只会有一次的内存申请。它一次性就申请好了足够Widget和control block使用的内存。性能上更加优化。
*/
```

但是如果智能指针要用到自定义的`dctor`的话，就不能用make方法。

make方法还有一种限制是:

```c++
auto upv = std::make_unique<std::vector<int>>(10,20);
// 到底是10个元素，每个值20的vector, 还是两个元素分别为10,20的vector
// 这取决于完美转发的时候，是传递(10,20),  还是传递{10,20}。
// make方法传递的是(10,20)
```

所以如果我们需要`initializer_list`方式的声明的话，就必须用new的方式进行构造。

​        因为shared_ptr和weak_ptr共用一个control block, 所以当shared_ptr的引用计数为0时，申请的对象被摧毁，但是control block和这个对象占用的空间并没有被释放(如果有weak_ptr引用这个control block的话)， 因为 the same chunk of dynamically allocated memory contains both。所以完全的内存回收是等到最后一个shared_ptr和weak_ptr被摧毁才进行。

​	    所以如果shared_ptr关联的对象占据了很大的内存空间，想尽早释放的话，那么应该用new的方式进行构造。但是正如前面所说，new的方式不是异常安全的。可以利用如下的方式。

```c++
std::shared_ptr<Widget> spw(new Widget, cusDel);
processWidget(spw, computePriority());

// 高效的方式可以如下
processWidget(std::move(spw),computePriority());
```



---

**Item 22: When using the Pimpl Idiom, define special member functions in the implementation file. **

Pimpl Idiom指的是头文件和和实现分离(不仅仅是实现，还有private member/functions) , 避免修改了我无法访问的数据而需要重新编译。简易的实现如下:

```c++
// in header file
class widget{
public:
    widget();
    ~widget();
private:
    class impl;
    unique_ptr<impl> pimpl;
};

// in implementation file
class widget::impl {
    
};
widget::widget(): pimpl{new impl{}} {}
widget::~widget() {}
/*
widget::~widget() = default;       // same effect as above
*/
```

在widget的头文件内部定义  

`widget(widget&& rhs) = default;` 

`widget& operator=(widget&& rhs) = default;`

会导致编译出错。因为move操作要求在赋值之前，需要销毁 pImpl指向的对象，二者要求pImpl指向的是一个完整的对象。所以为了解决这个问题，只需要在该段代码生成的时候，pImpl指向的对象是完整的就行。所以只需在头文件里面定义，在cpp文件里面实现就可以了。

但是如果智能指针是shared_ptr，却完全不必管。因为对于std::unique_ptr，deleter是它的一部分，所以编译器可以优化它，生成执行时间更快的代码，但是由此的后果就是unique_ptr指向的对象必须是完整的，当编译器生成的特殊函数(dctor 和 move操作)被使用时。

---

**Item 10: Perfer scoped enums to unscoped enums.**

```c++
enum Color {black,white,red};
auto white = false;                // error! white already declared in this scope

enum class Color {black,white,red};
auto white = false;
Color c = Color::white;
```

enum的问题在于它内部的变量能隐式转换成数字类型，而且可以与浮点数进行比较。

而enum class是强类型的，不能进行隐式转化，也不能与其他类型进行比较。

​		 enum在c++98里面不能前置声明的原因是，enum在c++内有其一套潜在的实现方式，比如enum数较少时会用char型，较多时会选择更大的类型。为了让编译器能够极力地优化，编译器需要知道enum的声明，所以不能只定义不声明。而enum class支持前置声明，因此可以减少因enum的修改而重新编译的工作。

可以改写enum class 的 underlying type。

```c++
enum class Status;             //underlying type is int
enum class Status: std::uint32_t;

```

有一个地方enum更好用，那就是应对tuple时:

```c++
using UserInfo = std::tuple<std::string,std::string,std::size_t>;
UserInfo uInfo;

enum UserInfoFields {uiName, uiEmail, uiReputation};
auto val = std:get<uiEmail>(uInfo);    

// 换成 enum class
enum class UserInfoFields {uiName, uiEmail, uiReputation};
auto val = std::get<static_cast<std::size_t>(UserInfoFields::uiEmail)(uInfo);
```

