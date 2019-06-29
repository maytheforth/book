pass by value 调用copy构造函数，即 `Widget(const Widget& rhs); // copy构造函数` 构造临时变量。

STL标准模板库, 包含容器/迭代器/算法.



**条款一： 视c++为一个语言联邦 View c++ as a federation of languages.**

c++ 目前已经是一个同时支持过程形式(procedural)、 面向对象形式(object-oriented)、函数形式(functional)、泛型形式(generic)、元编程形式(metaprogramming)的语言。

c++的次语言有4个，分别为C 、Object-Oriented C++  、template C++ 、 STL 。

---

**条款二:  尽量以const, enum, inline 替换为 #define**

运用define定义的常量获得编译错误信息时，可能会带来困惑。

class专属常量，为了将常量的作用域scope限制于class内，必须让它成为class的一个成员，二为了确保此常量至多只有一份实体，必须让它成为一个static成员。

```c++
class GamePalyer
{
private:
    enum { NumTurns = 5};
    int scores[NumTurns];
};
```

enum hack 的行为比较接近于#define,而非const. 取一个enum的地址就不合法。

+ **对于单纯常量，最好以const对象或者enums替换 #defines**
+ **对于形式函数的宏(macros),最好改用inline函数替换 #defines**

---

**条款三：尽可能使用const ( Use const whenever possible)**

关键字const出现在星号左边，表示被指物是常量。出现在星号右边，表示指针自身是常量。

以下两者都是指向一个常量的（不变的）Widget对象。

```c++
void f1(const Widget* pw);
void f2(const widget* pw);    
```

iterator 和 const_iterator

const成员函数

1.  使class接口比较容易理解。
2.  是“操作const对象”  成为可能。

```c++
class TextBlock
{
public:
   const char& operator[](std::size_t position) const
   { return text[position];}
   char& operator[](std::size_t position)
   { return text[position];}
private:
    std::string text;
};
```

mutable变量可以在const成员函数内部修改。



​      在const和non-const成员函数中避免重复，该成员函数中可能进行了一系列复杂的操作，例如边界检验、检验数据完整性等等，仅仅是为了const对象能访问其成员函数，所以我们应该选择令其中一个调用另一个。

```c++
class TextBlock
{
public:
   const char& operator[](std::size_t position)
   {
       return text[position];
   }
   char& operator[](std::size_t position)
   {
      return 
        const_cast<char&>(static_cast(const TextBlock&)(*this)[position]);
   }
};
```



**Tips:**

1.   将某些东西声明为const 可帮助编译器侦测出错误用法。const 可被施加于任何作用域内的对象、函数参数、函数返回类型、成员函数本体。

2.    编译器强制实施bitwise constness, 但你编写程序时应该使用“概念上的常量性”。
3.    当const 和 non-const 成员函数有着实质等价的实现时，令non-const版本调用const版本可避免代码重复。

---



**条款四：确定对象被使用前已被先初始化**

c++规定，对象的成员变量的初始化动作发生在进入构造函数本体之前。

```
class ABEntry
{
 private:
   std::string theName;
   std::string theAddress;
 public:
    ABEntry(const std::string& name,const std::string& address);
};
ABEntry::ABEntry(const std::string& name,const std::string& address)
{
   theName = name;
   theAddress = address;
}
```

 上面代码首先调用default构造函数为theName,theAddress设初值，然后再对它们赋予新值。

class的成员变量总是以其声明次序被初始化，无论其成员初值列的顺序如何。

所谓static对象，其寿命从被构造出来直到程序结束为止。

c++对“定义于不同编译单元内的non-local static 对象” 的初始化次序并无明确定义。



---



**条款五：了解c++默默编写并调用哪些函数**

​        一个empty class, 编译器会为它声明一个copy构造函数，一个copy assignment操作符和一个析构函数。此外，编译器也会为你声明一个default构造函数。这些函数都是public 且 inline.

​        编译器产出的析构函数是个non-virtual, 除非这个类的基类自身声明有virtual 。

​        如果你打算在一个“内含reference成员” 的 class内支持赋值操作，你必须自己定义copy assignment操作符，面对“内含const成员” 的classes时，编译器的反应也一样。



---



