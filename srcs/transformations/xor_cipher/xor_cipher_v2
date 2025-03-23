; void xor_cipher(char *data, int size, char *key, int key_size);
; xor_cipher(rdi data, rsi size, rdx key, rcx key_size);
xor_cipher:
	push rcx					; save key_size

	.loop:
		cmp rcx, 0				; if (key_size == 0)
		je .key_reset				; 	goto .key_reset

		cmp rsi, 0				; if (size == 0)
		je .end					; 	goto .end

		mov r8b, [rdi]				; al = *data
		mov r9b, [rdx]				; bl = *key
		xor r8b, r9b				; al ^= bl
		mov [rdi], r8b				; *data = al

		dec rsi					; size--
		inc rdx					; key++
		inc rdi					; data++
		dec rcx					; key_size--

		jmp .loop				; goto .loop

	.key_reset:
		pop rcx					; restore key_size
		push rcx				; ...
		sub rdx, rcx			; restore key
		jmp .loop				; goto .loop

	.end:
		pop rcx					; reset stack
		ret					; return
