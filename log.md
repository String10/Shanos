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