**条款六： 若不想使用编译器自动生成的函数，就该明确拒绝( Explicitly desallow the use of compiler-generated functions you do not want)**

```c++
class HomeForSale
{
private：
   HomeForSale(const HomeForSale&);
   HomeForSale& operator= (const HomeForSale&);  // 仅有声明
};
```

如果将基类的拷贝构造函数和赋值构造函数声明为private，那么编译器将不会为子类构造这两个构造函数。

也可以利用Boost 的 noncopyable来实现。

>为驳回编译器自动提供的机能，可将相应的成员函数声明为private并且不予实现，使用向Uncopyable这样的base class 也是一种做法。



---



**条款七：为多态基类声明virtual析构函数**

当class不企图被当做base class, 令其析构函数为virtual往往是个馊主意。

虚函数表会将类的体积增大。

纯虚函数会导致抽象类，可以为你希望它成为抽象的那个class声明一个pure virtual析构函数。

```c++
class AWOV
{
public:
  virtual ~AWOV() = 0;
};
AWOV::~AWOV() {}        // pure virtual析构函数的定义
```



---

**条款八： 别让异常逃离析构函数**

> 析构函数绝对不要吐出异常。如果一个被析构函数调用的函数可能抛出异常，析构函数应该捕捉任何
>
>异常，然后吞下它们（不传播）或结束程序。
>
>如果客户需要对某个操作函数运行期间抛出的异常做出反应，那么class应该提供一个普通函数执行该操作。



---

**条款九：绝不在构造和析构过程中调用virtual函数。**

这样的调用不会给你带来预想的结果。

```c++
class Transaction
{
public:
   Transaction();
   virtual void logTransaction() const = 0;
};
Transaction::Transaction()
{
   logTransaction();
}
class BuyTransaction:public Transaction
{
public:
   virtual void logTransaction() const;
}
```

在base class构造期间，virtual函数不是virtual函数。

static类成员函数不能访问非static的类成员，只能访问static修饰的类成员。

可将logTransaction改为non-virtual调用，如下：

```c++
class BuyTransaction: public Transaction
{
public:
   BuyTransaction(parameters): Transaction(craeteLogString(parameters))
   {
   }
private:
   static std::string createLogString(parameters);
};
```



---

**条款十：令operator = 返回一个reference to *this**

---

**条款十一:  在 operator= 中处理 “自我赋值”**

```c++
Widget& Widget::operator=(const Widget& rhs)
{
   if(this = &rhs) return *this;
   delete pb;
   pb = new Bitmap(*rhs.pb);
   return *this;
}
```

如果"new Bitmap" 发生异常，Widget最终会持有一个指针指向一块被删除的Bitmap.

新的代码：

```c++
Widget& Widget::operator=(const Widget& rhs)
{
   Bitmap* pOrig = pb;
   pb = new Bitmap(*rhs.pb);
   delete pOrig;
   return *this;
}
```

就是申请内存成功之前，绝不把过去旧的内存删掉，宁愿先用临时变量保存过去的指针。

或者是

```c++
Widget& Widget::operator= ( const Widget& rhs)
{
   Widget temp(rhs);
   swap(temp);
   return *this;
}
```

**Tips:**

>确保当对象自我赋值时operator= 有良好行为，其中技术包括比较“来源对象” 和 “目标对象” 的地址、精心周到的语句顺序、以及copy-and-swap.
>
>确定任何函数如果操作一个以上的对象，而其中多个对象是同一个对象时，其行为仍然正确。



---

**条款十二：复制对象时勿忘其每一个成分**

>Copying函数应该确保复制“对象内的所有成员变量” 及“所有base class 成分”.
>
>不要尝试以某个copying函数来实现另一个copying函数，应该讲共同技能放进第三个函数中，并由两个copying函数共同调用。

```c++
PriorityCustomer::PriorityCustomer(const PriorityCustomer& rhs) : Customer(rhs), priority(rhs.priority)  // 调用base class的copy构造函数
{
    logCall("PriorityCustomer copy constructor");
}
PriorityCustomer& PriorityCustomer::operator=(const PriorityCustomer& rhs)
{
    Customer::operator=(rhs);   // 对base class成分进行赋值动作
    priority = rhs.priority;
    return *this;
}
```

