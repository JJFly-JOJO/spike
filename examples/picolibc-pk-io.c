#include <stdio.h>

static int pk_putc(char ch, FILE *stream)
{
    (void)stream;
    register long a0 __asm__("a0") = 1;
    register const char *a1 __asm__("a1") = &ch;
    register long a2 __asm__("a2") = 1;
    register long a7 __asm__("a7") = 64;
    __asm__ volatile("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7) : "memory");
    return a0 == 1 ? 0 : -1;
}

static FILE pk_stdout = FDEV_SETUP_STREAM(pk_putc, NULL, NULL, _FDEV_SETUP_WRITE);
FILE *const stdout = &pk_stdout;
FILE *const stderr = &pk_stdout;
FILE *const stdin = NULL;

extern int main(void);

__attribute__((noreturn)) void pk_main(void)
{
    register long a0 __asm__("a0") = main();
    register long a7 __asm__("a7") = 93;
    __asm__ volatile("ecall" : : "r"(a0), "r"(a7) : "memory");
    __builtin_unreachable();
}
