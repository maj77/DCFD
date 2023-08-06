# DCFD
Implementation of digital constant fraction discriminator on FPGA. \
NOTE: this project is still in development and a lot can change!

## Block Diagram 
![image](https://github.com/maj77/DCFD/blob/main/CFD_+_interpolator.drawio.svg)


## Modules used in design:

### Linear interpolation
Module performs interpolation between two samples. It is based on formula: $s = s_0 + t * (s_1 - s_0)$ from wikipedia: [Lerp wikipedia](https://en.wikipedia.org/wiki/Linear_interpolation#Programming_language_support)
![image](https://github.com/maj77/DCFD/blob/main/Interpolator.drawio.svg)
### Serializer
Module performs serialization of samples coming from linear interpolator, it works on $clk_{ser} = 1.5*clk$
