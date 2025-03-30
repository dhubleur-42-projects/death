push r11
push rax
pop r11
pop rax

push r10
push rdi
pop r10
pop rdi

push r9
push rsi
pop r9
pop rsi

push r8
push rax	; nop
pop rax		; ...
push rdx
pop r8
nop		; nop
pop rdx

push rbx
push rcx
inc rbp		; nop
dec rbp		; ...
pop rbx
dec rbp		; nop
inc rbp		; ...
pop rcx
nop		; nop

push r11
add rbp, 8	; nop
sub rbp, 8	; ...
push r10
add rbp, 8	; nop
sub rbp, 8	; ...
dec rbp		; nop
inc rbp		; ...
push r9
push r8
nop		; nop
push rbx
push rcx
push rdx
push rsi
push rdi
push rax
