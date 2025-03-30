nop		; nop
push rax
sub rsp, 24
inc rbp		; nop
dec rbp		; ...
mov [rsp + 8], rsi
mov [rsp + 16], rdi
nop		; nop
mov [rsp], rdx
push rcx
push rbx
sub rsp, 32
inc rbp		; nop
dec rbp		; ...
dec rbp		; nop
inc rbp		; ...
push rax	; nop
pop rax		; ...
mov [rsp], r11
nop		; nop
mov [rsp + 16], r9
inc rbp		; nop
dec rbp		; ...
mov [rsp + 24], r8
nop		; nop
dec rbp		; nop
inc rbp		; ...
nop		; nop
mov [rsp + 8], r10
