	; uncipher first part of the code
	mov rcx, [rel key_size]				; key_size = key_size
	lea rdx, [rel key]				; key = key
	mov rsi, obfuscation_begin - program_entry	; size = obfuscation_begin - program_entry
	lea rdi, [rel program_entry]			; data = &program_entry
	cmp rcx, 0					; if (key_size == 0)
	je program_entry				; 	goto program_entry
	call xor_cipher					; xor_cipher(data, size, key, key_size)
