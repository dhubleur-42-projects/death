; void xor_cipher(char *data, int size, char *key, int key_size);
; xor_cipher(rdi data, rsi size, rdx key, rcx key_size);
xor_cipher:
	push rcx					; save key_size
	push rdx					; save key

	push rax					; nop
	pop rax						; ...

	.loop:
		cmp rsi, 0				; if (size == 0)
		je .end					; 	goto .end

		mov al, [rdi]				; al = *data
		mov bl, [rdx]				; bl = *key
		xor al, bl				; al ^= bl
		mov [rdi], al				; *data = al

		inc rdi					; data++
		inc rdx					; key++
		nop					; nop
		dec rsi					; size--
		dec rcx					; key_size--

		cmp rcx, 0				; if (key_size == 0)
		je .key_reset				; 	goto .key_reset
		push rax				; nop
		pop rax					; ...

		jmp .loop				; goto .loop

	.key_reset:
		mov rdx, [rsp]				; restore key
		mov rcx, [rsp + 8]			; ...
		push rax				; nop
		pop rax					; ...
		jmp .loop				; goto .loop

	.end:
		pop rdx					; reset stack
		pop rcx					; ...
		ret					; return
