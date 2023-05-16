-- PIFO wrapper module
-- TO DO:


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.log2;
--use work.gb_package.all;

entity fifo_wrapper is
  generic (
    g_IS_LEVEL0        : boolean;    -- True if instantiated in level 0
    g_L2_FIFO_SIZE     : integer;    -- log2 of size
    g_FIFO_DATA_WIDTH  : integer;    -- Descriptor width
    g_RANK_LSB         : integer;    -- Rank least significant bit in PIFO data word
    g_RANK_WIDTH       : integer     -- Bit width of rank
  );
  port (
    rst                              : in  std_logic;
    clk                              : in  std_logic;
    enq_wr                           : in  std_logic;
    enq_wr_data                      : in  std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
    evct_wr                          : in  std_logic;
    evct_wr_data                     : in  std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
    rld_wr                           : in  std_logic;
    rld_wr_data                      : in  std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
    mig_wr                           : in  std_logic;
    mig_wr_data                      : in  std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
    ovfl_wr                          : in  std_logic;
    ovfl_wr_data                     : in  std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
    deq_rd                           : in  std_logic;
    deq_rd_data                      : out std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
    deq_rd_data_valid                : out std_logic;
    rld_rd                           : in  std_logic;
    rld_rd_data                      : out std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
    rld_rd_data_valid                : out std_logic;
    mig_rd                           : in  std_logic;
    mig_rd_data                      : out std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
    mig_rd_data_valid                : out std_logic;
    fill_level                       : out unsigned(g_L2_FIFO_SIZE downto 0);
    empty                            : out std_logic;
    full                             : out std_logic
  );
end fifo_wrapper;

architecture fifo_wrapper_arch of fifo_wrapper is
component xpm_fifo_sync
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
end component;
  

  --constant FIFO_SIZE : positive := 2**g_L2_FIFO_SIZE;

  signal enq_wr_l       : std_logic;
  signal enq_wr_data_l  : std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
  signal evct_wr_l      : std_logic;
  signal evct_wr_data_l : std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
  signal rld_wr_l       : std_logic;
  signal rld_wr_data_l  : std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
  signal mig_wr_l       : std_logic;
  signal mig_wr_data_l  : std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
  signal ovfl_wr_l      : std_logic;
  signal ovfl_wr_data_l : std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
  signal deq_rd_d1      : std_logic;
  signal rld_rd_d1      : std_logic;
  signal mig_rd_d1      : std_logic;
  signal deq_rd_l       : std_logic;
  signal rld_rd_l       : std_logic;
  signal mig_rd_l       : std_logic;
  signal deq_rd_busy    : std_logic;
  signal rld_rd_busy    : std_logic;
  signal mig_rd_busy    : std_logic;
  signal rd_busy        : std_logic;
  signal fifo_push      : std_logic;
  signal fifo_push_data : std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
  signal fifo_pop       : std_logic;
  signal fifo_pop_data  : std_logic_vector(g_FIFO_DATA_WIDTH-1 downto 0);
  signal fifo_pop_data_valid  : std_logic;
  signal fifo_wr_data_count : std_logic_vector(g_L2_FIFO_SIZE downto 0);
  signal fifo_rd_data_count : std_logic_vector(g_L2_FIFO_SIZE downto 0);
  signal deq_rd_op      : std_logic;
  signal mig_rd_op      : std_logic;
  signal rld_rd_op      : std_logic;

