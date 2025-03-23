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
push rdx
pop r8
pop rdx

push rbx
push rcx
pop rbx
pop rcx

sub rsp, 80
mov [rsp + 32], rcx
mov [rsp + 48], r8
mov [rsp + 8], rdi
mov [rsp + 16], rsi
mov [rsp + 40], rbx
mov [rsp + 56], r9
mov [rsp], rax
mov [rsp + 24], rdx
mov [rsp + 72], r11
mov [rsp + 64], r10
