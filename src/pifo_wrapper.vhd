-- PIFO wrapper module
-- TO DO:


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.log2;
--use work.gb_package.all;

entity pifo_wrapper is
  generic (
    g_L2_PIFO_SIZE     : integer;    -- log2 of size
    g_PIFO_DATA_WIDTH  : integer;    -- Descriptor width
    g_RANK_LSB         : integer;    -- Rank least significant bit in PIFO data word
    g_RANK_WIDTH       : integer     -- Bit width of rank
  );
  port (
    rst                              : in  std_logic;
    clk                              : in  std_logic;
    vc_update                        : in  std_logic;
    vc                               : in  unsigned(g_RANK_WIDTH-1 downto 0);
    enq_wr                           : in  std_logic;
    enq_wr_data                      : in  std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
    ovfl_wr                          : in  std_logic;
    ovfl_wr_data                     : in  std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
    rld_wr                           : in  std_logic;
    rld_wr_data                      : in  std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
    rld_wr_done                      : out std_logic;
    mig_wr                           : in  std_logic;
    mig_wr_data                      : in  std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
    mig_wr_done                      : out std_logic;
    pop_cmd                          : in  std_logic;
    pop_data                         : out std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
    pop_data_valid                   : out std_logic;
    evicted_data                     : out std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
    evicted_data_valid               : out std_logic;
    max_rank                         : out unsigned(g_RANK_WIDTH-1 downto 0);
    max_rank_valid                   : out std_logic;
    fill_level                       : out unsigned(g_L2_PIFO_SIZE downto 0);
    empty                            : out std_logic;
    full                             : out std_logic
  );
end pifo_wrapper;

architecture pifo_wrapper_arch of pifo_wrapper is
  component pifo
    generic (
      g_L2_PIFO_SIZE     : integer;    -- log2 of size
      g_PIFO_DATA_WIDTH  : integer;     -- Descriptor width
      g_RANK_LSB         : integer;    -- Rank least significant bit in PIFO data word
      g_RANK_WIDTH       : integer     -- Bit width of rank
    );
    port (
      rst                              : in  std_logic;
      clk                              : in  std_logic;
      push_cmd                         : in  std_logic;
      push_data                        : in  std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
      pop_cmd                          : in  std_logic;
      pop_data                         : out std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
      pop_valid                        : out std_logic;
      evicted_data                     : out std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
      evicted_valid                    : out std_logic;
      max_rank                         : out unsigned(g_RANK_WIDTH-1 downto 0);
      max_rank_valid                   : out std_logic;
      fill_level                       : out unsigned(g_L2_PIFO_SIZE downto 0);
      empty                            : out std_logic;
      full                             : out std_logic
    );
  end component;
  
  
  constant PIFO_SIZE : positive := 2**g_L2_PIFO_SIZE;

  signal enq_busy       : std_logic;
  signal enq_wr_l       : std_logic;
  signal enq_wr_data_l  : std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
  signal ovfl_wr_l      : std_logic;
  signal ovfl_wr_data_l : std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
  signal ovfl_busy      : std_logic;
  signal rld_wr_l       : std_logic;
  signal rld_wr_data_l  : std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
  signal rld_busy       : std_logic;
  signal mig_wr_l       : std_logic;
  signal mig_wr_data_l  : std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
  signal mig_busy       : std_logic;
  signal busy           : std_logic;
  signal busy_d1        : std_logic;
  signal pifo_push      : std_logic;
  signal pifo_push_data : std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
  signal pifo_valid  : std_logic_vector(PIFO_SIZE-1 downto 0);
  signal insert_idx  : integer range 0 to PIFO_SIZE-1;
  signal insert_idx_found: boolean;
  signal push_rank   : unsigned(g_RANK_LSB+g_RANK_WIDTH-1 downto 0);

