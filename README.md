To run simulations:

Required packages:
- Python 3.8 or higher
- cocotb 1.7.2 (https://www.cocotb.org)

Instructions:
- cd Sifter-sim/tb
- make TESTCASE=fixed370 # To run the fixed size 370-byte packet test
- make TESTCASE=rand370  # To run the variable size packet test w/ 370 bytes min size packets


To run Vivado:

Required packages:
- Vivado 2921.2
- Enyx nxFramework 5.9.1
- Enyx nxFramework 5.9.1 license

Instructions:
To run Vivado:
- cd Sifter-hw/src
- cp *.vhd <enyx example designs dir>/hw/cores/hdl/smartnic/src
- cd <enyx example designs dir>/hw/build
- make firmware_u250-smartnic

To run the hw test:
- cd Sifter-hw/src
- cp *.cpp <enyx example designs dir>/sw/enyx-hw-mmio-test
- cd <enyx example designs dir>/sw/enyx-hw-mmio-test
- mkdir build
- cd build
- cmake3 ..
- make
- ./enyx-hw-mmio-test
