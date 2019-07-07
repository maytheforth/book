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



**条款二十七：尽量少做转型动作**

c++ 提供四种新式转型：

*const_cast<T> ( expression)*  :   用于对象的常量性转除

*dynamic_cast<T>(expression)*:   用来执行“安全向下转型”，用来决定某对象是否归属于继承体系中的某个类型。

*reinterpret_cast<T>(expression)*:  意图执行低级转型，实际动作可能取决于编译器。例如将pointer to int 转型为int.

*static_cast<T>(expression)*:  用来强迫隐式转换。

新式转型较受欢迎，原因是：第一 、它们很容易在代码中辨识出来。 第二、各转型动作的目标愈窄化，编译器愈可能诊断出错误的运用。

```c++
class Window{
public:
    virtual void onResize() {}
};
class SpecialWindow: public Window
{
public:
   virtual void onResize() {
      static_cast<Window>(*this).onResize();
   }
};
```

 以上代码调用的并不是当前对象上的函数，而是稍早转型动作所建立的一个“*this对象之base class成分”的暂时副本身上的onResize. 所以应该这么写：

```c++
class SpecialWindow:public Window
{
public:
   virtual void onResize() {
       Window::onResize();  //调用Window::onResize作用于*this身上
   }
};
```

**Tips:**

>尽量避免转型，特别是在注重效率的代码中避免dynamic_cast。如果有个设计需要转型动作，试着发展无需转型的替代设计。
>
>如果转型是必要的，试着将它隐藏于某个函数背后，客户随后可以调用该函数，而不需将转型放进他们自己的代码内。
>
>宁可使用c++-style转型，不要使用旧式转型，前者很容易辨识出来，而且也比较有着分门别类的执掌。

---



**条款二十八：避免返回handles指向对象内部成分**

​     成员变量的封装性最多只等于“返回其reference” 的函数的访问级别，如果函数传出了private变量的引用，那么它们实际上是public 。

>避免返回handles(包括references、指针、迭代器) 指向对象内部。遵守这个条款可增加封装性，帮助const成员函数的行为像个const ,并将发生“虚吊号码牌(dangling handles)” 的可能性降到最低。

---



**条款二十九： 为“异常安全” 而努力是值得的**

```c++
void PrettyMenu::changeBackground(std::istream& imgSrc)
{
   lock(&mutex);
   delete bgImage;
   ++imageChanges;
   bgImage = new Image(imgSrc);
   unlock(&mutex);
}
```

没有满足

1.  **不泄露任何资源**。 因为一旦 "new Image(imgSrc)" 导致异常，就没有释放锁。

2. **不允许数据败坏**。 如果 "new Image(imgSrc)" 抛出异常，bgImage就是指向一个已被删除的对象,imsgechanges也已被累加，而其实并没有新的图像被成功安装。



异常安全函数提供以下三个保证之一：

1. **基本承诺：** 如果异常被抛出，程序内的任何事物仍然保持在有效状态下。没有任何对象或数据结构会因此而败坏，所有对象都处于一种内部前后一致的状态。

2. **强烈保证：**  如果函数成功，就是完全成功，如果函数失败，程序会回复到“调用函数之前” 的状态。

3. **不抛掷保证**： 承诺绝不抛出异常，因为他们总是能完成它们原先承诺的功能。作用于内置类型身上的所有操作都提供nothrow保证。

 有个一般化的设计策略很典型地会导致强烈保证，很值得熟悉它。这个策略被称为copy and swap 。 原则很简单 : 为你打算修改的对象作出一份副本，然后在那副本上做一切必要修改，若有任何修改动作抛出异常，原对象扔保持未改变状态。成功后，再将修改过的那个副本和原对象在一个不抛出异常的操作中置换(swap)

```c++
struct PMImpl
{
   std::tr1::shared_ptr<Image> bgImage;
   int imageChanges;
};
clas PrettyMenu
{
 private:
    Mutex mutex;
    std::str1::shared_ptr<PMImpl> pImpl;
}
void PrettyMenu::changeBackground(std::istream& imgSrc)
{
   using std::swap;
   Lock ml(&mutex);
   std::st1::shared_ptr<PMImpl> pNew(new PMImpl(*pImpl));
   pNew->bgImage.reset(new Image(imgSrc));
   ++pNew->imageChanges;
   swap(pImpl,pNew);
}
```

**Tips**

>异常安全函数： 即使发生异常也不会泄露资源或允许任何数据结构败坏。这样的函数区分为三种可能的保证：基本型、强烈型、不抛异常型。
>
>“强烈保证” 往往能够以copy-and-swap 实现出来，但“强烈保证”并非对所有函数都可实现或具备现实意义。
>
> 函数提供的“异常安全保证” 通常最高只等于其所调用之各个函数的“异常安全保证”中的最弱者。



---

