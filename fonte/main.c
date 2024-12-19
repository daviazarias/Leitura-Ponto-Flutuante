#include <stdio.h>

extern void ler_float(float *);

int main(void)
{
    float f;

    ler_float(&f);
    printf("%f\n", f);

    return 0;
}

