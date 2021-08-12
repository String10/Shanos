BaseOfStack		equ		0x7c00
BaseOfLoader	equ 	0x1000
OffsetOfLoader	equ		0x00

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
;=======	display on screen : Start Booting

	mov 	ax, 	1301h
	mov		bx, 	000fh
	mov 	dx, 	0800h
	mov 	cx, 	32
	push	ax
	mov 	ax, 	ds
	mov		es, 	ax
	pop		ax
	mov 	bp, 	EnterKernelMessage
	int 	10h

	jmp 	$

;=======	display message

EnterKernelMessage:		db		"Kernel is ready."