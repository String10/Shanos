# Daily Log

## Day 0

忙活一晚上，试图在 WSL 上安装一个带有调试功能的 Bochs ，最终失败。

最后下载了一个 win-64 版本的 Bochs ，感觉可以先凑活用一用，如果不太行的话只能上虚拟机了。

附带书中的 configure 工具配置信息:

> ./configure --with-x11 --with-wx --enable-debugger -enable-disasm \
> --enable-all-optimizations --enable-readline --enable-long-phy-address \
> --enable-ltdl-install --enable-idle-hack --enable-plugins --enable-a20-pin \
> --enable-x86-64 --enable-smp --enable-cpu-level=6 --enable-large-ramfile \
> --enable-repeat-speedups --enable-fast-function-calls --enable-handlers-chaining \
> --enable-trace-linking --enable-configurable-msrs --enable-show-ips --enable-cpp \
> --enable-debugger-gui --enable-iodebug --enable-logging --enable-assert-checks \
> --enable-fpu --enable-vmx=2 --enable-svm --enable-3dnow --enable-alignment-check \
> --enable-monitor-mwait --enable-avx --enable-evex --enable-x86-debugger \
> --enable-pci --enable-usb --enable-voodoo

以及经搜索查询得到的精简版：

> ./configure \
> --enable-debugger \
> --enable-disasm \
> --enable-iodebug \
> --enable-x86-debugger \
> --with-x \
> --with-x11

或者只用：

> ./configure --enable-debugger --enable-disasm

Bochs 运行环境的配置实在是没有办法把书里面的全敲下来，先放着吧。

## Day 1

AT&T 汇编语言格式与 Intel 汇编语言格式对比。

汇编语言调用 C 函数。

GNU C 内嵌汇编及 GNU C 对标准 C 语言的拓展。