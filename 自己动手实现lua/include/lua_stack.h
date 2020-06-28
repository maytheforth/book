#ifndef __LUA_STACK_H__
#define __LUA_STACK_H__

// lua类型
enum LUA_TYPE {
    LUA_TNONE = -1,
    LUA_TNIL,
    LUA_TBOOLEAN,
    LUA_TLIGHTUSERDATA,
    LUA_TNUMBER,
    LUA_TSTRING,
    LUA_TTABLE,
    LUA_TFUNCTION,
    LUA_TUSERDATA,
    LUA_TTHREAD
};

struct lua_stack
{
    


};

#endif