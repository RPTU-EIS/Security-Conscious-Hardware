# BasicRSA

Original Repository (accessed 30/05/2023): \
https://opencores.org/projects/basicrsa \
https://github.com/freecores/BasicRSA

The BasicRSA module computes the modular exponentiation *(b^e) % mod* required for the RSA cryptosystem. \
It computes the exponentiation in a square-and-multiply fashion:

    result = (e[0] ? b^1 : 1) * (e[1] ? b^2 : 1) * (e[2] ? b^4 : 1) * ... 

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


## Timing Behavior (Optimized Design)

| Module    | Min. Latency | Latency                                                        | Max. Latency            |
|-----------|--------------|----------------------------------------------------------------|-------------------------|
| modmult   | 2            | WIDTH + 1 - max{lzc(mpand[WIDTH-1:1]), lzc(mplier[WIDTH-1:1])} | WIDTH + 1               |
| rsacypher | 4            | -                                                              | WIDTH^2 + 2 * WIDTH + 1 |

Two changes have been done in the modmult design:
 - The latency now depends on the smaller operand instead of the mplier alone. 
 - The result is already available one cycle earlier, except for when one operand is 0. \
   Therefore, we now stop the operation as soon as the value of the shifted register is 0 **or 1**, reducing the average and maximum latency by one cycle. 

These changes also reduce the minimum and maximum latency of the rsacypher module by one cycle per required operation.


## Timing Behavior (Security-Conscious Design)

### Modular Multiplication (modmult)

The basic idea to achieve a performance optimization base in the modmult component is to use the public operand for shifting. 
This means that, in case there is one public and one confidential operand, the public operand is chosen to be the multiplier, i.e., the factor that is shifted and thus dictates the timing.
The confidential operand is the multiplicand that does not influence the timing behavior. \
If both operands are public, we choose the smaller operand for the shifting as this results in a better performance (cf. the table above).
If both operands are confidential, we trigger an additional counter to ensure that the maximum latency is met before providing the result.

### Modular Exponentiation (rsacypher)

In the square-and-multiply algorithm, the exponent determines the number of modular multiplications (MMs) to be performed. 
Furthermore, in our design, the latency of each MM depends on the intermediate results that provide the operands for the suboperation.

The first performance improvement is therefore to optimize the number of MMs whenever there is a public exponent. 
However, in case of a confidential exponent, the maximum number of MMs (WIDTH) have to be performed.

As mentioned, the length of each MM depends on the intermediate result. 
Since the intermediate result depends on all three operands, an optimizations seems not possible on first glance.
However, this is only true for the modmult instance M_i computing the intermediate result, the modmult instance for squaring M_s is simply fed back its result and thus independent of the exponent. \
An important observation now is that *the latency of M_i can never be larger than the latency of M_s*.
This is because, for all iterations k, one input of M_i is either 1 (if e[k] is 0) or has the same value as the inputs of M_s (b^2^k).
If the operand is 1, M_i can finish with the minimum latency of 2 clock cycles.
If the operand is the same as both operands of M_s, then both modules can finish simultaneously, if they optimize based on this operand. \
As a result, if *b* and *mod* are public, we can optimize the latency for the individual MMs. 
The overall timing is then dictated by WIDTH optimized squaring operations. 

In case only the base *b* is public but the modulus *mod* is confidential, we can only optimize the first squaring operation.
After this initial MM, the result of the squaring operation is confidential, as its value depends on the modulus.

We summarize the possible performance optimizations in the table below:

| b_label | e_label | mod_label | Optimization                                |
|:-------:|:-------:|:---------:|---------------------------------------------|
| 0       | 0       | 0         | original performance                        |
| 0       | 0       | 1         | faster initial MM and reduced number of MMs |
| 0       | 1       | 0         | individual MMs can be optimized             |
| 0       | 1       | 1         | faster initial MM                           |
| 1       | 0       | 0         | reduced number of MMs                       |
| 1       | 0       | 1         | reduced number of MMs                       |
| 1       | 1       | 0         | worst-case latency                          |
| 1       | 1       | 1         | worst-case latency                          |
