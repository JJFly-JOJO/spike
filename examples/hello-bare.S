    .section .text
    .globl _start
_start:
    li t0, 10
    li t1, 20
    add t2, t0, t1
    li t3, 30
    bne t2, t3, fail
    li a0, 1               # HTIF exit code 0: (0 << 1) | 1
    j finish
fail:
    li a0, 3               # HTIF exit code 1: (1 << 1) | 1
finish:
    la t0, tohost
    sd a0, 0(t0)
1:  j 1b

    .section .tohost,"aw",@progbits
    .align 3
    .globl tohost
tohost:
    .dword 0
    .globl fromhost
fromhost:
    .dword 0
