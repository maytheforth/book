#ifndef __SKIP_LIST_H__
#define __SKIP_LIST_H__

#include<iostream>
#include<new>
#include<memory>
#include<random>

namespace may
{
	const int MAX_LEVEL = 16;
    template<typename T>
    class skipNode
    {
    private:
        mutable int level;
        std::unique_ptr<T> data;
        skipNode<T>* forward[MAX_LEVEL];
    public:
        int getLevel() const { return level; };
        skipNode();
        skipNode(const T& data);
        void setLevel(int level) { this->level = level; };
        T getData() { return *data; };
        ~skipNode() {};
        skipNode<T>* getIndex() { return forward; };
    };
    
    template<typename T>
    skipNode<T>::skipNode() :level(1)
    {
        for (int i = 0; i < MAX_LEVEL; i++)
        {
            forward[i] = nullptr;
        }
    }

    template<typename T>
    skipNode<T>::skipNode(const T& value): level(1),data(new T(value))
    {
        for (int i = 0; i < MAX_LEVEL; i++)
        {
            forward[i] = nullptr;
        }
    }

    template<typename T>
    class skipList
    {
    private:
        int max_level;
        std::unique_ptr<skipNode<T>> head;
        std::default_random_engine e;
    public:
        skipList();
        void Insert(const T& value);
        void Delete(const T& value);
        int GetRandomLevel();
    };

    // 生成头节点，设置索引层次
    template<typename T>
    skipList<T>::skipList(): e(32767),head(new skipNode<T>()),max_level(0)
    {
    }

    template<typename T>
    int skipList<T>::GetRandomLevel()
    {
        int count = 1;
        for (int i = 0; i < MAX_LEVEL; i++)
        {
            int randomNum = e();
            if (randomNum & 0x1 == 1)
            {
                count++;
            }
        }
        return count;
    }

    template<typename T>
    void skipList<T>::Insert(const T& value)
    {
        // 生成一个新的节点
        std::unique_ptr<skipNode<T>> newNode(new skipNode<T>(value));
        int level = GetRandomLevel();
        newNode->setLevel(level);
      
        if (level > max_level)
        {
            max_level = level;
        }

        skipNode<T>* temp = head.get();
        for (int i = level - 1; i >= 0; i--)
        {
            while ((temp->getIndex()[i] != nullptr) && (temp->getIndex()[i]->getData() <= value))
            {
                temp = temp->getIndex()[i];
            }
            skipNode<T>* store = temp->getIndex()[i];
            temp->getIndex()[i] = newNode.get();
            newNode->getIndex()[i] = store;
        }
    }

    template<typename T>
    void skipList<T>::Delete(const T& value)
    {
        
    }

    template<typename T>
    
}
#endif