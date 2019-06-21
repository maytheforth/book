#include<new>
#include<iostream>
#include<utility>
#include<memory>

namespace may
{
	template<typename T>
	class listNode
	{
	public:
		std::unique_ptr<T> data;
		std::unique_ptr<listNode<T>> next;
		listNode();
		listNode(const T& newData) :data(new T(newData)) { next = nullptr; };
	};

	template<typename T>
	listNode<T>::listNode()
	{
		data = nullptr;
		next = nullptr;
	}

//------------------------------------------------------------------------

	template<typename T>
	class linkedlist
	{
	private:
		int lsize;
		std::unique_ptr<listNode<T>> head;
		listNode<T>* tail;
	public:
		linkedlist();
		~linkedlist() {};
		 bool isEmpty();
		 int size();
		 listNode<T>* getNodeAt(int pos);
		 void append(const T& newData);
		 void insert(int pos, const T& newData);
		 void erase(const T& target);
		listNode<T>* find(const T& target);
		 void printAll();
	};

	template<typename T>
	linkedlist<T>::linkedlist(): head(new listNode<T>())
	{
		lsize = 0;
		tail = head.get();
	}

	template<typename T>
	bool linkedlist<T>::isEmpty()
	{
		return !lsize;
	}

	template<typename T>
	int linkedlist<T>::size()
	{
		return lsize;
	}

	template<typename T>
	void linkedlist<T>::append(const T& newData)
	{
		std::unique_ptr<listNode<T>> newNode(new listNode<T>(newData));
		tail->next = std::move(newNode);
		tail = tail->next.get();
		++lsize;
	}

	template<typename T>
	void linkedlist<T>::printAll()
	{
		listNode<T>* searchNode = head.get();
		while (searchNode->next != NULL)
		{
			searchNode = searchNode->next.get();
			std::cout << *(searchNode->data) << " ";
		}
		std::cout << std::endl;
	}

	template<typename T>
	listNode<T>* linkedlist<T>::find(const T& target)
	{
		if (isEmpty()) return;
		listNode<T>* searchNode = head.get();
		while (searchNode->next != NULL)
		{
			searchNode = searchNode->next.get();
			if (*(searchNode->data) == target)
				return searchNode;
		}
		return NULL;
	}

	template<typename T>
	listNode<T>* linkedlist<T>::getNodeAt(int pos)
	{
		listNode<T>* aim = nullptr;
		if (pos <= 0 || pos > lsize)
		{
			return aim;
		}
		else
		{
			aim = head.get();
			int i = 1;
			while (i <= pos)
			{
				aim = aim->next.get();
				++i;
			}
			return aim;
		}
	}

	template<typename T>
	void linkedlist<T>::erase(const T& target)
	{
		if (isEmpty()) return;
		listNode<T>* searchNode = head.get();
		listNode<T>* preNode = head.get();
		bool find = false;
		while (searchNode->next != NULL)
		{
			preNode = searchNode;
			searchNode = searchNode->next.get();
			if (*(searchNode->data) == target)
			{
				find = true;
				break;
			}
		}

		if (find)
		{
			if (tail == searchNode) 
				tail = preNode;
			preNode->next = std::move(searchNode->next);
			lsize--;
		}
	}

	template<typename T>
	void linkedlist<T>::insert(int pos, const T& newData)
	{
		if (pos <= 0 || pos > lsize + 1)
			return;
		else if (pos == lsize + 1)
		{
			append(newData);
		}
		else
		{
			std::unique_ptr<listNode<T>> newNode(new listNode<T>(newData));
			listNode<T>* preNode = head.get();
			int i = 1;
			while (i < pos)
			{
				preNode = preNode->next.get();
				++i;
			}
			newNode.get()->next = std::move(preNode->next);
			preNode->next = std::move(newNode);
			++lsize;
		}
	}
}

int main()
{
	{
		using namespace may;
		linkedlist<int> list;
		list.append(1);
		list.append(2);
		list.append(3);
		list.printAll();
		list.erase(1);
		list.printAll();
		list.erase(3);
		list.append(4);
		list.printAll();
		list.insert(1, 5);
		list.insert(4, 6);
		list.printAll();
	}
	return 0;
}