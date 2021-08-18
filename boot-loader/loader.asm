org		10000h

	jmp		Label_Start

%include 	"fat12.inc"
RootDirSectors				equ 	14
SectorNumOfRootDirStart 	equ 	19
SectorNumOfFAT1Start		equ 	1
SectorBalance				equ 	17

BaseOfKernelFile		equ		0x00
OffsetOfKernelFile		equ		0x100000

BaseTmpOfKernelAddr		equ		0x00
OffsetTmpOfKernelFile	equ		0x7e00

MemoryStructBufferAddr	equ		0x7e00

;=======	read one sector from floppy
Func_ReadOneSector:

	push 	bp
	mov		bp, 	sp
	sub		esp,	2
	mov 	byte	[bp - 2],	cl
	push	bx
	mov		bl,		[BPB_SecPerTrk]
	div		bl
	inc		ah
	mov		cl, 	ah
	mov		dh,		al
	shr		al, 	1
	mov		ch, 	al
	and		dh,		1
	pop		bx
	mov		dl, 	[BS_DrvNum]
Label_Go_On_Reading:
	mov		ah,		2
	mov		al,		byte	[bp - 2]
	int 	13h
	jc		Label_Go_On_Reading
	add		esp,	2
	pop		bp
	ret


;=======	display on screen : Start Loader
[SECTION .s16]
[BITS 16]

Label_Start:
	mov		ax,		cs
	mov		ds,		ax
	mov		es,		ax
	mov		ax,		0x00
	mov		ss,		ax
	mov		sp,		0x7c00
;=======	display on screen : Start Loading

	mov		ax,		1301h
	mov		bx,		000fh
	mov 	dx,		0200h		;row 2
	mov		cx,		13
	push	ax
	mov		ax,		ds
	mov		es,		ax
	pop		ax
	mov		bp,		StartLoaderMessage
	int 	10h

;======= 	open address A20
	push	ax
	in		al,		92h
	or		al,		00000010b
	out		92h,	al
	pop		ax

	cli

	db		0x66
	lgdt	[GdtPtr]

	mov		eax,	cr0
	or		eax,	1
	mov		cr0,	eax

	mov		ax,		SelectorData32
	mov		fs,		ax
	mov		eax,	cr0
	and		al,		11111110b
	mov		cr0,	eax

	sti

;======= search kernel.bin
	mov 	word	[SectorNo], 	SectorNumOfRootDirStart

Lable_Search_In_Root_Dir_Begin:

	cmp		word	[RootDirSizeForLoop],	0
	jz		Label_No_KernelBin
	dec		word	[RootDirSizeForLoop]
	mov		ax,		00h
	mov		es,		ax
	mov		bx,		8000h
	mov		ax,		[SectorNo]
	mov		cl,		1
	call 	Func_ReadOneSector
	mov		si, 	KernelFileName
	mov		di,		8000h
	cld
	mov		dx,		10h

Label_Search_For_KernelBin:

	cmp		dx,		0
	jz		Label_Goto_Next_Sector_In_Root_Dir
	dec		dx
	mov		cx,		11

Label_Cmp_FileName:

	cmp		cx,		0
	jz		Label_FileName_Found
	dec		cx
	lodsb
	cmp		al,		byte	[es:di]
	jz		Label_Go_On
	jmp		Label_Different

Label_Go_On:

	inc		di
	jmp		Label_Cmp_FileName

Label_Different:

	and		di,  	0ffe0h
	add		di,		20h
	mov		si,		KernelFileName
	jmp		Label_Search_For_KernelBin

Label_Goto_Next_Sector_In_Root_Dir:

	add		word	[SectorNo],		1
	jmp		Lable_Search_In_Root_Dir_Begin

;=======	display on screen : ERROR: No KERNEL Found

Label_No_KernelBin:

	mov		ax, 	1301h
	mov		bx,		008ch
	mov		dx,		0300h
	mov		cx,		22
	push	ax
	mov		ax,		ds
	mov		es,		ax
	pop 	ax
	mov		bp,		NoKernelMessage
	int 	10h
	jmp		$

