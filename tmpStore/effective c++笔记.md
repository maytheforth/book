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
2.  使“操作const对象”  成为可能。

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



---

**条款十三：以对象管理资源**

1.  获得资源后立刻放进管理对象内。此刻的管理对象类似于auto_ptr的智能指针。

2.  管理对象(managing object) 运用析构函数确保资源被释放。

   boost::scoped_array 和 boost::shared_classes 是针对数组而设计的、类似于auto_ptr那样的classes。

   >为防止资源泄露，请使用RAII对象，它们在构造函数中获得资源并在析构函数中释放资源。
   >
   >两个常被使用的RAII classes分别时tr1::shared_ptr和auto_ptr, 若选择auto_ptr, 复制动作会使它指向null。



---

**条款十四：在资源管理类中小心coping行为**

   例如虽然可以利用RAII管理锁，但复制锁仍然是不合理的，所以我们需要禁止复制。

   可以对底层资源祭出“引用计数法(reference-count)” , 但是shard_ptr的缺省行为是“当引用次数为0时删除其所指物”，那不是我们所要的行为。当我们用上一个mutex, 我们想要做的释放动作是锁定而非删除。shared_ptr允许指定“删除器(deleter)”, 当引用计数为0时被调用。代码如下：

```c++
class Lock
{
public:
    explicit Lock(Mutex* pm): mutexPtr(pm,unlock)  // 以unlock为删除器
    {
         lock(nutexPtr.get());
    }
private:
    std::tr1::shared_ptr<Mutex> mutexPtr;
};
```

>复制RAII对象必须一并赋值它所管理的资源，所以资源的copying行为决定RAII对象的copying行为。
>
>普遍而常见的RAII class copying行为是：抑制copying / 施行引用计数法(reference counting), 不过其他行为也都可能被实现。



---

**条款十五：在资源管理类中提供对原始资源的访问**

>APIs 往往要求访问原始资源(raw resources), 所以每一个RAII class应该提供一个“取得其所管理之资源” 的办法。
>
>对原始资源的访问可能精油显示转换或隐式转换。一般而言显示转换比较安全，但隐式转换对客户比较方便。



---

**条款十六：成对使用new和 delete时要采取相同形式。(Use the same form in corresponding uses of new and delete)**

>如果你在new表达式中使用[], 必须在相应的delete表达式中也使用[] 。 如果你在new表达式中不使用[], 一定不要在相应的delete表达式中使用[].

---

**条款十七：以独立语句将newed对象置入智能指针**

例子：

​    一个函数用来在某动态分配所得的Widget上进行某些带有优先权的处理：

   `int priority();`

   `void processWidget(std::tr1::shared_ptr<Widget>pw,int priority);`

现在进行如下调用：

`processWidget(std::tr1::shared_ptr<Widget>(new Widget),priority())`

事实上，两个参数的执行顺序是未知的， 如果是以下的顺序：

1. 执行 "new Widget".    2. 调用priority     3. 调用tr1::shared_ptr构造函数

如果对priority的调用导致异常，在此情况下“new Widget”返回的指针会遗失，可能会造成资源泄露。

我们可以如下操作：

```c++
std::str1::shared_ptr<Widget> pw(new Widget); //在单独语句内衣智能指针存储newed所得对象
processWidget(pw,priority());
```

>以独立语句将newed对象存储于(置入) 智能指针内，如果不这样做，一旦异常被抛出，有可能导致难以察觉的资源泄露。

---



**条款十八： 让接口容易被正确使用，不容易被误用**

```c++
class Data
{
public:
   Data(int month, int day, int year);
};
```

客户端可能错误的调用 Data d(30,3,1995);   可以对传入参数做简单的类型封装来达到效果。

```c++
struct Day
{
  explicit Day(int d): val(d) {}
  int val;
};

class Data
{
public:
   Date(const Month& m,const Day& d,const Year& y);
};
Date d(Month(3),Day(30),Year(1995));
```

对月份的限定其值，可以如下做到：

```c++
class Month
{
public:
    static Month Jan() { reutrn Month(1);}
    static Month Feb() { return Month(2);}
private:
    explicit Month(int m);
}
```



"cross-DLL problem" , 问题发生于“对象在动态连接程序库(DLL)中被new创建，却在另一个DLL中被delete销毁”。tr1::shared_ptr没有这个问题，因为它缺省的删除器是来自“tr1::shared_ptr” 诞生所在的那个DLL的delete. 



**Tips:**

>好的接口很容易被正确使用，不容易被误用。你应该在你的所有接口中 努力达成这些性质。
>
>“促进正确使用” 的办法包括接口的一致性，以及与内置类型的行为兼容。
>
>“阻止误用”的办法包括建立新类型、限制类型上的操作，束缚对象值，以及消除客户的资源管理责任。
>
>tr1::shared_ptr支持定制型删除器，这可防范DLL问题，可被用来自动解除互斥锁等等。



---



**条款十九： 设计class犹如设计type**

必须考虑如下问题：

新type的对象应该如何被创建和销毁？             决定构造函数和析构函数。

对象的初始化和对象的赋值应该有什么样的差别？    决定构造函数和赋值操作符的差别。

新type的对象如果被passed by value(以值传递)，意味着什么？

什么是新type的“合法值”？    

你的新type需要配合某个继承图系(inheritance graph) 吗?

