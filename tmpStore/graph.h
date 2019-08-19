#pragma once
#ifndef __GRAPH_H__
#define __GRAPH_H__
#include<iostream>
#include<memory.h>
#include<assert.h>
#include<queue>
#include<vector>
#include<stack>
namespace may
{
    class undirectedGraph
    {
    private:
        //������
        int v;
        // �ڽӾ���
        int** adj;
    public:
        undirectedGraph(int v);
        ~undirectedGraph();
        void addEdge(int s, int t);
        void printMatrix();
        int getVertexNum() { return v; }
        void findpathBreadthFirst(int start, int end);
        void findpathDepthFirst(int start, int end);
    };
    undirectedGraph::undirectedGraph(int v) :v(v)
    {
        assert(v > 0);
        adj = new int*[v];
        for (int i = 0; i < v; i++)
        {
            adj[i] = new int[v];
            memset(adj[i], 0, sizeof(int) * v);
        }
    }
    undirectedGraph::~undirectedGraph()
    {
        assert((v > 0) && (adj != nullptr));
        for (int i = 0; i < v; i++)
        {
            delete[] adj[i];
            adj[i] = nullptr;
        }
        delete[] adj;
        adj = nullptr;
    }
    void undirectedGraph::addEdge(int s, int t)
    {
        assert((s >= 0) && (t >= 0) && (s < v) && (t < v));
        adj[s][t] = 1;
        adj[t][s] = 1;
    }
    void undirectedGraph::printMatrix()
    {
        assert((v > 0) && (adj != nullptr));
        for (int i = 0; i < v; i++)
        {
            for (int j = 0; j < v; j++)
            {
                std::cout << adj[i][j] << " ";
            }
            std::cout << std::endl;
        }
    }
    void undirectedGraph::findpathBreadthFirst(int start, int end)
    { 
        assert((start >= 0) && (end >= 0) && (start < v) && (end < v));
        if (start == end) return;
        int* visited = new int[v];
        int* ord = new int[v];
        // prev�洢����ǰ���ڵ�
        int* prev = new int[v];
        memset(visited, 0,sizeof(int) * v);
        memset(prev, -1 , sizeof(int) * v);
        memset(ord, -1, sizeof(int) * v);
        std::queue<int> store;
        store.push(start);
        ord[start] = 0;
        while (!store.empty())
        {
            int temp = store.front();
            visited[temp] = 1;
            store.pop();
            for (int i = 0; i < v; i++)
            {
                // ���֮ǰû���ʹ���������֮����·��
                if (!visited[i] && (adj[temp][i] == 1))
                {
                    store.push(i);
                    if (prev[i] != -1)
                    {
                        if (ord[temp] + 1 < ord[i])
                        {
                            prev[i] = temp;
                            ord[i] = ord[temp] + 1;
                        }
                    }
                    else
                    {
                        prev[i] = temp;
                        ord[i] = ord[temp] + 1;
                    }
                    if (i == end)
                    {
                        break;
                    }
                }
                else if (visited[i] && (adj[temp][i] == 1)) //�������֮����·�������Ѿ������ʹ���,�ж��Ƿ������·��
                {
                    if (ord[temp] + 1 < ord[i])
                    {
                        prev[i] = temp;
                        ord[i] = ord[temp] + 1;
                    }
                }
            }
        }
        std::vector<int> answer;
        int mid = end;
        while (mid != -1)
        {
            answer.emplace_back(mid);
            mid = prev[mid];
        }
        std::reverse(answer.begin(), answer.end());
        std::cout << ord[end] << std::endl;
        for (auto item : answer)
        {
            std::cout << item << "->";
        }
        delete[] visited;
        delete[] prev;
        delete[] ord;
    }
    void undirectedGraph::findpathDepthFirst(int start, int end)
    {
        assert((start >= 0) && (end >= 0) && (start < v) && (end < v));
        if (start == end) return;
        int* visited = new int[v];
        memset(visited, 0, sizeof(int) * v);
        std::stack<int> store;
        store.push(start);
        visited[start] = 1;
        int preNode = -1;
        while (!store.empty())
        {
            int topElem = store.top();
            int count = 0;
            int i = -1;
            for (i = preNode + 1; i < v; i++)
            {
                //û�з��ʹ�������֮����·��
                if (!visited[i] && (adj[topElem][i] == 1))
                {
                    count++;
                    store.push(i);
                    visited[i] = 1;
                    break;
                }
            }
            if (i == end)
            {
                break;
            }
            // û��û���ʹ�������ڵ�
            if (!count)
            {
                preNode = store.top();
                store.pop();
            }
        }
        while (!store.empty())
        {
            int topElem = store.top();
            std::cout << topElem << " ";
            store.pop();
        }
        std::cout << std::endl;
    }
}
#endif
