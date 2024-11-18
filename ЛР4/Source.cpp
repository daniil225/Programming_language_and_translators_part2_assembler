#include <iostream>
#include <iomanip>
#include <cmath>
#include <stdio.h>

# define M_PI           3.14159265358979323846  /* pi */
extern "C" double f(double x);

double f_check(double x)
{
    double res = 0.0;
    double arg1 = std::tan(x);

    if (std::abs(arg1) <= 1e-15)
    {
        res = 1.0 / res;
    }
    else if (std::fabs(arg1) >= 1e+15)
    {
        res = 0.0;
    }
    else
    {
        res = 1.0/arg1;
    }

    return  res - 2 * x;
}


int main() {

    double values[] = { 0, M_PI / 4, M_PI / 2, 3*M_PI/4.0, M_PI};

    for (double x : values) {
        double result = f(x);
        printf("f(%.5lf) = %8.5lf  f control(%.5lf) = %8.5lf\n", x, f(x), x, f_check(x));
    }
    return 0;
}