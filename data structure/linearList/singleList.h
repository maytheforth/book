#ifndef __SINGLELIST_H__
#define __SINGLELIST_H__
#include<new>
#include<iostream>
namespace may
{
  template<typename T>
  class listNode
  {
    public:
      T data;
      listNode<T>* next;
      listNode<T>():data(0),next(NULL) {}
      listNode<T>(T x):data(x),next(NULL) {}
  };

   // 此单链表head节点不储存数据，tail节点指向最后一个元素
   template<typename T>
   class singleList 
   {
     friend void printSingleList(const singleList<T>& list)
     {
       listNode<T>* tmp = list.head;
       while(tmp != list.tail)
       {
         tmp = tmp->next;
         std::cout << tmp->data << " ";
       }
       std::cout << std::endl;
      
     }

     private: 
        listNode<T>* head;
        listNode<T>* tail;
        int lsize;
     public:
        explicit singleList();
        virtual ~singleList();
        bool isEmpty();
        int size() ;
        listNode<T>* getNodeAt(int pos);
        void append(T newData);
        void insert(int pos,T newData);    
        void delNodeAt(int pos);
        listNode<T>* begin();
        listNode<T>* end();
  };

  // 初始化链表  
  template<typename T>
  singleList<T>::singleList()
  {
     lsize = 0;
     head = new listNode<T>();
     tail = head;
  }
  
  // 析构单链表
  template<typename T>
  singleList<T>::~singleList()
  {
     listNode<T>* tmp = head;
     while(head != tail)
     {
       head = head->next;
       delete tmp;
       tmp = head;
     }
     delete tail;
  }
 
  // 链表是否为空
  template<typename T>
  bool singleList<T>::isEmpty()
  { 
     return lsize == 0 ;
  }
  // 获取链表的大小
  template<typename T>
  int singleList<T>::size()
  {
     return lsize;
  }

  // 获取指定位置的节点
  template<typename T>
  listNode<T>* singleList<T>::getNodeAt(int pos)
  {
    listNode<T>* aim = NULL;
    if(pos <=0 || pos > lsize)
    {
      return aim;
    }
    else
     {
        aim = head;
        int i = 1;
        while(i <= pos)
        {
          aim = aim->next;
          ++i;
        }
        return aim;
     }
  }


  // 往链表尾部添加数据
  template<typename T>
  void singleList<T>::append(T newData)
  {
     listNode<T>* newNode = new listNode<T>(newData);
     ++ lsize;
     tail->next = newNode;
     tail = newNode;
  }

  //在指定位置插入数据
  template<typename T>
  void singleList<T>::insert(int pos, T newData)
  {
     if(pos <=0 || pos > lsize + 1)
       return;
     else if(pos == lsize + 1)
     {
        append(newData);
     }
     else
     {
        listNode<T>* newNode = new listNode<T>(newData);
        //找到指定位置前一个位置的元素
        listNode<T>* preNode = head;
        int i = 1;
        while( i < pos)
        {  
          preNode = preNode->next;
          ++i;
        }
        listNode<T>* tmp = preNode->next;
        preNode->next = newNode;
        newNode->next = tmp;
        ++lsize;
     }
  }
  // 删除指定位置的元素
   template<typename T>
  void singleList<T>::delNodeAt(int pos)
  {
     if(pos <=0 || pos > lsize)
       return;
     else
     {
        //找到指定位置前一个位置的元素
        listNode<T>* preNode = head;
        int i = 1;
        while(i < pos)
        {
           preNode = preNode->next;
           ++i;
        }
        if(pos != lsize)
        {
          listNode<T>* tmp = preNode->next->next;
          delete preNode->next;
          preNode->next = tmp;
        }
        else
        {
          delete preNode->next;
          preNode->next = NULL;
          tail = preNode;
        }
        --lsize;
     }
  } 
  // 获取头结点
  template<typename T>
  listNode<T>* singleList<T>::begin()
  { 
     return head;
  }
  // 获取尾节点 
  template<typename T>
  listNode<T>* singleList<T>::end()
  {
     return tail;
  }
 
}
#endif