**条款三十：透彻了解 inlining的里里外外**

​    inline是编译器的一个申请，而不是强制命令。这项申请可以隐喻提出，也可以明确提出。隐喻方式是将函数定义于class定义式内：

```c++
class Person
{
public:
   int age() const {return theAge;}   // 一个隐喻的inline申请
private:
    int theAge;
}
```

 inlining在大多数c++程序中是编译器行为。

所有对virtual函数的调用都会使inlining落空。因为virtual意味着“等待，知道运行期才确定调用哪个函数” ，而inline意味着"执行前，现将调用动作替换为被调用函数本身。"

inline函数无法随着程序库升级而升级，一旦inline函数改变，所有用到inline函数的客户端程序必须重新编译。

>将大多数inlining 限制在小型、被频繁调用的函数身上。这可使日后的调试过程和二进制升级更容易，也可使潜在的代码膨胀问题最小，使程序的速度提升机会最大化。
>
>不要只因为function templates出现在头文件，就将它们声明为inline.
>



---



**条款三十一：将文件间的编译依存关系降至最低。**

前置声明每一件东西的第二个困难是，编译器必须在编译期间知道对象的大小。

​      持有某个自定义类Person，假如修改了某个private成分，那么使用Person的所有文件必须重新编译，因为自定义类Person的分配大小改变了。如果使用对象指针加前置声明的话，就可以减少编译的依赖性。这种设计常被称为 pimpl idiom 。

   ```c++
#include<string>
#include<memory>
class PersonImpl;        // Person实现类的前置声明
class Date;
class Address;
class Person
{
public:
    Person(const std::string& name,const Date& birthday,const Address& addr);
    std::string name() const;
    std::string birthDate() const;
    std::string address() const;
private:
    std::tr1::shared_ptr<PersonImpl> pImpl;
};
   ```

以“声明的依存性” 替换“定义的依存性”。 设计策略：

+ 如果使用object references 或 object pointers 可以完成任务，就不要使用objects.
+  如果能够，尽量以class声明式替换class定义式。注意，当你声明一个函数而它用到某个class时，你并不需要该class的定义；纵使函数以by value方式传递该类型的参数(或返回值) 依然。

+  为声明式和定义式提供不同的头文件。为了上述准则，需要两个头文件，一个用于声明式，一个用于定义式。

​    如果Date的客户如果希望声明today 和 clearAppointments, 他们应该#include适当的、内含声明式的头文件：

```c++
#include "datefwd.h"   // 这个头文件内声明(但未定义)class Date.
Date today();             
void clearAppointments(Date d); 
```

像Person这样使用pimpl idiom的classes,被称为Handle classes.  下面是Person两个成员函数的实现：

```c++
#include "Person.h"
#include "PersonImpl.h"
Person::Person(const std::sting& name, const Date& birthday, const Addresss& addr) : pImpl(new PersonImpl(name,birthday,addr))
{}

std::string Person::name() const
{
   return pImpl->name();
}
```

**Tips:**

>支持“编译依存性最小化”的一般构想是：相依于声明式，不要相依于定义式。基于此构想的两个手段是Handle classes 和 Interface classes.
>
>程序库头文件应该以“完全且仅有声明式” 的形式存在。这种做法不论是否涉及templates都适用。



---

**条款三十二：确定你的public继承塑模出 is-a 关系**

>"public继承" 意味is-a .  适用于base classes身上的每一件事情也一定适用于derived classes身上，因为每一个derived class对象也都是一个base class对象。



---

**条款三十三：避免遮掩继承而来的名称**

   即使base classes和 derived classes内的函数有不同的参数类型，而且不论函数时virtual或non-virtual一体适用，base classes 的同名函数会被derived classes的掩盖。

​    可以使用using声明式达成目标：

```c++
class Base
{
private:
   int x;
public:
   virtual void mf1() = 0;
   virtual void mf1(int);
   virtual void mf2();
   void  mf3();
   void  mf3(double);
};
class Derived:public Base
{
public:
    using Base::mf1; // 让Base class 内名为mf1和mf3的所有东西在Derived 作用域内可见
    using Base::mf3;
    virtual void mf1();
    void mf3();
    void mf4();
};
```

**Tips:**

>derived classes内的名称会遮掩base classes内的名称。在public继承下从来没有人希望如此。
>
>为了让被这样的名称再见天日，可使用using 声明式或转交函数。



---



**条款三十四： 区分接口继承和实现继承**

pure virtual函数的意义是 “你必须提供一个这样的函数，但我不干涉你怎么实现它”

impure virutal 函数的意义是“你必须提供它，但如果你不想自己写一个，就可以用缺省版本”

