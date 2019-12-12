**安装**

`./configure  --without-boost`

make && make install 

编译时： 加上宏 `ASIO_STANDALONE`

asio::read 是 preactor 模式的，读到指定的buf大小才会返回

