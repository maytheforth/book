#ifndef __LUAC_HEADER__H__
#define __LUAC_HEADER__H__
#include<string>
typedef struct upvalue{
    unsigned char Instack;
    unsigned char Idx;
}UPVALUE;

// 大端还是小端
enum endien { LITTLE, BIG };

// 常量tag 
enum constant_tag {
    TAG_NIL  = 0x00,
    TAG_BOOLEAN = 0X01,
    TAG_NUMBER = 0X03,
    TAG_INTEGER = 0X13,
    TAG_SHORT_STR = 0X04,
    TAG_LONG_STR = 0X14
};


// 常量定义
struct constant {
    constant_tag tag;
    union value{
        uint8_t boolValue;
        double  doubleValue;
        long long intValue;
        char*  strValue;
    }v;
    ~constant() {
        if(tag == TAG_SHORT_STR || tag == TAG_LONG_STR)
        {
            free(v.strValue);
        }
    }
};

// 局部变量定义
typedef struct LocVar{
    std::string varName;
    uint32_t    startPC;
    uint32_t    endPC;
}LOCVAR;


typedef struct header {
    unsigned char signature[4];                  // magic number 0x1b4c7561
    char        version;                       //  0x53
    char        format;                        //  格式号， 0x00
    unsigned char luacData[6];                   //  验证 
    char        cintSize;
    char        sizetSize;
    char        instructionSize;
    char        luaIntegerSize;
    char        luaNumberSize;
    long long   luacInt;                       // 0x5678 检测大小端方式
    double      luacNum;                       // 检测浮点数格式
}LUAC_HEADER;

typedef struct proto {
    std::string         Source;                        // 源文件名
    uint32_t            LineDefined;                   // 起始行号
    uint32_t            LastLineDefined;               // 终止行号
    char                NumParams;                     // 固定参数个数
    char                IsVararg;                      // 是否是变长函数
    char                MaxStackSize;                  // 寄存器数量
    uint32_t*           Code;                          // 指令集
    struct constant*    Constants;                 // 常量表
    UPVALUE*            Upvalues;                      // upvalue表
    struct proto*       Protos;                 // 子函数原型列表
    uint32_t*           LineInfo;                      // 行号表
    LOCVAR*             LocVars;                       // 局部变量表  
    std::string*        UpvalueNames;                 // upvalue名字表
}PROTO;


#endif 