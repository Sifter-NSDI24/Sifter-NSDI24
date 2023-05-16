-------------------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
--
-- Description: Creates a Synchronous FIFO made out of registers.
--              Generic: g_WIDTH sets the width of the FIFO created.
--              Generic: g_DEPTH sets the depth of the FIFO created.
--
--              Total FIFO register usage will be width * depth
--              Note that this fifo should not be used to cross clock domains.
--              (Read and write clocks NEED TO BE the same clock domain)
--
--              FIFO Full Flag will assert as soon as last word is written.
--              FIFO Empty Flag will assert as soon as last word is read.
--
--              FIFO is 100% synthesizable.  It uses assert statements which do
--              not synthesize, but will cause your simulation to crash if you
--              are doing something you shouldn't be doing (reading from an
--              empty FIFO or writing to a full FIFO).
--
--              No Flags = No Almost Full (AF)/Almost Empty (AE) Flags
--              There is a separate module that has programmable AF/AE flags.
-------------------------------------------------------------------------------
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity xpm_fifo_sync is
  generic (
      DOUT_RESET_VALUE    : string;
      ECC_MODE            : string;
      FIFO_MEMORY_TYPE    : string;
      FIFO_READ_LATENCY   : integer;
      FIFO_WRITE_DEPTH    : integer;
      FULL_RESET_VALUE    : integer;
      PROG_EMPTY_THRESH   : integer;
      PROG_FULL_THRESH    : integer;
      RD_DATA_COUNT_WIDTH : integer;
      READ_DATA_WIDTH     : integer;
      READ_MODE           : string;
      SIM_ASSERT_CHK      : integer; 
      USE_ADV_FEATURES    : string;
      WAKEUP_TIME         : integer;
      WRITE_DATA_WIDTH    : integer;
      WR_DATA_COUNT_WIDTH : integer
    );
    port (
      almost_empty  : out std_logic;     -- 1-bit output: Almost Empty : When asserted, this signal indicates that
                                         -- only one more read can be performed before the FIFO goes to empty.

      almost_full   : out std_logic;     -- 1-bit output: Almost Full: When asserted, this signal indicates that
                                         -- only one more write can be performed before the FIFO is full.

      data_valid    : out std_logic;     -- 1-bit output: Read Data Valid: When asserted, this signal indicates
                                         -- that valid data is available on the output bus (dout).

      dbiterr       : out std_logic;     -- 1-bit output: Double Bit Error: Indicates that the ECC decoder
                                         -- detected a double-bit error and data in the FIFO core is corrupted.

      dout          : out std_logic_vector(READ_DATA_WIDTH-1 downto 0) ;         -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                         -- when reading the FIFO.

      empty         : out std_logic;     -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                                         -- the FIFO is empty. Read requests are ignored when the FIFO is empty,
                                         -- initiating a read while empty is not destructive to the FIFO.

      full          : out std_logic;     -- 1-bit output: Full Flag: When asserted, this signal indicates that the
                                         -- FIFO is full. Write requests are ignored when the FIFO is full,
                                         -- initiating a write when the FIFO is full is not destructive to the
                                         -- contents of the FIFO.

      overflow      : out std_logic;     -- 1-bit output: Overflow: This signal indicates that a write request
                                         -- (wren) during the prior clock cycle was rejected, because the FIFO is
                                         -- full. Overflowing the FIFO is not destructive to the contents of the
                                         -- FIFO.

      prog_empty    : out std_logic;     -- 1-bit output: Programmable Empty: This signal is asserted when the
                                         -- number of words in the FIFO is less than or equal to the programmable
                                         -- empty threshold value. It is de-asserted when the number of words in
                                         -- the FIFO exceeds the programmable empty threshold value.

      prog_full     : out std_logic;     -- 1-bit output: Programmable Full: This signal is asserted when the
                                         -- number of words in the FIFO is greater than or equal to the
                                         -- programmable full threshold value. It is de-asserted when the number
                                         -- of words in the FIFO is less than the programmable full threshold
                                         -- value.

      rd_data_count : out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0); -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates
                                         -- the number of words read from the FIFO.

      rd_rst_busy   : out std_logic;     -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO
                                         -- read domain is currently in a reset state.

      sbiterr       : out std_logic;     -- 1-bit output: Single Bit Error: Indicates that the ECC decoder
                                         -- detected and fixed a single-bit error.

      underflow     : out std_logic;     -- 1-bit output: Underflow: Indicates that the read request (rd_en)
                                         -- during the previous clock cycle was rejected because the FIFO is
                                         -- empty. Under flowing the FIFO is not destructive to the FIFO.

      wr_ack        : out std_logic;     -- 1-bit output: Write Acknowledge: This signal indicates that a write
                                         -- request (wr_en) during the prior clock cycle is succeeded.

      wr_data_count : out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0); -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                         -- the number of words written into the FIFO.

      wr_rst_busy   : out std_logic;     -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                         -- write domain is currently in a reset state.

      din           : in  std_logic_vector(WRITE_DATA_WIDTH-1 downto 0); -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                         -- writing the FIFO.

      injectdbiterr : in  std_logic;      -- 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                         -- the ECC feature is used on block RAMs or UltraRAM macros.

      injectsbiterr : in std_logic;      -- 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                         -- the ECC feature is used on block RAMs or UltraRAM macros.

      rd_en         : in std_logic;      -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                         -- signal causes data (on dout) to be read from the FIFO. Must be held
                                         -- active-low when rd_rst_busy is active high.

      rst           : in std_logic;      -- 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                         -- unstable at the time of applying reset, but reset must be released
                                         -- only after the clock(s) is/are stable.

      sleep         : in std_logic;      -- 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                                         -- block is in power saving mode.

      wr_clk        : in std_logic;      -- 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                         -- free running clock.

      wr_en         : in std_logic       -- 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                         -- signal causes data (on din) to be written to the FIFO Must be held
                                         -- active-low when rst or wr_rst_busy or rd_rst_busy is active high
    );
