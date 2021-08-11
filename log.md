# Daily Log

## Day 0

忙活一晚上，试图在 WSL 上安装一个带有调试功能的 Bochs ，最终失败。

最后下载了一个 win-64-2.7 版本的 Bochs ，感觉可以先凑活用一用，如果不太行的话只能上虚拟机了。

附带书中的 configure 工具配置信息:

```shell
./configure --with-x11 --with-wx --enable-debugger -enable-disasm \
--enable-all-optimizations --enable-readline --enable-long-phy-address \
--enable-ltdl-install --enable-idle-hack --enable-plugins --enable-a20-pin \
--enable-x86-64 --enable-smp --enable-cpu-level=6 --enable-large-ramfile \
--enable-repeat-speedups --enable-fast-function-calls --enable-handlers-chaining \
--enable-trace-linking --enable-configurable-msrs --enable-show-ips --enable-cpp \
--enable-debugger-gui --enable-iodebug --enable-logging --enable-assert-checks \
--enable-fpu --enable-vmx=2 --enable-svm --enable-3dnow --enable-alignment-check \
--enable-monitor-mwait --enable-avx --enable-evex --enable-x86-debugger \
--enable-pci --enable-usb --enable-voodoo
```

以及经搜索查询得到的精简版：

```shell
./configure \
--enable-debugger \
--enable-disasm \
--enable-iodebug \
--enable-x86-debugger \
--with-x \
--with-x11
```

或者只用：

```shell
./configure --enable-debugger --enable-disasm
```

Bochs 运行环境的配置实在是没有办法把书里面的全敲下来，先放着吧。

## Day 1

AT&T 汇编语言格式与 Intel 汇编语言格式对比。

汇编语言调用 C 函数。

GNU C 内嵌汇编及 GNU C 对标准 C 语言的拓展。

### 编写简单的 Boot 引导程序

根据书中相关知识及参考代码，实现一个简单的 Boot 引导程序，可以在界面上打印**一行文字**。

**操作步骤：**

1. 编写 boot.asm ，相关知识可在书中查询，代码内容如下：

   ```assembly
   org		0x7c00
   
   BaseOfStack		equ		0x7c00
   
   Label_Start:
   
   	mov 	ax, 	cs
   	mov 	ds, 	ax
   	mov		es, 	ax
   	mov 	ss, 	ax
   	mov 	sp, 	BaseOfStack
   
   ;=======	clear screen
   
   	mov 	ax, 	0600h
   	mov 	bx, 	0700h
   	mov 	cx, 	0
   	mov 	dx, 	0184fh
   	int 	10h
   ;=======	set focus
   
   	mov 	ax, 	0200h
   	mov 	bx, 	0000h
   	mov 	dx, 	0000h
   	int 	10h
   ;=======	display on screen : Start Booting......
   
   	mov 	ax, 	1301h
   	mov		bx, 	000fh
   	mov 	dx, 	0000h
   	mov 	cx, 	17
   	push	ax
   	mov 	ax, 	ds
   	mov		es, 	ax
   	pop		ax
   	mov 	bp, 	StartBootMessage
   	int 	10h
   ;=======	reset floppy
   
   	xor 	ah, 	ah
   	xor 	dl, 	dl
   	int 	1301h
   
   StartBootMessage:	db		"Welcome to Shanos"
   ;========	fill zero until whole sector
   
   	times 	510 - ($ - $$) 	db 		0
   	dw 		0xaa55
   ```

