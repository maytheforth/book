/*
  It is used to test singleList.h
*/
#include"singleList.h"
using namespace std;
int main()
{
  may::singleList<int> list;
  cout << list.isEmpty() << endl;

  list.append(1);
  cout << list.size() << endl;
  list.insert(1,2);
  list.insert(3,3);
  cout << list.size() << endl;
  printSingleList(list);
  cout << "-----" << list.getNodeAt(1)->data << "----" <<endl;
  cout << "-----" << list.getNodeAt(2)->data << "----" <<endl;
  cout << "-----" << list.getNodeAt(3)->data << "----" <<endl;
  
  list.delNodeAt(3);
  printSingleList(list);
  cout << list.size() << endl; 
  list.delNodeAt(1);
  printSingleList(list);
  return 0;
}
