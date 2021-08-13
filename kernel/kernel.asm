	org 	100000h
	
	mov		ax,		0b800h
	mov 	gs,		ax
	mov		ah,		0fh		; 0000: Black Background	1111: White Foreground
	mov		al,		'o'
	mov		[gs:((80 * 0 + 41) * 2)], 	ax		; row 0, column 41

	mov		ax,		0b800h
	mov 	gs,		ax
	mov		ah,		0fh		; 0000: Black Background	1111: White Foreground
	mov		al,		'd'
	mov		[gs:((80 * 0 + 42) * 2)], 	ax		; row 0, column 42

	jmp		$