;======= 	get FAT Entry
Func_GetFATEntry:

	push	es
	push	bx
	push	ax
	mov		ax,		00
	mov		es,		ax
	pop		ax
	mov		byte	[Odd],		0
	mov 	bx,		3
	mul		bx
	mov		bx,		2
	div		bx
	cmp		dx,		0
	jz		Label_Even
	mov		byte	[Odd],		1

Label_Even:

	xor		dx,		dx
	mov		bx,		[BPB_BytesPerSec]
	div		bx
	push	dx
	mov		bx,		8000h
	add		ax,		SectorNumOfFAT1Start
	mov		cl,		2
	call	Func_ReadOneSector

	pop		dx
	add		bx,		dx
	mov		ax,		[es:bx]
	cmp		byte	[Odd], 		1
	jnz		Label_Even_2
	shr		ax,		4

Label_Even_2:
	and 	ax,		0fffh
	pop		bx
	pop		es
	ret

;======= 	found kernel.bin name in root director struct

Label_FileName_Found:
	mov		ax,		RootDirSectors
	and		di, 	0ffe0h
	add 	di,		01ah
	mov		cx,		word	[es:di]
	push	cx
	add 	cx,		ax
	add		cx,		SectorBalance
	mov		eax,	BaseTmpOfKernelAddr		;BaseOfKernelFile
	mov		es,		eax
	mov		bx,		OffsetTmpOfKernelFile		;OffsetOfKernelFile
	mov		ax,		cx

Label_Go_On_Loading_File:
	push 	ax
	push	bx
	mov		ah,		0eh
	mov		al,		'.'
	mov		bl,		0fh
	int 	10h
	pop		bx
	pop		ax

	mov		cl,		1
	call	Func_ReadOneSector
	pop		ax

;;;;;;;;;;;;;;;;;;;;;;;;
	push	cx
	push	eax
	push	fs
	push	edi
	push	ds
	push	esi

	mov		cx,		200h
	mov		ax,		BaseOfKernelFile
	mov		fs,		ax
	mov		edi,	dword	[OffsetOfKernelFileCount]

	mov		ax,		BaseTmpOfKernelAddr
	mov		ds,		ax
	mov		esi,	OffsetTmpOfKernelFile

Label_Mov_Kernel:
	mov		al,		byte	[ds:esi]
	mov 	byte	[fs:edi],	al

	inc		esi
	inc		edi

	loop Label_Mov_Kernel

	mov		eax,	0x1000
	mov		ds,		eax

	mov		dword 	[OffsetOfKernelFileCount], 		edi

	pop 	esi
	pop		ds
	pop		edi
	pop 	fs
	pop		eax
	pop		cx

;;;;;;;;;;;;;;;;;;;;;;;;

	call	Func_GetFATEntry
	cmp		ax,		0fffh
	jz		Label_File_Loaded
	push	ax
	mov		dx,		RootDirSectors
	add		ax,		dx
	add		ax,		SectorBalance
	add		bx,		[BPB_BytesPerSec]
	jmp		Label_Go_On_Loading_File

Label_File_Loaded:

	mov		ax,		0b800h
	mov 	gs,		ax
	mov		ah,		0fh		; 0000: Black Background	1111: White Foreground
	mov		al,		'G'
	mov		[gs:((80 * 0 + 39) * 2)], 	ax		; row 0, column 39

;=======	get memory address size type
	mov		ax,		1301h
	mov		bx,		000fh
	mov 	dx,		0400h		;row 4
	mov		cx,		24
	push	ax
	mov		ax,		ds
	mov		es,		ax
	pop		ax
	mov		bp,		StartGetMemStructMessage
	int 	10h

	mov		ebx,	0
	mov		ax,		0x00
	mov		es,		ax
	mov		di,		MemoryStructBufferAddr

KillMotor:
	push	bx
	mov		dx,		03f2h
	mov		al,		0
	out		dx,		al
	pop		dx

