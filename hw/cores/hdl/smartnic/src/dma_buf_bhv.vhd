-- (c) Copyright 1995-2021 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:ip:dist_mem_gen:8.0
-- IP Revision: 13

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity dma_buf is
  generic (
    ADDR_WIDTH  : integer := 10;    -- log2 of number of flows
    DATA_WIDTH : integer := 20     -- VC bit width
  );
  port (
    a    : IN  STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    d    : IN  STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    dpra : IN  STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    clk  : IN  STD_LOGIC;
    we   : IN  STD_LOGIC;
    dpo  : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
  );
END dma_buf;

ARCHITECTURE dma_buf_arch OF dma_buf IS
type ram_type is array (0 to 2**ADDR_WIDTH - 1) of std_logic_vector (DATA_WIDTH-1 downto 0);
signal RAM : ram_type := (others => (others => '0'));

begin

  process (clk)
    begin
      if rising_edge(clk) then
        if we = '1' then
          RAM(to_integer(unsigned(a))) <= d;
        end if;
        dpo <= RAM(to_integer(unsigned(dpra)));
      end if;
  end process;
END dma_buf_arch;
