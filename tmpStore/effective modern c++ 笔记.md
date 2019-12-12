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

init capture 在 c++ 14得到支持，所以如果想在c++11中实现类似的