Label_Get_Mem_Struct:

	mov		eax,	0x0e820
	mov		ecx,	20
	mov		edx,	0x534d4150
	int 	15h
	jc		Label_Get_Mem_Fail
	add		di,		20
	cmp		ebx,	0
	jne		Label_Get_Mem_Struct
	jmp		Label_Get_Mem_OK

Label_Get_Mem_Fail:
	mov		ax,		1301h
	mov		bx,		008ch
	mov 	dx,		0500h		;row 5
	mov		cx,		24
	push	ax
	mov		ax,		ds
	mov		es,		ax
	pop		ax
	mov		bp,		GetMemStructErrMessage
	int 	10h
	jmp		$

Label_Get_Mem_OK:
	mov		ax,		1301h
	mov		bx,		000fh
	mov 	dx,		0600h		;row 6
	mov		cx,		29
	push	ax
	mov		ax,		ds
	mov		es,		ax
	pop		ax
	mov		bp,		GetMemStructOKMessage
	int 	10h

;	jmp		Init_IDT

	jmp		Label_SET_SVGA_Mode_VESA_VBE

[SECTION .s16lib]
[BITS 16]
;======= 	display num in al
Label_DispAL:

	push 	ecx
	push	edx
	push	edi

	mov		edi,	[DisplayPosition]
	mov		ah,		0fh
	mov		dl,		al
	shr		al,		4
	mov		ecx,	2
.begin:

	and		al, 	0fh
	cmp		al,		9
	ja		.1
	add		al,		'0'
	jmp		.2
.1:

	sub		al,		0ah
	add		al,		'A'
.2:	
	mov		[gs:edi], 	ax
	add 	edi,	2

	mov		al,		dl
	loop	.begin

	mov		[DisplayPosition], 	edi

	pop		edi
	pop		edx
	pop		ecx

	ret

;=======	set the SVGA mode(VESA VBE)
Label_SET_SVGA_Mode_VESA_VBE:

	mov		ax,		4f02h
	mov		bx,		4143h	;========================= mode : 0x180 or 0x143
	int 	10h

	cmp		ax,		004fh
	jnz		Label_SET_SVGA_Mode_VESA_VBE_FAIL
	jmp 	Label_SET_SVGA_Mode_VESA_VBE_OK

Label_SET_SVGA_Mode_VESA_VBE_FAIL:
	mov		ax,		1301h
	mov		bx,		008ch
	mov 	dx,		0700h		;row 7
	mov		cx,		18
	push	ax
	mov		ax,		ds
	mov		es,		ax
	pop		ax
	mov		bp, 	SetSVGAModeErrMessage
	int 	10h

	jmp		$

Label_SET_SVGA_Mode_VESA_VBE_OK:
	mov		ax,		1301h
	mov		bx,		000fh
	mov 	dx,		0800h		;row 8
	mov		cx,		25
	push	ax
	mov		ax,		ds
	mov		es,		ax
	pop		ax
	mov		bp,		SetSVGAModeOKMessage
	int 	10h

	jmp 	Init_IDT

[SECTION gdt]

LABEL_GDT:				dd		0,0
LABEL_DESC_CODE32:		dd		0x0000ffff,0x00cf9a00
LABEL_DESC_DATA32:		dd		0x0000ffff,0x00cf9200

GdtLen		equ		$ - LABEL_GDT
GdtPtr		dw		GdtLen - 1
			dd		LABEL_GDT

SelectorCode32		equ		LABEL_DESC_CODE32 - LABEL_GDT
SelectorData32		equ		LABEL_DESC_DATA32 - LABEL_GDT

;======= 	tmp IDT
IDT:
	times	0x50	dq		0
IDT_END:

IDT_POINTER:
		dw		IDT_END - IDT - 1
		dd		IDT

;=======	init IDT GDT goto protect mode
Init_IDT:

	cli		;======= close interrupt

	db		0x66
	lgdt	[GdtPtr]

	db		0x66
	lidt 	[IDT_POINTER]

	mov		eax,	cr0
	or		eax,	1
	mov		cr0,	eax

	jmp 	dword 	SelectorCode32:GO_TO_TMP_Protect

[SECTION gdt64]