​    问题是，有时候我们不想用缺省版本，但忘记了提供这个函数，引发错误。可以用如下代码解决：

   ```c++
class Airplane
{
public:
virtual void fly(const Ariport& destination) = 0;
protected:
   void defaultFly(const Airport& destination);
};
void Airplane::defaultFly(const Airport& destination)
{

}

class ModelA: public Airplane
{
public:
    virtual void fly(const Airport& destination)
    { defaultFly(destination);}
};
   ```

将接口和缺省实现分开。

pure virtual 函数必须在derived classes中重新声明，但它们也可以拥有自己的实现。

```c++
class Airplane
{
public:
   virtual void fly(const Airport* destination) = 0;
};
void Airplane::fly(const Airport& destination)  // pure virtual的缺省实现
{
    
}

class ModelA: public Airplane
{
public:
   virtual void fly(const Airport& destination)
   {  Airplane::fly(destination);}
}
```

声明non-virtual 函数的目的是为了令derived classes 继承函数的接口及一份强制性实现。

一个典型的程序有80%的执行时间花费在20%的代码身上。

**Tips:**

>接口继承和实现继承不同。在public继承之下，derived classes 总是继承 base class 的接口。
>
>pure virtual 函数只具体指定接口继承。
>
>简朴的(非纯) impure virtual 函数具体指定接口继承及缺省实现继承。
>
>non-virtual 函数集体指定接口继承以及强制性实现继承。



---

**条款三十五 : 考虑virtual函数以外的其他选择**

借由Non-Virtual Interface手法实现 Template Method模式。

​    “令客户通过public non-virtual 成员函数间接调用private virtual函数”，称为 non-virtual interface (NVI) 手法 ， 就是所谓的 Template Method设计模式。

 ```c++
class GameCharacter
{
public:
   int healthValue() const
   {
      // 事前工作
      int retVal = doHealthValue();
      // 事后工作
      return retVal;
   }
private:
    virtual int doHealthValue() const
    {
        
    }
};
 ```



借由Function Pointers 实现Strategy模式

```c++
class GameCharacter;
int defaultHeadthCalc(const GameCharacter& gc);
class GameCharacter
{
public:
    typedef int (*HealthCalcFunc)(const GameCharacter&);
    explicit GameCharacter(HealthCalcFunc hcf = defaultHealthCalc)
    : healthFunc(hcf)
    {}
    int healthValue() const
    { return healthFunc(*this); }
};
```



借由 tr1::function 完成  strategy模式

`typedef std::tr1::function<int (const GameCharacter&)> HealthCalcFunc;`

**Tips**

>​     virtual函数的替代方案包括NVI手法及 Strategy设计模式的多种形式。NVI手法自身是一个特殊形式的 Template Method 设计模式。
>
>​    将机能从成员函数移到class外部函数，带来的一个缺点是，非成员函数无法访问class的non-public成员。
>
>​    tr1::function对象的行为就像一般函数指针。这样的对象可接纳“与给定之目标签名式兼容” 的所有可调用物。



---



**条款三十六：绝不重新定义继承而来的non-virtual函数**

​      那么何不考虑修改当初的设计，将函数设计成为virtual函数，而且在基类、子类的指针下，同一对象同一方法会呈现两种不同的结果，令人困惑。



----



**条款三十七： 绝不重新定义继承而来的缺省参数值**

​      如果缺省参数值是动态绑定，编译器就必须有某种办法在运行期为virtual函数决定适当的参数缺省值。这比目前实行的“在编译期决定” 的机制更慢而且更复杂。 所以编译器选取基类的默认参数值。

​      应采用 NVI的设计

```c++
class Shape
{
public:
   enum ShapeColor {Red,Green,Blue};
   void draw(ShapeColor color = Red) const
   {
      doDraw(color);
   }
private:
   virtual void doDraw(ShapeColor color) const = 0;     // 真正的工作
};

class Rectangel:public Shape
{
public:
private:
    virtual void doDraw(ShapeColor color)  const;    //注意，不需指定缺省参数值。
}
```

**Tips**

> 绝对不要重新定义一个继承而来的缺省参数值，因为缺省参数值都是静态绑定，而virtual函数 , 你唯一应该覆写的东西，却是动态绑定。



---

**条款三十八：通过复合塑模出has-a  或 “根据某物实现出”**

>复合(composition) 的意义和 public 继承完全不同。
>
>在应用域，复合意味has-a 。 在实现域，复合意味着is-implemented-in-terms-of.



---



**条款三十九：明智而审慎地使用private继承**

如果classes之间的继承关系是private,编译器不会自动将一个derived class对象转换为一个base class对象。这和public继承的情况不同。第二条规则是，由private base class 继承而来的所有成员，在derived  class中都会变成private属性，纵使它们在base class 中原本是protected 或 public属性。

大小为零之独立(非附属) 对象，通常c++官方勒令默默安插一个char到空对象内。这个约束不适用于derived class对象内的base class成分。

