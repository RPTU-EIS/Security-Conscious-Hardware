# CVA6 Serial Division Unit

Original Repository (accessed 31/05/2023):  
https://github.com/openhwgroup/cva6

## Timing behaviour

The serial division module features four different types of operation:  
 - Unsigned Division (UDIV)
 - Signed Division (DIV)
 - Unsigned Remainder (UREM)
 - Signed Remainder (REM)

An overview of the operation timing is shown in the table below.  
Latency is measured as the number of clock cycles between asserting *in_vld_i* and *out_rdy_o*.  

| Operation    | Condition                              | Latency             | Max. Latency |
|--------------|----------------------------------------|---------------------|--------------|
| UDIV \| UREM | lzc(x) <= lzc(y) && b != 0             | lzc(y) - lzc(x) + 2 | WIDTH + 1    |
|              | lzc(x) >  lzc(y) && b != 0             | 1                   | 1            |
|              | b == 0                                 | WIDTH + 2           | WIDTH + 2    |
| DIV \| REM   | lzc(x) <= lzc(y) && b $\notin$ {0, -1} | lzc(y) - lzc(x) + 2 | WIDTH + 1    |
|              | lzc(x) >  lzc(y) && b $\notin$ {0, -1} | 1                   | 1            |
|              | b ==  0                                | WIDTH + 2           | WIDTH + 2    |
|              | b == -1                                | WIDTH + 2           | WIDTH + 2    |

Legend:  
 - x is {~a[WIDTH-2:0], 1'b0} if a < 0, otherwise x is a.
 - y is ~b if b < 0, otherwise y is b.
 - The *WIDTH* parameter specifies the width of the operands.  
 - The *lzc* function returns the number of leading zeros.  