begin

  -- Arbiter process
  -- enq: wr pifo, wr fifo, evict: wr fifo
  -- ovf: wr pifo, wr fifo, evict: wr fifo
  -- deq: rd pifo OR rd fifo (depending on level)
  -- rel: rd fifo, wr pifo, evict: wr fifo (can we get stuck in a loop?)
  -- mig: rd fifo, wr pifo, evict: wr fifo (can we get stuck in a loop?)
  p_pifo_arbiter: process(rst, clk)
  begin
    if rst = '1' then
      pifo_push <= '0';
      enq_busy  <= '0';
      ovfl_busy <= '0';
      rld_busy  <= '0';
      mig_busy  <= '0';
      busy_d1   <= '0';
      rld_wr_done <= '0';
      mig_wr_done <= '0';
    elsif clk'event and clk = '1' then
      pifo_push <= '0';
      enq_busy  <= '0';
      ovfl_busy <= '0';
      rld_busy  <= '0';
      mig_busy  <= '0';
      rld_wr_done <= '0';
      mig_wr_done <= '0';
      
      if enq_wr = '1' then
        enq_wr_l       <= '1';
	enq_wr_data_l  <= enq_wr_data;
      end if;
      if ovfl_wr = '1' then
        ovfl_wr_l      <= '1';
        ovfl_wr_data_l <= ovfl_wr_data;
      end if;
      if rld_wr = '1' then
        rld_wr_l      <= '1';
        rld_wr_data_l <= rld_wr_data;
      end if;
      if mig_wr = '1' then
        mig_wr_l      <= '1';
        mig_wr_data_l <= mig_wr_data;
      end if;
      
      if enq_wr_l = '1' then
        if busy = '0' then
          pifo_push <= '1';
	  -- If vc is ahead of desc finish time, update it
	  if (unsigned(enq_wr_data_l(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB)) < vc) then
	    pifo_push_data <= enq_wr_data_l(g_PIFO_DATA_WIDTH-1 downto g_RANK_LSB+g_RANK_WIDTH) &
			      std_logic_vector(vc) & enq_wr_data_l(g_RANK_LSB-1 downto 0);
	  else
            pifo_push_data <= enq_wr_data_l;
	  end if;
	  enq_wr_l <= enq_wr;
	  enq_busy <= '1';
        end if;

      elsif enq_wr = '1' then
        if busy = '0' then
          pifo_push <= '1';
	  if (unsigned(enq_wr_data(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB)) < vc) then
	    pifo_push_data <= enq_wr_data(g_PIFO_DATA_WIDTH-1 downto g_RANK_LSB+g_RANK_WIDTH) &
			      std_logic_vector(vc) & enq_wr_data(g_RANK_LSB-1 downto 0);
	  else
            pifo_push_data <= enq_wr_data;
	  end if;
	  enq_wr_l <= '0';
          enq_busy  <= '1';
        end if;
        
      elsif ovfl_wr_l = '1' then
        if busy = '0' then
          pifo_push <= '1';
          pifo_push_data <= ovfl_wr_data_l;
          ovfl_wr_l <= ovfl_wr;
          ovfl_busy <= '1';
        end if;
        
      elsif ovfl_wr = '1' then
        if busy = '0' then
          pifo_push <= '1';
          pifo_push_data <= ovfl_wr_data;
          ovfl_wr_l <= '0';
          ovfl_busy <= '1';
        end if;
      
      elsif rld_wr_l = '1' then
        if busy = '0' then
          pifo_push <= '1';
          pifo_push_data <= rld_wr_data_l;
          rld_wr_l  <= rld_wr;
          rld_busy <= '1';
        end if;
      
      elsif rld_wr = '1' then
        if busy = '0' then
          pifo_push <= '1';
          pifo_push_data <= rld_wr_data;
          rld_wr_l  <= '0';
          rld_busy <= '1';
        end if;
        
      elsif mig_wr_l = '1' then
        if busy = '0' then
          pifo_push <= '1';
          pifo_push_data <= mig_wr_data_l;
          mig_wr_l <= mig_wr;
          mig_busy <= '1';
        end if;
        
      elsif mig_wr = '1' then
        if busy = '0' then
          pifo_push <= '1';
          pifo_push_data <= mig_wr_data;
          mig_wr_l  <= '0';
          mig_busy <= '1';
        end if;
              
      end if;
      
      if busy = '1' then -- busy assignment is below
        if busy_d1 = '0' then
          busy_d1 <= '1';
          if rld_busy = '1' then
            rld_wr_done <= '1';
          end if;
          if mig_busy = '1' then
            mig_wr_done <= '1';
          end if;
        end if;
      else
        busy_d1 <= '0';
      end if;
    end if;
  end process p_pifo_arbiter;
  busy <= enq_busy or ovfl_busy or rld_busy or mig_busy;
  
    i_pifo_inst: pifo
    generic map (
      g_L2_PIFO_SIZE     => g_L2_PIFO_SIZE,    -- integer
      g_PIFO_DATA_WIDTH  => g_PIFO_DATA_WIDTH, -- Descriptor width
      g_RANK_LSB         => g_RANK_LSB,        -- Rank least significant bit in PIFO data word
      g_RANK_WIDTH       => g_RANK_WIDTH       -- Bit width of rank
    )
    port map (
      rst                => rst,
      clk                => clk,
      push_cmd           => pifo_push,
      push_data          => pifo_push_data,
      pop_cmd            => pop_cmd,
      pop_data           => pop_data,
      pop_valid          => pop_data_valid,
      evicted_data       => evicted_data,
      evicted_valid      => evicted_data_valid,
      max_rank           => max_rank,
      max_rank_valid     => max_rank_valid,
      fill_level         => fill_level,
      empty              => empty,
      full               => full
    );

end pifo_wrapper_arch;
