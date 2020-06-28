#include "include/luac_header.h"
#include<iostream>
#include<fstream>
#include<memory>
#include<cstring>
#include<stdio.h>
#include<fmt/core.h>

int readProto(PROTO& lua_proto, const char* fileContent, int startPos);

int filesize = 0;
char* fileContent;
using std::ifstream;
std::string sourceName;

// 获取luac文件字节流
void readfile(const char* filename)
{
    ifstream inFile(filename, std::ios::in | std::ios::binary);
    if(!inFile.is_open())
    {
        return;
    }

    inFile.seekg(0, std::ios_base::end);
    filesize = inFile.tellg();
    fileContent = new char[filesize]();
    memset(fileContent,0,filesize);
    inFile.seekg(0);
    int i = 0;
    while(!inFile.eof())
    {
        inFile.get(fileContent[i]);
        i++;
    }
    inFile.close();
}


/*
lua 字符串
null    0
n<=0xfd 短字符串    (one byte for size + 1)     (string)
n>=0xfe 长字符串    0xff    (8 bytes for size + 1)  (string)

pair.first  string
pair.second nextPos
读取lua string
*/
std::pair<std::string,int> readString(const char* fileContent, int startPos)
{
    unsigned char flag = fileContent[startPos];
    if(flag == 0x00)
    {
        return std::make_pair<std::string,int>("", startPos + 1);
    }
    else if (flag != 0xff)  //short string
    {       
        int size = flag;
        return std::make_pair<std::string,int>(std::string(fileContent + startPos + 1, size - 1), startPos + size);
    }
    else            // long string
    {
        long long size = 0;
        memmove(&size, fileContent + startPos, 8);
        return std::make_pair<std::string,int>(std::string(fileContent + startPos + 9, size - 1), startPos + 8 + size);
    }
}

// 读取常量表
int  readConstants(PROTO& lua_proto,const char* fileContent,int startPos)
{
    int constantSize = 0;
    memmove(&constantSize, fileContent + startPos, 4);
    fmt::print("constantSize = {}\n", constantSize);
    lua_proto.Constants = new constant[constantSize];
    memset(lua_proto.Constants, 0, constantSize * sizeof(constant));

    int i = 0;
    int nowPos = startPos + 4;
    /*
    enum constant_tag {
        TAG_NIL  = 0x00,
        TAG_BOOLEAN = 0X01,
        TAG_NUMBER = 0X03,
        TAG_INTEGER = 0X13,
        TAG_SHORT_STR = 0X04,
        TAG_LONG_STR = 0X14
    };
    */
    fmt::print("constants are like:\n");
    while(i < constantSize)
    {
        char tag = fileContent[nowPos];
        if(tag == 0x00)
        {
            lua_proto.Constants[i].tag = TAG_NIL;
            fmt::print("nil\n");
            nowPos += 1;
        }
        else if(tag == 0x01)
        {
            lua_proto.Constants[i].tag = TAG_BOOLEAN;
            lua_proto.Constants[i].v.boolValue = fileContent[nowPos + 1];
            fmt::print("Boolean: {%d}\n", lua_proto.Constants[i].v.boolValue);
            nowPos += 2;
        }
        else if(tag == 0x03)
        {
            lua_proto.Constants[i].tag = TAG_NUMBER;
            memmove(&(lua_proto.Constants[i].v.doubleValue),fileContent + nowPos + 1, 8);
            fmt::print("number: {}\n",lua_proto.Constants[i].v.doubleValue);
            nowPos += 9;
        }
        else if(tag == 0x13)
        {
            lua_proto.Constants[i].tag = TAG_INTEGER;
            memmove(&(lua_proto.Constants[i].v.intValue),fileContent + nowPos + 1, 8);
            fmt::print("integer: {}\n", lua_proto.Constants[i].v.intValue);
            nowPos += 9;
        }
        else if(tag == 0x04)
        {
            lua_proto.Constants[i].tag = TAG_SHORT_STR;
            auto [constantName,nextPos] = readString(fileContent, nowPos + 1);
            lua_proto.Constants[i].v.strValue = (char*)malloc(constantName.size() + 1);
            memset(lua_proto.Constants[i].v.strValue,0, constantName.size() + 1);
            memmove(lua_proto.Constants[i].v.strValue,constantName.c_str(), constantName.size());
            fmt::print("string: {:s}\n",lua_proto.Constants[i].v.strValue);
            nowPos = nextPos;
        }
        else if(tag == 0x14)
        {
            lua_proto.Constants[i].tag = TAG_LONG_STR;
            auto [constantName,nextPos] = readString(fileContent, nowPos + 1);
            lua_proto.Constants[i].v.strValue = (char*)malloc(constantName.size() + 1);
            memset(lua_proto.Constants[i].v.strValue,0, constantName.size() + 1);
            memmove(lua_proto.Constants[i].v.strValue,constantName.c_str(), constantName.size());
            fmt::print("string: {:s}\n",lua_proto.Constants[i].v.strValue);
            nowPos = nextPos;
        }
        i++;
    }
    return nowPos;
}

