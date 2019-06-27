pass by value 调用copy构造函数，即 `Widget(const Widget& rhs); // copy构造函数` 构造临时变量。

STL标准模板库, 包含容器/迭代器/算法.



**条款一： 视c++为一个语言联邦 View c++ as a federation of languages.**

c++ 目前已经是一个同时支持过程形式(procedural)、 面向对象形式(object-oriented)、函数形式(functional)、泛型形式(generic)、元编程形式(metaprogramming)的语言。

c++的次语言有4个，分别为C 、Object-Oriented C++  、template C++ 、 STL 。



**条款二:  尽量以const, enum, inline 替换为 #define**

运用define定义的常量获得编译错误信息时，可能会带来困惑。

class专属常量，为了将常量的作用域scope限制于class内，必须让它成为class的一个成员，二为了确保此常量至多只有一份实体，必须让它成为一个static成员。