2. 利用 Bochs 文件夹中的 bximage.exe 创建虚拟软盘镜像，指令如下：

   ```
   ========================================================================
                                   bximage
     Disk Image Creation / Conversion / Resize and Commit Tool for Bochs
            $Id: bximage.cc 14091 2021-01-30 17:37:42Z sshwarts $
   ========================================================================
   
   1. Create new floppy or hard disk image
   2. Convert hard disk image to other format (mode)
   3. Resize hard disk image
   4. Commit 'undoable' redolog to base image
   5. Disk image info
   
   0. Quit
   
   Please choose one [0] 1
   
   Create image
   
   Do you want to create a floppy disk image or a hard disk image?
   Please type hd or fd. [hd] fd
   
   Choose the size of floppy disk image to create.
   Please type 160k, 180k, 320k, 360k, 720k, 1.2M, 1.44M, 1.68M, 1.72M, or 2.88M.
    [1.44M]
   
   What should be the name of the image?
   [a.img] boot.img
   
   Creating floppy image 'boot.img' with 2880 sectors
   
   The following line should appear in your bochsrc:
     floppya: image="boot.img", status=inserted
   (The line is stored in your windows clipboard, use CTRL-V to paste)
   
   Press any key to continue
   ```

3. 利用 nasm 编译引导程序，相关指令如下：

   ```shell
   nasm .\boot.asm -o boot.bin  
   ```

4. 利用 dd.exe 将二进制程序文件写入到虚拟软盘镜像文件中，相关指令如下：

   ```shell
   .\dd.exe if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
   ```

5. 打开 Bochs 2.7 ，修改配置文件，将刚才制作的虚拟软盘镜像文件加入到 Bochs 创建的虚拟机中，并将配置文件保存为 bochsrc.bxrc ，以便后面的调试中使用。

## Day 2

在 Boot 引导程序中加入文件加载功能，以便可以将 Loader 程序的加载。为此，将软盘格式化成 FAT12 文件系统。

### FAT12 文件格式

* 引导扇区：

  FAT12 文件系统的引导扇区不仅包含有引导程序，还有 FAT12 文件系统的整个组成结构信息。

* FAT 表

* 根目录区和数据区

> Todo: 理解有关 FAT12 文件系统的细节，并类比其实现机理将文件系统进行从 FAT12 到 FAT16 的替换。

由于对于汇编语言不是很熟练，将书上的代码抄下来后并没有出现应有的警告字样，猜测是由于后续代码的添加位置不合理导致，于是利用 Bochs 文件夹中的 bochsdbg.exe 进行调试。

加载配置文件 bochsrc.bxrc 完毕后，与 Bochs 的使用方法一样，点击 Start 按钮开始模拟，调试指令及输出信息在 Console 窗口中进行。

所需输入指令如下：

```shell
b 0x7C00
c
```

其中 b 0x7c00 是添加断点， c 命令可以使汇编程序继续进行直到遇到断点。

这样虚拟机就会停留在引导扇区的第一条指令上，然后就可以进行调试了。

可能会用到的调试命令：

* c 继续执行直到遇到断点；
* n 单步执行，跳过子程序和int中断程序；
* s 单步执行；
* s num （s指令后加一数字）执行n步；
* info r|reg|rigisters 展示寄存器内容；
* info cpu 展示CPU寄存器内容；

最后，

1. 将 Func_ReadOneSector 函数段移动到 jmp short Label_Start 与 Label_Start 函数段之间，只作为函数调用，而不会被程序顺序执行；
2. 将 reset floppy 部分注释掉，因为这部分代码对于引导的进行并没有起到任何作用，而且其中的 jmp $ 会令程序进入死循环中，无法进行 Loader 程序的加载；
3. 作为保险，依旧将 fill zero... 部分放置在程序最后。

## Day 3

复习昨天的 FAT12 文件系统的具体实现流程。

首先更正一个 BUG ，BS_OEMName 部分只能声明为一个长度为 8 的字符串，否则挂载镜像文件时无法检测文件系统类型。

由于当前环境为 Windows 10 ，故书中指导的 mount 命令无法直接使用，经网络查找后无果。

使用 ImDisk 将 boot.img 挂载在 img 文件夹下，直接将写好的 loader.bin 文件拷贝到 img 文件夹中，启动 bochs 虚拟机测试运行成功。