你的新type需要什么样的转换？        是否允许类型T1被隐式转换为类型T2之物

什么样的操作符和函数对此新type而言是合理的？    声明哪些函数，哪些是member函数    

什么样的标准函数必须驳回？   禁止使用

谁该取用新type的成员？        决定哪个成员是public,protected和private

什么是新type的“未声明接口” (undeclared interface) ?     它对效率、异常安全性以及资源运用提供何种保证？

你的新type有多么一般化？      是否需要设计模板类

你真的需要一个新type吗？

---

**条款二十： 宁以pass-by-reference-to-const 替换 pass-by-value**

>尽量以pass-by-reference-to-const 替换 pass-by-value。 前者通常比较高效，并可避免切割问题(slicing problem)
>
>以上规则并不适用于内置类型，以及STL的迭代器和函数对象。对它们而言，pass-by-value往往比较妥当。

切割问题如下:

```c++
void printNameAndDsisplay(Window w)
{
   std::cout << w.name();
   w.display();   
}
```

函数参数是一个基类，即使我们调用时传进去一个子类，然而w.display() 仍然是基类的display.



---



**条款二十一： 必须返回对象时，别妄想返回其reference.**

>绝不要返回pointer或reference指向一个local stack对象，或返回reference指向一个heap-allocated对象，或返回pointer 或 reference 指向一个local static 对象而有可能同时需要多个这样的对象。



---



**条款二十二：将成员变量声明为private**

​        不隐藏成员变量，你很快就会发现，即使拥有class原始码，改变任何public事物的能力还是极端受到束缚，因为那会破坏太多客户吗。

​        从封装的角度观之，其实只有两种访问权限: private 和其他.

> 切记将成员变量声明为private. 这可赋予客户访问数据的一致性、可细微划分访问控制、允诺约束条件获得保证，并提供class作者以充分的实现弹性。
>
>protected并不比public 更加封装性。

---



**条款二十三： 宁以non-member、non-friend 替换member函数。**

越多函数可访问成员变量，则其数据的封装性就越低。

```c++
class WebBrowser
{
public:
    void clearCache();
    void clearHistory();
    void removeCookies();
};
// 以下哪种比较好
class WebBrowser{
  public:
      void clearEverything();
};

void clearBrowser(WebBrowser& wb)
{
    wb.clearCache();
    wb.clearHistory();
    wb.removeCookies();
}

```

​     导致较大封装性的是non-member noon-friend函数，因为它并不增加“能够访问class类之private成分” 的函数数量。

​     将所有便利函数放在多个头文件内但隶属于同一个命名空间，意味着客户可以轻松扩展这一组便利函数。他们需要做的就是添加更多non-member non-friend函数到此命名空间内。

---



**条款二十四： 若所有参数皆需类型转换，请为此采用non-member函数。**

```c++
class Rational
{
public:
   const Rational operator* ( const Rational& rhs) const;
};

Rational oneHalf(1,2);
Rational result = oneHalf * 2;     // 正确
result = 2 * oneHalf;            // 错误
```

oneHalf * 2中，2发生了隐式转换，转换成了class Rational .

而，只有当参数被列于参数列(parameter list) 内，这个参数隐式转换的合格参与者。 这也是为什么第一次调用成功，而第二次失败，因为第一个调用伴随一个放在参数列内的参数，第二次则否。

因此需要将member function 转换为 non-member function

```c++
class Rational
{
};
const Rational operator* (const Rational& lhs,const Rational& rhs)
{
   return Rational(lhs.numerator() * rhs.numerator(), lhs.denominator() * rhs.denominator());
}
```

**Tips:**

>如果你需要为某个函数的所有参数（包括被this指针所指的那个隐喻参数）进行类型转换，那么这个函数必须是non-member.



---



**条款二十五： 考虑写出一个不抛异常的swap函数**

```c++
namespace WidgetStuff
{
   template<typename T>
   class Widget {};
   
   template<typename T>
   void swap(Widget<T>& a, Widget<T>& b)
   {
     // 这会让编译器在std::swap和我们自定义的swap中做挑选。当然和Widget在同一命名空间内的swap
     // 优先级高。
      using std::swap;
      a.swap(b);
   }
}
```

**Tips:**

>当std::swap对你的类型效率不高时，提供一个swap成员函数，并确定这个函数不抛出异常。
>
>如果你提供一个member swap , 也该提供一个non-member swap 来调用前者。对于classes(而非templates),  也请特化std::swap.
>
>调用swap时应针对std::swap使用using 声明式，然后调用swap并且不带任何“命名空间资格修饰”。
>
>为“用户定义类型” 进行std templates全特化是好的，但千万不要尝试在std内加入某些对std而言全新的东西。



----

**条款二十六： 尽可能延后变量定义式的出现时间**

​      只要你定义了一个变量，且其带有构造函数和析构函数，那么即使变量没有被使用，仍然需要耗费这些成本。

​     例子如下：

```c++
std::string encryptPassword(const std::string& password)
{
   using namespace std;
   string encrypted;
   if(password.length() < MinimumPasswordLength)
   {
       throw logic_error("Password is too short");
   }
}
```

如果发生异常，则 encrypted变量就是声明了，而没有使用。

​      你不只应该延后变量的定义，知道非得使用该变量的前一刻为止，甚至应该尝试延后这份定义知道能够给它初值实参为止。

---

