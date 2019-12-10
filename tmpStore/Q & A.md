1. **The special problem of  accept()ing when you can't"** problem

当服务器连接增多时，经常会出现描述符用完，导致accept()失败，并返还一个`ENFILE`错误，但没有拒绝这个连接，连接仍然在连接队列中，这导致在下一次迭代的时候，仍然会触发监听描述符的可读事件，导致程序的busy loop.  优雅的解决办法是，先`open /dev/null`，保留一个描述符，当accept()出现`ENFILE`错误的时候，`close /dev/null`，然后`accept`，然后再`close`掉`accept`产生的`fd`, 然后再次`open/dev/null` ，优雅的方式来拒绝客户端的连接。

```c++
// idleFd_(::open("/dev/null",O_RDONLY | O_CLOEXEC))
::close(idleFd_);
idleFd_ = ::accept(acceptSocket_fd(),NULL,NULL);
::close(idleFd_);
idleFd_ = ::open("/dev/null",O_RDONLY | O_CLOEXEC);
```



 