# CVA6 Serial Division Unit

Original Repository (accessed 31/05/2023 - updated 16/06/2023):  
https://github.com/openhwgroup/cva6

The serial division module features four different types of operation:  
 - Unsigned Division (UDIV)
 - Signed Division (DIV)
 - Unsigned Remainder (UREM)
 - Signed Remainder (REM)

An overview of the operation timing of the different designs is shown in the tables below.  
Latency is measured as the number of clock cycles between asserting *in_vld_i* and *out_rdy_o*.  

The following notation is used:  
 - a and b denote the dividend and divisor, respectively
 - x is {~a[WIDTH-2:0], 1'b0} if a < 0, otherwise x is a.
 - y is ~b if b < 0, otherwise y is b.
 - The *WIDTH* parameter specifies the width of the operands.  
 - The *lzc* function returns the number of leading zeros.  
   If the input is 0, the result of *lzc* is WIDTH-1, not WIDTH


## Timing Behavior (Original Design)

| Operation    | Condition                              | Latency             | Max. Latency |
|--------------|----------------------------------------|---------------------|--------------|
| UDIV \| UREM | lzc(x) <= lzc(y) && b != 0             | lzc(y) - lzc(x) + 2 | WIDTH + 1    |
|              | lzc(x) >  lzc(y) && b != 0             | 1                   | 1            |
|              | b == 0                                 | WIDTH + 2           | WIDTH + 2    |
| DIV \| REM   | lzc(x) <= lzc(y) && b $\notin$ {0, -1} | lzc(y) - lzc(x) + 2 | WIDTH + 1    |
|              | lzc(x) >  lzc(y) && b $\notin$ {0, -1} | 1                   | 1            |
|              | b $\in$ {0, -1}                        | WIDTH + 2           | WIDTH + 2    |

In the original design, the latency usually depends on the difference of leading zeros in the operands.  
The only exceptions are the cases where the result is clearly zero (fast path) or when the divisor is 0 or -1 (in signed operations).  
A divisor of 0 or -1 causes the input of the leading zero counter to be 0, which then causes the counter to count for WIDTH cycles.


## Timing Behavior (Optimized Design)

| Operation    | Condition                              | Latency             | Max. Latency |
|--------------|----------------------------------------|---------------------|--------------|
| UDIV \| UREM | lzc(x) <= lzc(y) && b != 0             | lzc(y) - lzc(x) + 2 | WIDTH + 1    |
|              | lzc(x) >  lzc(y) && b != 0             | 1                   | 1            |
|              | **b == 0**                             | **1**               | **1**        |
| DIV \| REM   | lzc(x) <= lzc(y) && b $\notin$ {0, -1} | lzc(y) - lzc(x) + 2 | WIDTH + 1    |
|              | lzc(x) >  lzc(y) && b $\notin$ {0, -1} | 1                   | 1            |
|              | **b $\in$ {0, -1}**                    | **1**               | **1**        |

In a security-conscious design, the worst-case operand-dependent latency dictates the performance.  
This means that, in the original design, whenever b is confidential, the worst-case latency (WIDTH+2) must be assumed.  
As a consequence, we have optimized the design by adding fast paths to handle these cases.  
These changes were contributed to the CVA6 project and merged on June 16th 2023.


## Timing Behavior (Security-Conscious Design)

| op_a_label | op_b_label | Latency            | Max. Latency |
|:----------:|:----------:|--------------------|--------------|
| 0          | 0          | *Optimized Design* | WIDTH + 1    |
| 0          | 1          | WIDTH + 1 - lzc(x) | WIDTH + 1    |
| 1          | 0          | lzc(y) + 2         | WIDTH + 1    |
| 1          | 1          | WIDTH + 1          | WIDTH + 1    |

In the security-conscious design we introduce labels that indicate, whether or not an operand is public ("0") or confidential ("1").  
The design itself was changed such that latency never depends on confidential information.  
A dummy counter is introduced that delays the output until the specified latency is reached.  
If both operands are confidential, the worst-case latency must be taken.  
