int main(void)
{
int a, b; /* Initialized elsewhere */
while (a!=b)
{ /* Assume a, b > 0 */
if (a>b)
a = a - b;
else
b = b - a;
}
return 0; /* a and b both hold the result */
}