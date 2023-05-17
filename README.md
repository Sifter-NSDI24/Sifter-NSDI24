# This is the VHDL implementation of Sifter hardware prototype

## To run simulations:

### Required packages:
- Python 3.8 or higher
- cocotb 1.7.2 (https://www.cocotb.org)
- GHDL 3.0.0 (https://github.com/ghdl/ghdl/releases)

### Instructions:
- cd Sifter-NSDI24/tb
- make TESTCASE=fixed370 # To run the fixed size 370-byte packet test
- make TESTCASE=rand370  # To run the variable size packet test w/ 370 bytes min size packets

### To run Vivado:
### Required packages:
- Vivado 2021.2
- Enyx nxFramework 5.9.1 (https://www.enyx.com/downloads/)
- Enyx nxFramework 5.9.1 license

### Instructions:
- Download Enyx nxFramework example designs
- Copy Sifter-NSDI2024/hw/config/u250-smartnic/firmware_config.yaml to
  <enyx_example>/hw/config/u250-smartnic/
- Copy Sifter-NSDI2024/hw/cores/hdl/smartnic/src/*.vhd to
  <enyx_example>/hw/cores/hdl/smartnic/src/
To run Vivado:
- cd <enyx_example>/hw/build
- make firmware_u250-smartnic

### Vivado outputs:
- FPGA bitstream: Sifter-NSDI2024/hw/build/output/u250-smartnic/compil_0/synth_00/build/output
- Vivado logs:    Sifter-NSDI2024/hw/build/output/u250-smartnic/compil_0/synth_00/build/logs
- Vivado reports: Sifter-NSDI2024/hw/build/output/u250-smartnic/compil_0/synth_00/build/reports

### To run the hw test:
- Target: AMD/Xilinx Alveo U250 FPGA card
- Program the .bit file using the Vivado hardware manager or follow Enyx's instructions for
  first time setup of the U250 SmartNIC card and then program the flash memory using the .rbf
  using Enyx's enyx-bsp instructions
- Copy Sifter-NSDI2024/sw/enyx-hw-mmio-test/main.cpp to <enyx_example>/sw/enyx-hw-mmio-test/
- Copy Sifter-NSDI2024/sw/enyx-hw-mmio-test/data/* to <enyx_example>/sw/enyx-hw-mmio-test/data
- cd <enyx_example>/sw/enyx-hw-mmio-test
- mkdir build
- cd build
- cmake3 ..
- make
- ./enyx-hw-mmio-test

The test to run is configured on line 25 of main.cpp as follows:

const std::string TEST_NAME = "rand370";

The test reads the following files:
- <test_name>.conf for Sifter's configuration
- <test_name>.enq, containing the input descriptors

The format of the <test_name>.enq file is as follows:

|    | F1 | F2 | F3 | F4 | F5 |
| -- | -- | -- | -- | -- | -- |
|  V | 27 | 997| 27 | 0  | 1  |

- F1: Delta delay from previous packet in clocks
- F2: Length of packets in bytes
- F3: Transmission time of packet in clocks
- F4: Flow ID
- F5: Packet ID within flow

The test writes the following files:
- <test_name>.deq, containing the scheduled descriptors
- <test_name>.ovfl, containing the overflow descriptors

The format of the <test_name>.deq and <test_name>.ovfl files is as follows:

| F1 | F2 | F3 | F4 | F5 |
| -- | -- | -- | -- | -- |
|1402| 370| 10 | 2  | 1  |

- F1: Timestamp of descriptor in clocks since reset
- F2: Length of packets in bytes
- F3: Transmission time of packet in clocks
- F4: Flow ID
- F5: Packet ID within flow