LABEL_GDT64:		dq		0x0000000000000000
LABEL_DESC_CODE64:	dq		0x0020980000000000
LABEL_DESC_DATA64:	dq		0x0000920000000000

GdtLen64		equ		$ - LABEL_GDT64
GdtPtr64		dw		GdtLen64 - 1
				dd		LABEL_GDT64

SelectorCode64		equ		LABEL_DESC_CODE64 - LABEL_GDT64
SelectorData64		equ		LABEL_DESC_DATA64 - LABEL_GDT64

[SECTION .s32]
[BITS 32]

GO_TO_TMP_Protect:

;=======	go to tmp long mode

	mov		ax,		0x10
	mov		ds,		ax
	mov		es,		ax
	mov		fs,		ax
	mov		ss,		ax
	mov		esp,	7e00h

	call 	support_long_mode
	test	eax,	eax

	jz		no_support

;=======	init template page table 0x90000

	mov 	dword 	[0x90000], 	0x91007
	mov		dword	[0x90800],	0x91007
	
	mov		dword 	[0x91000], 	0x92007

	mov 	dword 	[0x92000],	0x000083
	mov		dword	[0x92008],	0x200083
	mov		dword 	[0x92010], 	0x400083
	mov		dword	[0x92018],	0x600083
	mov		dword	[0x92020],	0x800083
	mov		dword	[0x92028],	0xa00083
;======= 	load GDTR

	db		0x66
	lgdt	[GdtPtr64]
	mov		ax,		0x10
	mov		ds,		ax
	mov		es,		ax
	mov		fs,		ax
	mov		gs,		ax
	mov		ss,		ax

	mov		esp,	7e00h

;======= 	open PAE
	mov		eax,	cr4
	bts		eax,	5
	mov		cr4,	eax

;=======	load cr3
	mov		eax,	0x90000
	mov		cr3,	eax

;=======	enable long-mode
	mov		ecx,	0c0000080h		; IA32_EFER
	rdmsr

	bts		eax,	8
	wrmsr

;=======	open PE and paging
	mov		eax,	cr0
	bts		eax,	0
	bts		eax,	31
	mov		cr0,	eax

;=======	sent an message before turn to kernel
	; mov 	ax, 	1301h
	; mov		bx, 	000fh
	; mov 	dx, 	0800h
	; mov 	cx, 	32
	; push	ax
	; mov 	ax, 	ds
	; mov		es, 	ax
	; pop		ax
	; mov 	bp, 	EnterKernelMessage
	; int 	10h
	; mov		ax,		0b800h
	; mov 	gs,		ax
	; mov		ah,		0fh		; 0000: Black Background	1111: White Foreground
	; mov		al,		'o'
	; mov		[gs:((80 * 0 + 40) * 2)], 	ax		; row 0, column 39

	jmp		SelectorCode64:OffsetOfKernelFile

;=======	test support long mode or not
support_long_mode:

	mov		eax,	0x80000000
	cpuid
	cmp		eax,	0x80000001
	setnb			al
	jb		support_long_mode_done
	mov		eax,	0x80000001
	cpuid
	bt		edx,	29
	setc			al

support_long_mode_done:

	movzx	eax, 	al
	ret
;======= 	no support

no_support:
	jmp 	$

;=======	tmp variable

RootDirSizeForLoop	dw		RootDirSectors
SectorNo			dw		0
Odd					db		0

OffsetOfKernelFileCount 	db		0
DisplayPosition				db		0

;=======	display messages

StartLoaderMessage:			db		"Start Loading"
NoKernelMessage:			db		"ERROR: No KERNEL Found"
KernelFileName:				db		"KERNEL  BIN",0
StartGetMemStructMessage:	db		"Start Get Memory Struct."
GetMemStructErrMessage:		db		"Get Memory Struct ERROR!"
GetMemStructOKMessage:		db		"Get Memory Struct SUCCESSFUL!"
SetSVGAModeErrMessage:		db		"Set SVGA Mode ERR!"
SetSVGAModeOKMessage:		db		"Set SVGA Mode SUCCESSFUL!"
EnterKernelMessage:			db		"Kernel is ready."