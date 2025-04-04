; void xor_cipher(char *data, int size, char *key, int key_size);
; xor_cipher(rdi data, rsi size, rdx key, rcx key_size);
xor_cipher:
	xor r8, r8					; i_key = 0;
	push rbp				; nop
	pop rbp					; ...
	xor r9, r9					; i_data = 0;

	.loop:
		cmp r9, rsi, 			; if (i_data == size)
		je .end					; 	goto .end

		mov r10, rdx			; cur_key_ptr = key
		add r10, r8				; + i_key;
		mov bl, [r10]			; bl = *cur_key_ptr

		mov r10, rdi			; cur_data_ptr = data
		add r10, r9				; + i_data;
		push rbp				; nop
		pop rbp					; ...
		mov al, [r10]			; al = *cur_data_ptr

		xor al, bl				; al ^= bl
		mov [r10], al			; *cur_data_ptr = al

		inc r8					; i_key++;
		inc r9					; i_data++;

		cmp r8, rcx,			; if (i_key == key_size)
		je .key_reset			; 	goto .key_reset

		jmp .loop				; goto .loop

	.key_reset:
		xor r8, r8				; restore key
		jmp .loop				; goto .loop

	.end:
		ret					; return
