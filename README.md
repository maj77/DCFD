# DCFD
Implementation of digital constant fraction discriminator on FPGA.
RTL has its matlab model which can generate input waves and calculate expected results with the same fxp precision as in RTL.


## Top level block diagram 
![image](https://github.com/maj77/DCFD/blob/experiment/block_diagrams/CFD_top.svg)

## Modules used in design:
### zc_interp.sv 
Module performs interpolation between two samples. It is based on formula: clocks = abs(neg_sample)*T / (abs(neg_sample)+pos_sample)
![image](https://github.com/maj77/DCFD/blob/experiment/block_diagrams/zero_cross_v2.svg)