```c++
class Empty {}；
class HoldAnInt {
private:
   int x;
   Empty e;
};
```

空对象因为c++官方要求，内含一个char的空间，而由于齐位的要求，HoldAnInt对象中可能增加的是一个int的空间。

而private继承则几乎确定没有额外的空间：

```c++
class HoldsAnInt: private Empty
{
private:
    int x;
};
```

现实中的 EBO(empty base optimization:空白基类最优化) , 往往内含typedefs,enums, static成员变量，或non-virtual函数，在STL 中有广泛的实践。

所处理的class不带任何数据时，这样的classes没有non-static成员变量，没有virtual函数，也没有virtual base classes , 于是这种所谓的empty classes对象不使用任何空间，因为没有任何隶属对象的数据需要存储。

---



**条款四十：明智而审慎地使用多重继承**

多重继承下，两个base class 有重名的函数，即使一个是private ，一个是public, 但它们的匹配程度是相同的，没有所谓的最佳匹配。

​    为了避免继承得来的成员变量重复，可以采用virtual继承。

```c++
class File {};
class InputFile: virtual public File {};
class OutputFile: virtual public File {};
class IOFile: public InputFile,public OutputFile {};
```

 使用virtual 继承的classes所产生的对象往往比使用non-virtual继承的体积大，访问virtual base classes的成员变量时，也比访问non-virtual base classes的成员变量速度慢。

​    virtual base的初始化责任是由继承体系中的最底层(most derived) class负责。

`class CPerson: public IPerson, private PersonInfo`

>多重继承比单一继承复杂，它会导致新的歧义性，以及对virtual继承的需要。
>
>virtual继承会增加大小、速度、初始化(及赋值) 复杂度等等成本。如果virtual base classes不带任何数据，将是最具使用价值的情况。
>
>多重继承的确有正当用途。其中一个情节涉及"public继承某个Interface class" 和 “private继承某个协助实现的class”  的两相组合。



---



**条款四十一： 了解隐式接口和编译器多态**

“哪一个重载函数该被重载” (发生在编译期) 和 “哪一个virtual函数该被绑定”(发生在运行期)之间的差异。

>classes和 templates 都支持接口(interfaces) 和 多态 (polymorphism) 。
>
>对classes而言接口是显式的，以函数签名为中心。多态则是通过virtual函数发生于运行期。
>
>对template参数而言，接口是隐式的(implicit), 奠基于有效表达式。多态则通过template具现化和函数重载解析发生于编译期。

---



**条款四十二：了解typename的双重意义**

template内出现的名称如果相依于某个template参数，称之为从属名称。否则称之为非从属名称。

嵌套从属名称

```c++
template<typename c >
void print2nd(const C& container)
{
   C::const_iterator* x;
}
```

以上代码可以解释为两个变量相乘，所以可能有歧义。

c++ 规定： 如果解析器在template中遭遇一个嵌套从属名称，它便假设这名称不是个类型，除非你告诉它是。

所以 `C:const_iterator iter(container.begin())` 被假设为非类型，需要你告诉它是。

```c++
template<typename C>
void print2nd(cosnt C& container)
{
   if(container.size() >= 2)
   {
      typename C::const_iterator iter(constainer.begin());
   }
}
```

但typename 不可以出现在 base classes list内的嵌套从属类型名称之前，也不可在member initialization list(成员初值列) 中作为base class修饰符。

```c++
template<typename T>
class Derived: public Base<T>::Nested {
public:
  explicit Derived(int x) : Base<T>::Nested(x)
  {
     typename Base<T>::Nested temp;
  }
}
```

>声明template参数时， 前缀关键字class和typename 可互换。
>
>请使用关键字typename标识嵌套从属类型名称；但不得在base class lists 或 member initialization list 内以它作为base class修饰符。

---



**条款四十三： 学习处理模板化基类内的名称**

```c++
template<typename Company>
class LoggingMsgSender：public MsgSender<Company>
{
public:
    void sendClearMsg(const MsgInfo& info)
    {
       sendClear(info);     // 调用base class函数： 这段代码无法通过编译
    }
};

template<>                   // 一个全特化的
class MsgSender<CompanyZ>    // MsgSender: 它和一般template相同，差别之在于它删掉了sendClear
{
public:
   void sendSecret(const MsgInfo& info) {}
};
```

全特化表明，当template实参是CompanyZ时使用这个特定的版本。

因为编译器知道template有可能是全特化的，所以它拒绝寻找继承而来的名称。

有三个办法：

1.   `this->sendClear(info);`      // 成立，假设sendClear将被继承
2.   使用using 声明式     `using MsgSender<Company>::sendClear;`

3.  明白指出被调用的函数位于base class内    `MsgSender<Company>::sendClear(info);  // 假设sendClear将被继承下来`       但它可能关闭了virtual函数的多态功能。