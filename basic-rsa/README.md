# BasicRSA

Original Repository (accessed 30/05/2023): \
https://opencores.org/projects/basicrsa \
https://github.com/freecores/BasicRSA

The BasicRSA module computes the modular exponentiation *(b^e) % mod* required for the RSA cryptosystem. \
It computes the exponentiation in a square-and-multiply fashion:

    result = 1 * (e[0] * b^1) * (e[1] * b^2) * (e[2] * b^4) * ... 

The module uses two instances of a modular multiplication module, one for squaring and on for calculating the intermediate result. \
It computes the following equation using a shift-and-add algorithm:

    product = (mpand * mplier) % mod


The following notation is used:  
 - b, e and mod denote the base, exponent and modulus
 - mpand and mplier denote the multiplicand and multiplier of the modmult submodule
 - The *WIDTH* parameter specifies the width of the operands.  
 - The *lzc* function returns the number of leading zeros.  

## Timing Behavior (Original Design)

| Module    | Min. Latency | Latency                 | Max. Latency            |
|-----------|--------------|-------------------------|-------------------------|
| modmult   | 2            | WIDTH + 2 - lzc(mplier) | WIDTH + 2               |
| rsacypher | 5            | -                       | WIDTH^2 + 3 * WIDTH + 1 |

The latency of the modmult module depends on the number of leading zeros of the multiplier and can range between 2 and WIDTH + 2 clock cycles. \
Since the latency of the rsacypher module is much more complicated, there is no simple explicit formula. 
Instead, we present the minimum and maximum latency.
The minimum latency consists of one cycle initial setup, a three cycle modmult operation with a *mplier* of 1 and another single cycle overhead for preparing the operands.
The worst case latency consists of WIDTH modmult operations with a WIDTH + 2 latency. 
In addition, there is an overhead of one clock cycle between each multiplication plus the setup clock cycles at the beginning and end.
Therefore, the maximum number of clock cycles is:

    Max. Latency = WIDTH * (WIDTH+2) + (WIDTH-1) + 2 = WIDTH^2 + 3 * WIDTH + 1

These latencies have been confirmed with formal verificaiton. 