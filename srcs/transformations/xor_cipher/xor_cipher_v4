; void xor_cipher(char *data, int size, char *key, int key_size);
; xor_cipher(rdi data, rsi size, rdx key, rcx key_size);
xor_cipher:
	mov r9, 0					; i_key = 0;
	mov r10, 0					; i_data = 0;

	.loop:
		cmp r10, rsi 			; if (i_data == size)
		je .end					; 	goto .end

		mov r8, rdx				; cur_key_ptr = key
		add r8, r9				; + i_key;
		mov bl, [r8]			; bl = *cur_key_ptr

		inc r9					; i_key++;

		mov r8, rdi				; cur_data_ptr = data
		add r8, r10				; + i_data;

		inc r10					; i_data++;

		xor [r8], bl			; *cur_data_ptr ^= bl

		cmp r9, rcx				; if (i_key == key_size) //This if is for je, some lines below. Shuffling code
		je .key_reset			; 	goto .key_reset

		jmp .loop				; goto .loop

	.key_reset:
		mov r9, 0				; restore key
		jmp .loop				; goto .loop

	.end:
		ret					; return