// 读取upvalue表
int readUpvalues(PROTO& lua_proto, const char* fileContent, int startPos)
{
    int tbsize = 0;
    memmove(&tbsize,fileContent + startPos , 4);
    fmt::print("upvalue table size = {}\nupvalues are like:\n",tbsize);
    lua_proto.Upvalues = new UPVALUE[tbsize];
    memset(lua_proto.Upvalues,0, tbsize * sizeof(UPVALUE));
    int nowPos = startPos + 4;
    for(int i = 0; i < tbsize; i++)
    {
        memmove(&(lua_proto.Upvalues[i]), fileContent + nowPos,2);
        fmt::print("Instack = {} , Idx = {} \n",lua_proto.Upvalues[i].Instack, lua_proto.Upvalues[i].Idx);
        nowPos += 2;
    }   
    return nowPos;
}

endien judgeEndien(long long target)
{   
    union a {
        long long b;
        int c[2];
    };
    union a  test;
    test.b = target;
    if(test.c[0] == 0x5678)
    {
        return LITTLE; 
    }
    else
    {
        return BIG;
    }
}

/*
typedef struct header {
    char        signature[4];                  // magic number 0x1b4c7561
    char        version;                       //  0x53
    char        format;                        //  格式号， 0x00
    char        luacData[6];                   //  验证 
    char        cintSize;
    char        sizetSize;
    char        instructionSize;
    char        luaIntegerSize;
    char        luaNumberSize;
    long long   luacInt;                       // 0x5678 检测大小端方式  8bytes
    double      luacNum;                       // 检测浮点数格式     8bytes
}LUAC_HEADER;
*/
void fillHeader(LUAC_HEADER& header,char* fileContent, int filesize)
{
    memmove(header.signature,fileContent,4);
    header.version = fileContent[4];
    header.format = fileContent[5];
    memmove(header.luacData, fileContent + 6, 6);
    header.cintSize = fileContent[12];
    header.sizetSize = fileContent[13];
    header.instructionSize = fileContent[14];
    header.luaIntegerSize = fileContent[15];
    header.luaNumberSize = fileContent[16]; 
    memmove(&(header.luacInt), fileContent + 17 , 8);
    memmove(&(header.luacNum),fileContent + 25, 8);
}

void showHeader(LUAC_HEADER& header)
{
    fmt::print("signature: {:02x} {:02x} {:02x} {:02x}\n",header.signature[0],header.signature[1],header.signature[2],header.signature[3]);
    fmt::print("version: {:02x}\n", header.version);
    fmt::print("format: {:02x}\n", header.format);
    fmt::print("luacData: {:02x} {:02x} {:02x} {:02x} {:02x} {:02x}\n",header.luacData[0],header.luacData[1],header.luacData[2],header.luacData[3],header.luacData[4],header.luacData[5]);
    fmt::print("cintSize: {:02x}\n", header.cintSize);
    fmt::print("sizetSize: {:02x}\n",header.sizetSize);
    fmt::print("instructionSize: {:02x}\n",header.instructionSize);
    fmt::print("luaIntegerSize: {:02x}\n", header.luaIntegerSize);
    fmt::print("luaNumberSize: {:02x}\n", header.luaNumberSize);
    fmt::print("luacInt: {:016x}\n",header.luacInt);
    int* df = (int*)&header.luacNum;
    fmt::print("luacNum: {:08x}{:08x}\n",*df, *(df + 1));
}

int readCode(PROTO& lua_proto, const char* fileContent, int startPos)
{
    int insSize = 0;
    memmove(&insSize,fileContent + startPos,4);
    fmt::print("--------------------------- instructions size = {}\n", insSize);
    lua_proto.Code = new uint32_t[insSize]();
    int nowPos = startPos + 4;
    for(int i = 0; i < insSize; i++)
    {
        memmove(&(lua_proto.Code[i]),fileContent + nowPos,4);
        fmt::print("{:08x}\n", lua_proto.Code[i]);
        nowPos += 4;
    }
    return nowPos;
}

// 获取函数基本信息
int readBasicInfo(PROTO& lua_proto,const char* fileContent, int startPos)
{
    auto [luaName, nextPos] = readString(fileContent, startPos);
    if(luaName != "")
    {
        lua_proto.Source = luaName;
        sourceName = luaName;
        fmt::print("sourceName = {}\n",luaName);
    }
    else
    {
        lua_proto.Source = sourceName;
        fmt::print("sourceName = {}\n",sourceName);
    }
    memmove(&lua_proto.LineDefined, fileContent + nextPos,4);
    memmove(&lua_proto.LastLineDefined, fileContent + nextPos + 4, 4);
    lua_proto.NumParams = fileContent[nextPos + 8];
    lua_proto.IsVararg = fileContent[nextPos + 9];
    lua_proto.MaxStackSize = fileContent[nextPos + 10];
    fmt::print("line = {} , lastline = {} , numparams = {:d} , isvararg = {:d} , MaxStackSize = {:d}\n", lua_proto.LineDefined,lua_proto.LastLineDefined, lua_proto.NumParams, lua_proto.IsVararg, lua_proto.MaxStackSize);
    return nextPos + 11;
}