end xpm_fifo_sync;
 
architecture rtl of xpm_fifo_sync is
 
  type t_FIFO_DATA is array (0 to FIFO_WRITE_DEPTH-1) of std_logic_vector(WRITE_DATA_WIDTH-1 downto 0);
  signal r_FIFO_DATA : t_FIFO_DATA := (others => (others => '0'));
 
  --signal r_WR_INDEX   : integer range -1 to FIFO_WRITE_DEPTH-1 := 0;
  --signal r_RD_INDEX   : integer range -1 to FIFO_WRITE_DEPTH-1 := 0;
  signal r_WR_INDEX   : unsigned(WR_DATA_COUNT_WIDTH - 2 downto 0);
  signal r_RD_INDEX   : unsigned(RD_DATA_COUNT_WIDTH - 2 downto 0);
     
begin
 
  p_CONTROL : process (wr_clk) is
  begin
    if rising_edge(wr_clk) then
      if rst = '1' then
        wr_data_count <= (others => '0');
        rd_data_count <= (others => '0');
        r_WR_INDEX    <= (others => '0');
        r_RD_INDEX    <= (others => '0');
--        data_valid    <= '0';
      else
--        data_valid    <= '0';
        
        -- Keeps track of the total number of words in the FIFO
        if (wr_en = '1' and rd_en = '0') then
          wr_data_count <= std_logic_vector(unsigned(wr_data_count) + 1);
        elsif (wr_en = '0' and rd_en = '1') then
          rd_data_count <= std_logic_vector(unsigned(rd_data_count) + 1);
        end if;
 
        -- Keeps track of the write index (and controls roll-over)
        if (wr_en = '1' and full = '0') then
          if r_WR_INDEX = FIFO_WRITE_DEPTH-1 then
            r_WR_INDEX <= (others => '0');
          else
            r_WR_INDEX <= r_WR_INDEX + 1;
          end if;
        end if;
 
        -- Keeps track of the read index (and controls roll-over)        
        if (rd_en = '1' and empty = '0') then
          if r_RD_INDEX = FIFO_WRITE_DEPTH-1 then
            r_RD_INDEX <= (others => '0');
          else
            r_RD_INDEX <= r_RD_INDEX + 1;
          end if;
--          dout <= r_FIFO_DATA(r_RD_INDEX);
--          data_valid <= '1';
        end if;
 
        -- Registers the input data when there is a write
        if wr_en = '1' then
          r_FIFO_DATA(to_integer(r_WR_INDEX)) <= din;
        end if;
         
      end if;                           -- sync reset
    end if;                             -- rising_edge(i_clk)
  end process p_CONTROL;
    
  full  <= '1' when r_WR_INDEX = r_RD_INDEX-1 else '0';
  empty <= '1' when r_WR_INDEX = r_RD_INDEX   else '0';
  dout  <= r_FIFO_DATA(to_integer(r_RD_INDEX));
  data_valid <= not empty;
   
  -- ASSERTION LOGIC - Not synthesized
  -- synthesis translate_off
 
  p_ASSERT : process (wr_clk) is
  begin
    if rising_edge(wr_clk) then
      if wr_en = '1' and full = '1' then
        report "ASSERT FAILURE - MODULE_REGISTER_FIFO: FIFO IS FULL AND BEING WRITTEN " severity failure;
      end if;
 
      if rd_en = '1' and empty = '1' then
        report "ASSERT FAILURE - MODULE_REGISTER_FIFO: FIFO IS EMPTY AND BEING READ " severity failure;
      end if;
    end if;
  end process p_ASSERT;
 
  -- synthesis translate_on
end rtl;