begin

  -- Arbiter process
  -- enq: wr pifo, wr fifo, evict: wr fifo
  -- ovf: wr pifo, wr fifo, evict: wr fifo
  -- deq: rd pifo OR rd fifo (depending on level)
  -- rel: rd fifo, wr pifo, evict: wr fifo (can we get stuck in a loop?)
  -- mig: rd fifo, wr pifo, evict: wr fifo (can we get stuck in a loop?)
  p_fifo_arbiter: process(rst, clk)
  begin
    if rst = '1' then
      fifo_push   <= '0';
      fifo_pop    <= '0';
      deq_rd_d1   <= '0';
      rld_rd_d1   <= '0';
      mig_rd_d1   <= '0';
      deq_rd_busy <= '0';
      rld_rd_busy <= '0';
      mig_rd_busy <= '0';
      deq_rd_l    <= '0';
    elsif clk'event and clk = '1' then
      fifo_push <= '0';
      fifo_pop  <= '0';
      deq_rd_d1 <= '0';
      rld_rd_d1 <= '0';
      mig_rd_d1 <= '0';

      if evct_wr = '1' then
        evct_wr_l      <= '1';
        evct_wr_data_l <= evct_wr_data;
      end if;
      if rld_wr = '1' then
        rld_wr_l       <= '1';
        rld_wr_data_l  <= rld_wr_data;
      end if;
      if mig_wr = '1' then
        mig_wr_l       <= '1';
        mig_wr_data_l  <= mig_wr_data;
      end if;
      if ovfl_wr = '1' then
        ovfl_wr_l      <= '1';
        ovfl_wr_data_l <= ovfl_wr_data;
      end if;
      if rld_rd = '1' then
        rld_rd_l      <= '1';
      end if;
      if mig_rd = '1' then
        mig_rd_l      <= '1';
      end if;
      
      -- Write arbitration        
      if enq_wr = '1' then
        fifo_push <= '1';
        fifo_push_data <= enq_wr_data;
        
      elsif evct_wr_l = '1' then
        fifo_push <= '1';
        fifo_push_data <= evct_wr_data_l;
        evct_wr_l <= '0';
        
      elsif evct_wr = '1' then
        fifo_push <= '1';
        fifo_push_data <= evct_wr_data;
        evct_wr_l <= '0';

      elsif rld_wr_l = '1' then
        fifo_push <= '1';
        fifo_push_data <= rld_wr_data_l;
        rld_wr_l <= '0';
        
      elsif rld_wr = '1' then
        fifo_push <= '1';
        fifo_push_data <= rld_wr_data;
        rld_wr_l <= '0';

      elsif mig_wr_l = '1' then
        fifo_push <= '1';
        fifo_push_data <= mig_wr_data_l;
        mig_wr_l <= '0';
        
      elsif mig_wr = '1' then
        fifo_push <= '1';
        fifo_push_data <= mig_wr_data;
        mig_wr_l <= '0';

      elsif ovfl_wr_l = '1' then
        fifo_push <= '1';
        fifo_push_data <= ovfl_wr_data_l;
        ovfl_wr_l <= '0';
        
      elsif ovfl_wr = '1' then
        fifo_push <= '1';
        fifo_push_data <= ovfl_wr_data;
        ovfl_wr_l <= '0';
              
      end if;
      
      -- Read arbitration
      if deq_rd_l = '1' then
        if rd_busy = '0' then
          fifo_pop <= '1';
	  deq_rd_d1 <= '1';
          deq_rd_l  <= deq_rd;
          deq_rd_busy <= '1';
        end if;
      
      elsif deq_rd = '1' then
        if rd_busy = '0' then
          fifo_pop <= '1';
	  deq_rd_d1 <= '1';
          deq_rd_l  <= '0';
          deq_rd_busy <= '1';
        end if;

      elsif rld_rd_l = '1' then
        if rd_busy = '0' then
          fifo_pop <= '1';
	  rld_rd_d1 <= '1';
          rld_rd_l  <= rld_rd;
          rld_rd_busy <= '1';
        end if;
      
      elsif rld_rd = '1' then
        if rd_busy = '0' then
          fifo_pop <= '1';
	  rld_rd_d1 <= '1';
          rld_rd_l  <= '0';
          rld_rd_busy <= '1';
        end if;
        
      elsif mig_rd_l = '1' then
        if rd_busy = '0' then
          fifo_pop <= '1';
	  mig_rd_d1 <= '1';
          mig_rd_l <= mig_rd;
          mig_rd_busy <= '1';
        end if;
        
      elsif mig_rd = '1' then
        if rd_busy = '0' then
          fifo_pop <= '1';
	  mig_rd_d1 <= '1';
          mig_rd_l  <= '0';
          mig_rd_busy <= '1';
        end if;
      end if;
	  
	  -- rd_busy processing
	  if deq_rd_d1 = '1' then
	    deq_rd_busy <= '0';
	  end if;
	  if rld_rd_d1 = '1' then
	    rld_rd_busy <= '0';
	  end if;
	  if mig_rd_d1 = '1' then
	    mig_rd_busy <= '0';
	  end if;
    end if;
  end process p_fifo_arbiter;

  rd_busy <= deq_rd_busy or rld_rd_busy or mig_rd_busy;
   
  i_xpm_fifo_sync : xpm_fifo_sync
  generic map (
    DOUT_RESET_VALUE    => "0",                  -- String
    ECC_MODE            => "no_ecc",             -- String
    FIFO_MEMORY_TYPE    => "auto",               -- String
    FIFO_READ_LATENCY   => 1,                    -- DECIMAL
    FIFO_WRITE_DEPTH    => 2**g_L2_FIFO_SIZE,    -- DECIMAL
    FULL_RESET_VALUE    => 0,                    -- DECIMAL
    PROG_EMPTY_THRESH   => 10,                   -- DECIMAL
    PROG_FULL_THRESH    => 10,                   -- DECIMAL
    RD_DATA_COUNT_WIDTH => g_L2_FIFO_SIZE+1,     -- DECIMAL
    READ_DATA_WIDTH     => g_FIFO_DATA_WIDTH,    -- DECIMAL
    READ_MODE           => "fwft",               -- String
    SIM_ASSERT_CHK      => 0,                    -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    USE_ADV_FEATURES    => "1404",               -- String
    WAKEUP_TIME         => 0,                    -- DECIMAL
    WRITE_DATA_WIDTH    => g_FIFO_DATA_WIDTH,    -- DECIMAL
    WR_DATA_COUNT_WIDTH => g_L2_FIFO_SIZE+1      -- DECIMAL
  )
  port map (
    almost_empty  => open,             -- 1-bit output: Almost Empty : When asserted, this signal indicates that
                                       -- only one more read can be performed before the FIFO goes to empty.
    almost_full   => open,             -- 1-bit output: Almost Full: When asserted, this signal indicates that
                                       -- only one more write can be performed before the FIFO is full.
    data_valid    => fifo_pop_data_valid,    -- 1-bit output: Read Data Valid: When asserted, this signal indicates
                                       -- that valid data is available on the output bus (dout).
    dbiterr       => open,             -- 1-bit output: Double Bit Error: Indicates that the ECC decoder
                                       -- detected a double-bit error and data in the FIFO core is corrupted.
    dout          => fifo_pop_data,    -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                       -- when reading the FIFO.
    empty         => empty,            -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                                       -- the FIFO is empty. Read requests are ignored when the FIFO is empty,
                                       -- initiating a read while empty is not destructive to the FIFO.
    full          => full,             -- 1-bit output: Full Flag: When asserted, this signal indicates that the
                                       -- FIFO is full. Write requests are ignored when the FIFO is full,
                                       -- initiating a write when the FIFO is full is not destructive to the
                                       -- contents of the FIFO.
    overflow      => open,             -- 1-bit output: Overflow: This signal indicates that a write request
                                       -- (wren) during the prior clock cycle was rejected, because the FIFO is
                                       -- full. Overflowing the FIFO is not destructive to the contents of the
                                       -- FIFO.
    prog_empty    => open,             -- 1-bit output: Programmable Empty: This signal is asserted when the
                                       -- number of words in the FIFO is less than or equal to the programmable
                                       -- empty threshold value. It is de-asserted when the number of words in
                                       -- the FIFO exceeds the programmable empty threshold value.
    prog_full     => open,             -- 1-bit output: Programmable Full: This signal is asserted when the
                                       -- number of words in the FIFO is greater than or equal to the
                                       -- programmable full threshold value. It is de-asserted when the number
                                       -- of words in the FIFO is less than the programmable full threshold
                                       -- value.
    rd_data_count => fifo_rd_data_count, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates
                                       -- the number of words read from the FIFO.
    rd_rst_busy   => open,             -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO
                                       -- read domain is currently in a reset state.
    sbiterr       => open,             -- 1-bit output: Single Bit Error: Indicates that the ECC decoder
                                       -- detected and fixed a single-bit error.
    underflow     => open,             -- 1-bit output: Underflow: Indicates that the read request (rd_en)
                                       -- during the previous clock cycle was rejected because the FIFO is
                                       -- empty. Under flowing the FIFO is not destructive to the FIFO.
    wr_ack        => open,             -- 1-bit output: Write Acknowledge: This signal indicates that a write
                                       -- request (wr_en) during the prior clock cycle is succeeded.
    wr_data_count => fifo_wr_data_count, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                       -- the number of words written into the FIFO.
    wr_rst_busy   => open,             -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                       -- write domain is currently in a reset state.
    din           => fifo_push_data,   -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                       -- writing the FIFO.
    injectdbiterr => '0',              -- 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                       -- the ECC feature is used on block RAMs or UltraRAM macros.
    injectsbiterr => '0',              -- 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                       -- the ECC feature is used on block RAMs or UltraRAM macros.
    rd_en         => fifo_pop,         -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                       -- signal causes data (on dout) to be read from the FIFO. Must be held
                                       -- active-low when rd_rst_busy is active high.
    rst           => rst,              -- 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                       -- unstable at the time of applying reset, but reset must be released
                                       -- only after the clock(s) is/are stable.
    sleep         => '0',              -- 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                                       -- block is in power saving mode.
    wr_clk        => clk,              -- 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                       -- free running clock.
    wr_en         => fifo_push         -- 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                       -- signal causes data (on din) to be written to the FIFO Must be held
                                       -- active-low when rst or wr_rst_busy or rd_rst_busy is active high
  );

  p_data_out: process(rst, clk)
  begin
    if rst = '1' then
	  deq_rd_op <= '0';
	  mig_rd_op <= '0';
	  rld_rd_op <= '0';	
	elsif clk'event and clk = '1' then
	  mig_rd_op <= '0';
	  if (mig_rd = '1' or mig_rd_l = '1') and not g_IS_LEVEL0 then
	    mig_rd_op <= '1';
	    rld_rd_op <= '0';
	    deq_rd_op <= '0';
	  end if;
	  if (rld_rd = '1' or rld_rd_l = '1') and not g_IS_LEVEL0 then
	    mig_rd_op <= '0';
	    rld_rd_op <= '1';
	    deq_rd_op <= '0';
	  end if;
	  if deq_rd = '1' or deq_rd_l = '1' then
	    mig_rd_op <= '0';
	    rld_rd_op <= '0';
	    deq_rd_op <= '1';
	  end if;
	end if;
  end process p_data_out;
  
  deq_rd_data <= fifo_pop_data when deq_rd_op = '1' or g_IS_LEVEL0
                               else (others => 'X');
  deq_rd_data_valid <= fifo_pop_data_valid when deq_rd_op = '1' or g_IS_LEVEL0
                                           else '0';
  mig_rd_data <= fifo_pop_data when mig_rd_op = '1'
                               else (others => 'X');
  mig_rd_data_valid <= fifo_pop_data_valid when mig_rd_op = '1'
                                           else '0';
  rld_rd_data <= fifo_pop_data when rld_rd_op = '1'
                               else (others => 'X');
  rld_rd_data_valid <= fifo_pop_data_valid when rld_rd_op = '1'
                                           else '0';
  
  fill_level <= unsigned(fifo_wr_data_count) - unsigned(fifo_rd_data_count);
  
end fifo_wrapper_arch;
