pass by value 调用copy构造函数，即 `Widget(const Widget& rhs); // copy构造函数` 构造临时变量。

STL标准模板库, 包含容器/迭代器/算法.



**条款一： 视c++为一个语言联邦 View c++ as a federation of languages.**

c++ 目前已经是一个同时支持过程形式(procedural)、 面向对象形式(object-oriented)、函数形式(functional)、泛型形式(generic)、元编程形式(metaprogramming)的语言。

c++的次语言有4个，分别为C 、Object-Oriented C++  、template C++ 、 STL 。



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



