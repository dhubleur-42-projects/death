nop		; nop
sub rsp, 80
mov [rsp + 48], rdx
inc rbp		; nop
dec rbp		; ...
mov [rsp], r11
mov [rsp + 64], rdi
nop		; nop
mov [rsp + 16], r9
inc rbp		; nop
dec rbp		; ...
push rax	; nop
pop rax		; ...
mov [rsp + 24], r8
mov [rsp + 32], rbx
nop		; nop
mov [rsp + 56], rsi
mov [rsp + 8], r10
inc rbp		; nop
dec rbp		; ...
push rax	; nop
pop rax		; ...
mov [rsp + 72], rax
nop		; nop
nop		; nop
nop		; nop
mov [rsp + 40], rcx
