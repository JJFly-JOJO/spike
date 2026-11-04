static const char message[] = "Hello from PK syscall!\n";

__attribute__((noreturn)) void _start(void)
{
    register long a0 __asm__("a0") = 1;
    register const char *a1 __asm__("a1") = message;
    register long a2 __asm__("a2") = sizeof(message) - 1;
    register long a7 __asm__("a7") = 64; /* write */
    __asm__ volatile("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7) : "memory");

    a0 = 0;
    a7 = 93; /* exit */
    __asm__ volatile("ecall" : : "r"(a0), "r"(a7) : "memory");
    __builtin_unreachable();
}