// 子函数原型列表
int readProtos(PROTO& lua_proto, const char* fileContent, int startPos)
{
    int protoSize = 0;
    memmove(&protoSize,fileContent + startPos,4);
    fmt::print("----------protoSize = {}\n",protoSize);
    lua_proto.Protos = new PROTO[protoSize];
    memset(lua_proto.Protos, 0 , protoSize * sizeof(PROTO));
    int nowPos = startPos + 4;
    for(int i = 0; i < protoSize; i++)
    {
        nowPos = readProto(lua_proto.Protos[i],fileContent, nowPos);   
    }
    return nowPos;
}

int readLineInfo(PROTO& lua_proto, const char* fileContent, int startPos)
{
    int lineInfoSize = 0;
    memmove(&lineInfoSize, fileContent + startPos, 4);
    fmt::print("-----------LineInfoSize = {}\n", lineInfoSize);
    lua_proto.LineInfo = new uint32_t[lineInfoSize]();
    int nowPos = startPos + 4;
    for(int i = 0; i < lineInfoSize; i++)
    {
        memmove(&(lua_proto.LineInfo[i]), fileContent + nowPos ,4);
        fmt::print("{}\n",lua_proto.LineInfo[i]);
        nowPos += 4;   
    }
    return nowPos;
}

int readLocVars(PROTO& lua_proto, const char* fileContent, int startPos)
{   
    int locVarSize = 0;
    memmove(&locVarSize,fileContent + startPos, 4);
    fmt::print("------------------LocVarSize = {}\n", locVarSize);
    lua_proto.LocVars = new LOCVAR[locVarSize];
    int nowPos = startPos + 4;
    for(int i = 0; i < locVarSize; i++)
    {
        auto [varName,nextPos] = readString(fileContent, nowPos);
        lua_proto.LocVars[i].varName = varName;
        nowPos = nextPos;
        memmove(&(lua_proto.LocVars[i].startPC), fileContent + nowPos, 4);
        memmove(&(lua_proto.LocVars[i].endPC), fileContent + nowPos + 4, 4);
        fmt::print("{} ,{} ,{}\n",lua_proto.LocVars[i].varName, lua_proto.LocVars[i].startPC, lua_proto.LocVars[i].endPC);
        nowPos += 8;
    }
    return nowPos;
}

int readUpvalueNames(PROTO& lua_proto, const char* fileContent, int startPos)
{
    int upvalueNums = 0;
    memmove(&upvalueNums, fileContent + startPos, 4);
    fmt::print("---------------upvalueNums = {}\n",upvalueNums);
    lua_proto.UpvalueNames = new std::string[upvalueNums];
    int nowPos = startPos + 4;
    for(int i = 0; i < upvalueNums; i++)
    {
        auto [name,nextPos] = readString(fileContent,nowPos);
        lua_proto.UpvalueNames[i] = name;
        fmt::print("{}\n",lua_proto.UpvalueNames[i]);
        nowPos = nextPos;
    }
    return nowPos;
}

int readProto(PROTO& lua_proto, const char* fileContent, int startPos)
{
    int nowPos = 0;
    nowPos = readBasicInfo(lua_proto,fileContent, startPos);
    nowPos = readCode(lua_proto,fileContent, nowPos);
    fmt::print("-------------------");
    nowPos = readConstants(lua_proto,fileContent, nowPos);
    fmt::print("--------------------");
    nowPos = readUpvalues(lua_proto,fileContent, nowPos);
    fmt::print("\n---------begin Protos----\n");
    nowPos = readProtos(lua_proto,fileContent, nowPos);
    fmt::print("\n---------end Protos---------\n");
    nowPos = readLineInfo(lua_proto,fileContent,nowPos);
    fmt::print("--------------------");
    nowPos = readLocVars(lua_proto,fileContent,nowPos);
    fmt::print("--------------------");
    nowPos = readUpvalueNames(lua_proto,fileContent,nowPos);
    return nowPos;
}

int main(int argc, char* argv[])
{
   if(argc <= 1)
   {
       return 0;
   }
 
   const char* filename = argv[1];
   readfile(filename);

   {
    for(int i = 0; i < filesize; i++)
    {
        fmt::print("{:02x} ",static_cast<unsigned char>(fileContent[i]));
        if( (i + 1) % 16 == 0 )
        {
            fmt::print("\n");
        }
    }
    fmt::print("\n\n");
   }

    LUAC_HEADER header;
    PROTO    luaProto;
    fillHeader(header,fileContent,filesize);
    showHeader(header);
    readProto(luaProto,fileContent,34);
    return 0;
}