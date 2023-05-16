-- gearbox_level module
-- ***** TO DO ******
-- Check where we should use g_L2_MIN_GRAN vs g_L2_FIFO_SIZE

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use IEEE.math_real.all;
--library xpm;
--use xpm.vcomponents.all;
--use work.gb_package.all;

entity sifter_level is
  generic (
    g_THIS_LEVEL        : integer;     -- This level's number
    g_L2_MIN_GRAN       : integer;     -- log2 of min granularity
    g_FIFO_NUM          : integer;     -- number of FIFOs
    g_L2_FIFO_NUM       : integer;     -- log2 of number of FIFOs
    g_L2_FIFO_SIZE      : integer;     -- log2 size (depth) of each FIFO
    g_L2_PIFO_SIZE      : integer;     -- log2 size (depth) of PIFO
    g_PIFO_LOW_THRESH   : integer;     -- low threshold of PIFO
    g_DESC_BIT_WIDTH    : integer;     -- Descriptor width
    g_RANK_LSB          : integer;     -- Rank LSB position within descriptor
    g_RANK_WIDTH        : integer;     -- Bit width of rank
    g_PKT_LEN_BIT_WIDTH : integer;     -- Bit width of packet length
    g_PKT_CNT_WIDTH     : integer      -- packet count width
  );
  port (
    rst                              : in  std_logic;
    clk                              : in  std_logic;
    
    -- enq i/f
    enq_cmd                          : in  std_logic;
    enq_desc                         : in  std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
    enq_done                         : out std_logic;
        
    -- deq i/f
    deq_cmd                          : in  std_logic;
    deq_desc                         : out std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
    deq_desc_valid                   : out std_logic;
        
    -- migrate i/f
    mig_in_cmd                       : in  std_logic;
    mig_in_desc                      : in  std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
    mig_in_done                      : out std_logic;
    mig_out_cmd                      : in  std_logic;
    mig_out_fifo                     : in  unsigned(g_L2_FIFO_NUM-1 downto 0);
    mig_out_desc                     : out std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
    mig_out_desc_valid               : out std_logic;
    
    -- virtual clock i/f
    vc                               : in  unsigned(g_RANK_WIDTH-1 downto 0);
    vc_update                        : in  std_logic;
 
    -- ovfl from lower level
    ovfl_in                          : in  std_logic;
    ovfl_desc_in                     : in  std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
    
    -- ovfl to upper level
    ovfl_out                         : out std_logic;
    ovfl_desc_out                    : out std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
   
    -- status ready i/f
    status_rdy                       : out std_logic;
    
    -- fifo count i/f
    get_fifo_cnts_cmd                : in  std_logic;
    get_fifo_cnts_index              : in  unsigned(g_L2_FIFO_NUM-1 downto 0);
    get_fifo_cnts_rsp                : out std_logic;
    fifo_pkt_cnt                     : out unsigned(g_L2_FIFO_SIZE downto 0);
    fifo_empty                       : out std_logic_vector(g_FIFO_NUM-1 downto 0);
    
    -- level count i/f (always valid)
    level_pkt_cnt                    : out unsigned(g_L2_FIFO_NUM+g_PKT_CNT_WIDTH-1 downto 0)

  );
end sifter_level;

architecture sifter_level_arch of sifter_level is

----------------
--  FUNCTION  --
----------------
function IS_LEVEL0(level : integer)
              return boolean is
begin
  if level = 0 then
    return true;
  else
    return false;
  end if;
end IS_LEVEL0;

----------------
-- COMPONENTS --
----------------
component fifo_wrapper
  generic (
    g_IS_LEVEL0        : boolean;    -- true when instantiated in level 0
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
end component;

component pifo_wrapper
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
end component;

-------------
--  TYPES  --
-------------
  type   t_dout_array            is array(0 to g_FIFO_NUM-1) of std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0); 
  type   t_pkt_cnt_array         is array(0 to g_FIFO_NUM-1) of unsigned(g_PKT_CNT_WIDTH-1 downto 0);
  type   t_fifo_fill_level_array is array(0 to g_FIFO_NUM-1) of unsigned(g_L2_FIFO_SIZE downto 0);
  type   t_upd_curr_fifo_state   is (IDLE, WAIT_FIFO_EMPTY_UPDATE, WAIT_EARLIEST_NON_EMPTY_FIFO);
  type   t_deq_state             is (IDLE, WAIT_POP_VALID);
  type   t_rld_state             is (IDLE, WAIT_FIND_EARLIEST_NON_EMPTY_FIFO_RSP, WAIT_FIFO_READ_READY, WAIT_PIFO_MAX_RANK_READY, WAIT_PIFO_WRITE_DONE, WAIT_FIFO_WRITE_DONE, CHECK_RELOAD_SIZE);

----------------
-- PROCEDURES --
----------------
  -- find earliest non-empty FIFO
  procedure find_earliest_non_empty_fifo (
    signal   clk                               : in std_logic;
    signal   find_next                         : in boolean;
    signal   fifo_empty                        : in std_logic_vector(g_FIFO_NUM-1 downto 0);
    signal   fifo_fill_level                   : t_fifo_fill_level_array;
    variable v_current_fifo_index              : in unsigned(g_L2_FIFO_NUM-1 downto 0);
    signal   find_earliest_non_empty_fifo_rsp  : out std_logic;
    signal   earliest_fifo_index               : out unsigned(g_L2_FIFO_NUM-1 downto 0);
    signal   all_fifos_empty                   : out std_logic) is
  
  variable v_earliest_found_left  : boolean := false;
  variable v_earliest_found_right : boolean := false;
  variable v_earliest_fifo_index  : integer range 0 to g_FIFO_NUM-1 := 0;
  begin
  --  if clk'event and clk = '1' then
      v_earliest_found_left  := false;
      v_earliest_found_right := false;
      for i in 0 to g_FIFO_NUM-1 loop
        if i < to_integer(v_current_fifo_index) and not v_earliest_found_left then
          if fifo_empty(i) = '0'  then
            v_earliest_fifo_index := i;
            v_earliest_found_left := true;
          end if;
        elsif i = to_integer(v_current_fifo_index) and not find_next then
          if fifo_empty(i) = '0' then
            v_earliest_fifo_index := i;
            v_earliest_found_right := true;
          end if;
        elsif i > to_integer(v_current_fifo_index) and not v_earliest_found_right then
            if fifo_empty(i) = '0' then
              v_earliest_fifo_index := i;
              v_earliest_found_right := true;
            end if;
        end if;    
      end loop;

      find_earliest_non_empty_fifo_rsp <= '1';
      earliest_fifo_index              <= to_unsigned(v_earliest_fifo_index, earliest_fifo_index'length);
      all_fifos_empty                  <= '1' when (not v_earliest_found_left and not v_earliest_found_right) else
                                          '0';
  --  end if;
  end procedure find_earliest_non_empty_fifo;

-------------
-- SIGNALS --
-------------

  signal current_fifo_index                   : unsigned(g_L2_FIFO_NUM-1 downto 0);
  signal deq_find_earliest_non_empty_fifo_rsp : std_logic;
  signal deq_earliest_fifo_index              : unsigned(g_L2_FIFO_NUM-1 downto 0);
  signal deq_all_fifos_empty                  : std_logic;
  signal deq_find_next                        : boolean;
  signal upd_wait_cnt                         : unsigned(0 downto 0);
  signal deq_wait_cnt                         : unsigned(0 downto 0);
  signal reload_fifo                          : unsigned(g_L2_FIFO_NUM-1 downto 0);
  signal reload_fifo_valid                    : std_logic;
  signal reload_fifo_busy                     : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal reload_size                          : unsigned(g_L2_FIFO_SIZE downto 0);
  signal reload_size_updated                  : std_logic;
  signal reload_count                         : unsigned(g_L2_FIFO_SIZE downto 0);
  signal mig_out_cmd_l                        : std_logic;
  signal mig_out_fifo_l                       : unsigned(g_L2_FIFO_NUM-1 downto 0);
  signal mig_out_fifo_valid                   : std_logic;
  signal rld_find_earliest_non_empty_fifo_rsp : std_logic;
  signal rld_earliest_fifo_index              : unsigned(g_L2_FIFO_NUM-1 downto 0);
  signal rld_all_fifos_empty                  : std_logic;
  signal rld_find_next                        : boolean;
  signal fifo_full                            : std_logic_vector(g_FIFO_NUM-1 downto 0);     -- FIFO full indicator arr
  signal fifo_pop                             : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal fifo_pop_d1                          : std_logic;
  signal fifo_pop_data                    : t_dout_array;
  signal fifo_pop_data_valid              : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal fifo_push                        : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal fifo_push_data                   : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal fifo_evct_wr                     : std_logic_vector(g_FIFO_NUM-1 downto 0) := (others => '0');
  signal fifo_ecvt_wr_data                : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0) := (others => '0');
  signal fifo_rld_wr                      : std_logic_vector(g_FIFO_NUM-1 downto 0) := (others => '0');
  signal fifo_rld_wr_data                 : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0) := (others => '0');
  signal fifo_mig_wr                      : std_logic_vector(g_FIFO_NUM-1 downto 0) := (others => '0');
  signal fifo_mig_wr_data                 : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0) := (others => '0');
  signal fifo_ovfl_wr                     : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal fifo_ovfl_wr_data                : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal fifo_rld_rd                      : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal fifo_rld_rd_data                 : t_dout_array;
  signal fifo_rld_rd_data_valid           : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal fifo_mig_rd                      : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal fifo_mig_rd_data                 : t_dout_array;
  signal fifo_mig_rd_data_valid           : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal fifo_fill_level                  : t_fifo_fill_level_array;
  signal prev_level_pkt_cnt               : unsigned(g_L2_FIFO_NUM+g_PKT_CNT_WIDTH-1 downto 0);
  signal enq_fin_time                     : unsigned(g_RANK_WIDTH-1 downto 0);
  signal enq_fifo_idx                     : unsigned(g_L2_FIFO_NUM-1 downto 0);
  signal enq_cmd_l                        : std_logic;
  signal ovfl_fin_time                    : unsigned(g_RANK_WIDTH-1 downto 0);
  signal ovfl_fifo_idx                    : unsigned(g_L2_FIFO_NUM-1 downto 0);
  signal mig_fin_time                     : unsigned(g_RANK_WIDTH-1 downto 0);
  signal mig_fifo_idx                     : unsigned(g_L2_FIFO_NUM-1 downto 0);
  signal sentinel                         : unsigned(g_RANK_WIDTH-1 downto 0);
  signal deq_fifo_index_d1                : unsigned(g_L2_FIFO_NUM-1 downto 0) := (others => '0');
  signal enq_level_pkt_cnt                : unsigned(g_L2_FIFO_NUM+g_PKT_CNT_WIDTH-1 downto 0);
  signal deq_level_pkt_cnt                : unsigned(g_L2_FIFO_NUM+g_PKT_CNT_WIDTH-1 downto 0);
  signal pifo_push                        : std_logic;
  signal pifo_push_data                   : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal pifo_pop                         : std_logic;
  signal pifo_pop_data                    : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal pifo_pop_data_valid              : std_logic;
  signal pifo_evicted_data                : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal pifo_evicted_data_valid          : std_logic;
  signal pifo_ovfl_wr                     : std_logic;
  signal pifo_ovfl_wr_data                : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal pifo_rld_wr                      : std_logic;
  signal pifo_rld_wr_data                 : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal pifo_rld_wr_done                 : std_logic;
  signal pifo_mig_wr                      : std_logic;
  signal pifo_mig_wr_data                 : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal pifo_mig_wr_done                 : std_logic;
  signal pifo_fill_level                  : unsigned(g_L2_PIFO_SIZE downto 0);
  signal pifo_empty                       : std_logic;
  signal pifo_full                        : std_logic;
  signal ovfl_in_r                        : std_logic;
  signal mig_in_cmd_r                     : std_logic;
  signal upd_curr_fifo_state              : t_upd_curr_fifo_state;
  signal deq_state                        : t_deq_state;
  signal rld_state                        : t_rld_state;
  signal rld_fin_time_dbg                 : unsigned(g_RANK_WIDTH-1 downto 0);
  signal enq_fifo_idx_dbg                 : unsigned(g_L2_FIFO_NUM-1 downto 0);
begin
  
  
  -- Instantiate FIFOs  
  g_GENERATE_FIFOS: for i in 0 to g_FIFO_NUM-1 generate
    -- Generate migrate out read command to individual FIFO wraapper
    fifo_mig_rd(i) <= '1' when (mig_out_cmd = '1' and to_integer(mig_out_fifo) = i)
                          else '0';
    
    i_fifo_wrapper : fifo_wrapper
    generic map (
      g_IS_LEVEL0         => IS_LEVEL0(g_THIS_LEVEL),         -- true if level 0
      g_L2_FIFO_SIZE      => g_L2_FIFO_SIZE,       -- log2 of size
      g_FIFO_DATA_WIDTH   => g_DESC_BIT_WIDTH,     -- Descriptor width
      g_RANK_LSB          => g_RANK_LSB,           -- Rank least significant bit in PIFO data word
      g_RANK_WIDTH        => g_RANK_WIDTH          -- Bit width of rank
    )
    port map (
      rst                 => rst,
      clk                 => clk,
      enq_wr              => fifo_push(i),
      enq_wr_data         => fifo_push_data,
      evct_wr             => fifo_evct_wr(i),
      evct_wr_data        => fifo_ecvt_wr_data,
      rld_wr              => fifo_rld_wr(i),
      rld_wr_data         => fifo_rld_wr_data,
      mig_wr              => fifo_mig_wr(i),
      mig_wr_data         => fifo_mig_wr_data,
      ovfl_wr             => fifo_ovfl_wr(i),
      ovfl_wr_data        => fifo_ovfl_wr_data,
      deq_rd              => fifo_pop(i),
      deq_rd_data         => fifo_pop_data(i),
      deq_rd_data_valid   => fifo_pop_data_valid(i),
      rld_rd              => fifo_rld_rd(i),
      rld_rd_data         => fifo_rld_rd_data(i),
      rld_rd_data_valid   => fifo_rld_rd_data_valid(i),
      mig_rd              => fifo_mig_rd(i),
      mig_rd_data         => fifo_mig_rd_data(i),
      mig_rd_data_valid   => fifo_mig_rd_data_valid(i),
      fill_level          => fifo_fill_level(i),
      empty               => fifo_empty(i),
      full                => fifo_full(i)
    );
  end generate g_GENERATE_FIFOS;
  
  -- Generate migrate out data and valid from individual FIFO wraapper
  mig_out_desc       <= fifo_mig_rd_data(to_integer(mig_out_fifo));
  mig_out_desc_valid <= fifo_mig_rd_data_valid(to_integer(mig_out_fifo));

  -- Instantiate PIFO in levels > 0
  pifo_gen: if g_THIS_LEVEL > 0 generate
    i_pifo_wrapper: pifo_wrapper
    generic map (
      g_L2_PIFO_SIZE     => g_L2_PIFO_SIZE,   -- integer
      g_PIFO_DATA_WIDTH  => g_DESC_BIT_WIDTH, -- Descriptor width
      g_RANK_LSB         => g_RANK_LSB,       -- Rank least significant bit in PIFO data word
      g_RANK_WIDTH       => g_RANK_WIDTH      -- Bit width of rank      
    )
    port map (
      rst                => rst,
      clk                => clk,
      vc_update          => vc_update,
      vc                 => vc,
      enq_wr             => pifo_push,
      enq_wr_data        => pifo_push_data,
      ovfl_wr            => pifo_ovfl_wr,
      ovfl_wr_data       => pifo_ovfl_wr_data,
      rld_wr             => pifo_rld_wr,
      rld_wr_data        => pifo_rld_wr_data,
      rld_wr_done        => pifo_rld_wr_done,
      mig_wr             => pifo_mig_wr,
      mig_wr_data        => pifo_mig_wr_data,
      mig_wr_done        => pifo_mig_wr_done,
      pop_cmd            => pifo_pop,
      pop_data           => pifo_pop_data,
      pop_data_valid     => pifo_pop_data_valid,
      evicted_data       => pifo_evicted_data,
      evicted_data_valid => pifo_evicted_data_valid,
      max_rank           => open,
      max_rank_valid     => open,
      fill_level         => pifo_fill_level,
      empty              => pifo_empty,
      full               => pifo_full
    );
  else generate
      pifo_pop_data            <= (others => '0');
      pifo_pop_data_valid      <= '0';
      pifo_evicted_data        <= (others => '0');
      pifo_evicted_data_valid  <= '0';
      pifo_fill_level          <= (others => '0');
      pifo_empty               <= '1';
      pifo_full                <= '0';
  end generate;
  
  enq_fin_time <= unsigned(enq_desc(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
  -- Enqueue process
  p_enqueue: process(rst, clk)
  --variable v_enq_fin_time : unsigned(g_RANK_WIDTH-1 downto 0);
  variable v_enq_fifo_idx : unsigned(g_L2_FIFO_NUM-1 downto 0);
  variable v_ovfl_fin_time: unsigned(g_RANK_WIDTH-1 downto 0);
  variable v_ovfl_fifo_idx: unsigned(g_L2_FIFO_NUM-1 downto 0);
  variable v_mig_fin_time : unsigned(g_RANK_WIDTH-1 downto 0);
  variable v_mig_fifo_idx : unsigned(g_L2_FIFO_NUM-1 downto 0);
  variable v_evct_fin_time: unsigned(g_RANK_WIDTH-1 downto 0);
  variable v_evct_fifo_idx: unsigned(g_L2_FIFO_NUM-1 downto 0);
  begin
    if rst = '1' then
      pifo_push          <= '0';
      pifo_ovfl_wr       <= '0';
      pifo_mig_wr        <= '0';
      ovfl_in_r          <= '0';
      mig_in_cmd_r       <= '0';
      fifo_push          <= (others => '0');
      fifo_evct_wr       <= (others => '0');
      fifo_mig_wr        <= (others => '0');
      enq_level_pkt_cnt  <= (others => '0');
      ovfl_out           <= '0';
      enq_done           <= '0';
      mig_in_done        <= '0';
    elsif clk'event and clk = '1' then
      -- defaults
      pifo_push    <= '0';
      pifo_ovfl_wr <= '0';
      pifo_mig_wr  <= '0';
      ovfl_in_r    <= '0';
      mig_in_cmd_r <= '0';
      fifo_push    <= (others => '0');
      fifo_evct_wr <= (others => '0');
      fifo_mig_wr  <= (others => '0');
      ovfl_out     <= '0';
      enq_cmd_l    <= '0';
      enq_done     <= '0';
      mig_in_done  <= '0';
            
      pifo_push_data    <= enq_desc;
      pifo_ovfl_wr_data <= ovfl_desc_in;
      pifo_mig_wr_data  <= mig_in_desc;
      fifo_push_data    <= enq_desc;
      fifo_ovfl_wr_data <= ovfl_desc_in;
      fifo_mig_wr_data  <= mig_in_desc;
      if enq_cmd = '1' then
        enq_cmd_l <= '1';
      end if;

      v_enq_fifo_idx := enq_fin_time(g_THIS_LEVEL*g_L2_FIFO_NUM + g_L2_MIN_GRAN - 1 downto g_L2_MIN_GRAN);
      enq_fifo_idx_dbg <= v_enq_fifo_idx;
      v_ovfl_fin_time := unsigned(ovfl_desc_in(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
      v_ovfl_fifo_idx := v_ovfl_fin_time((g_THIS_LEVEL+1)*g_L2_FIFO_NUM + g_L2_MIN_GRAN - 1 downto g_THIS_LEVEL*g_L2_FIFO_NUM + g_L2_MIN_GRAN);
      v_mig_fin_time := unsigned(mig_in_desc(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
      v_mig_fifo_idx := v_mig_fin_time((g_THIS_LEVEL+1)*g_L2_FIFO_NUM + g_L2_MIN_GRAN - 1 downto g_THIS_LEVEL*g_L2_FIFO_NUM + g_L2_MIN_GRAN);
      if (enq_cmd = '1' or enq_cmd_l = '1') and reload_fifo_busy(to_integer(v_enq_fifo_idx)) = '0' then
	if enq_fin_time > (vc(g_RANK_WIDTH - 1 downto g_L2_MIN_GRAN) & "00000") + "00000000001111111111" then
            ovfl_desc_out <= enq_desc;  -- !!! can be overwritten if ovfl_in is simultaneous
            ovfl_out <= '1';
        elsif and_reduce(fifo_empty(g_FIFO_NUM-1 downto 0)) = '1' and pifo_full = '0' and g_THIS_LEVEL > 0 then
          pifo_push <= '1'; 
          enq_level_pkt_cnt <= enq_level_pkt_cnt + 1;
        elsif enq_fin_time <= sentinel and g_THIS_LEVEL > 0 then
          pifo_push <= '1'; 
          enq_level_pkt_cnt <= enq_level_pkt_cnt + 1;
        else
          if fifo_full(to_integer(v_enq_fifo_idx)) = '0' then
            fifo_push(to_integer(v_enq_fifo_idx)) <= '1';
            enq_level_pkt_cnt <= enq_level_pkt_cnt + 1;
          else
            ovfl_desc_out <= enq_desc;  -- !!! can be overwritten if ovfl_in is simultaneous
            ovfl_out <= '1';
          end if;
        end if;
	enq_cmd_l <= '0';
        enq_done <= '1'; 
      end if;
          
      if pifo_evicted_data_valid = '1' then
        fifo_ecvt_wr_data <= pifo_evicted_data;
        v_evct_fin_time := unsigned(pifo_evicted_data(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
        v_evct_fifo_idx := v_evct_fin_time(g_THIS_LEVEL*g_L2_FIFO_NUM + g_L2_MIN_GRAN - 1 downto g_L2_MIN_GRAN);
        if fifo_full(to_integer(v_evct_fifo_idx)) = '0' then
          fifo_evct_wr(to_integer(v_evct_fifo_idx)) <= '1';
        else
	  ovfl_desc_out <= pifo_evicted_data;
          ovfl_out <= '1';
        end if;
      end if;
        
    end if;
  end process p_enqueue;
      
  -- dequeue process
  p_dequeue: process(rst, clk)
  variable v_current_fifo_index: unsigned(g_L2_FIFO_NUM-1 downto 0);
  begin
    if rst = '1' then
      fifo_pop               <= (others => '0');
      pifo_pop               <= '0';
      v_current_fifo_index   := (others => '0');
      deq_find_earliest_non_empty_fifo_rsp <= '0';
      deq_state              <= IDLE;
      upd_curr_fifo_state    <= IDLE;
      prev_level_pkt_cnt     <= (others => '0');
      deq_level_pkt_cnt      <= (others => '0');
      upd_wait_cnt           <= (others => '0');

    elsif clk'event and clk = '1' then
      fifo_pop       <= (others => '0');
      pifo_pop       <= '0';            
      deq_find_earliest_non_empty_fifo_rsp <= '0';
      deq_find_next  <= false;
      
      case upd_curr_fifo_state is
        when IDLE =>      
          if prev_level_pkt_cnt /= level_pkt_cnt and g_THIS_LEVEL = 0 then
            upd_curr_fifo_state <= WAIT_FIFO_EMPTY_UPDATE;
          end if;
      
        when WAIT_FIFO_EMPTY_UPDATE =>
          if upd_wait_cnt = to_unsigned(1, upd_wait_cnt'length) then
            find_earliest_non_empty_fifo(clk, deq_find_next, fifo_empty, fifo_fill_level, v_current_fifo_index, deq_find_earliest_non_empty_fifo_rsp, 
                                         deq_earliest_fifo_index, deq_all_fifos_empty);
               upd_wait_cnt         <= (others => '0');
            upd_curr_fifo_state <= WAIT_EARLIEST_NON_EMPTY_FIFO;
          else
            upd_wait_cnt <= upd_wait_cnt + 1;
            end if;
        
        when WAIT_EARLIEST_NON_EMPTY_FIFO =>
          if deq_find_earliest_non_empty_fifo_rsp = '1' then
            v_current_fifo_index := deq_earliest_fifo_index;
            current_fifo_index   <= deq_earliest_fifo_index;
            prev_level_pkt_cnt   <= level_pkt_cnt;
            upd_curr_fifo_state  <= IDLE;
          end if;

        when others =>
          upd_curr_fifo_state <= IDLE;
          
      end case;
           
      -- Dequeue state machine
      case deq_state is
        when IDLE =>
          if deq_cmd = '1' then
            if g_THIS_LEVEL = 0 then
              fifo_pop (to_integer(current_fifo_index)) <= '1';
            else 
              pifo_pop  <= '1';
            end if;
            deq_state <= WAIT_POP_VALID;
          end if;
          
        when WAIT_POP_VALID =>
          deq_level_pkt_cnt <= deq_level_pkt_cnt + 1;
          deq_state <= IDLE;
          
        when others =>
          deq_state <= IDLE;

      end case;
      
      fifo_pop_d1 <= fifo_pop(to_integer(current_fifo_index));

    end if;
  end process p_dequeue;
  
  -- Output pre-read descriptor to Sifter top level
  gen_lvl_rd: if g_THIS_LEVEL = 0 generate
    deq_desc <= fifo_pop_data(to_integer(current_fifo_index));
    deq_desc_valid <= fifo_pop_data_valid(to_integer(current_fifo_index)) and not fifo_pop_d1;
    -- Level 0 status ready output
    status_rdy <= deq_desc_valid or not (and (fifo_empty));
  else generate
    deq_desc <= pifo_pop_data;
    deq_desc_valid <= pifo_pop_data_valid and not pifo_pop;
    -- Level n > 0 status ready output
    --status_rdy <= (pifo_empty and and fifo_empty);
    status_rdy <= deq_desc_valid or (and (fifo_empty));
  end generate gen_lvl_rd;

  -- reload process
  p_reload: process(rst, clk)
  variable v_current_fifo_index : unsigned(g_L2_FIFO_NUM-1 downto 0);
  variable v_rld_fin_time : unsigned(g_RANK_WIDTH-1 downto 0);
  begin
    if rst = '1' then
      fifo_rld_rd   <= (others => '0');
      fifo_rld_wr   <= (others => '0');
      mig_out_cmd_l <= '0';
      pifo_rld_wr   <= '0';
      rld_find_earliest_non_empty_fifo_rsp <= '0';
      reload_fifo_valid <= '0';
      reload_fifo_busy  <= (others => '0');
      reload_size_updated <= '0';
      rld_state   <= IDLE;
      
    elsif clk'event and clk = '1' then
      fifo_rld_rd <= (others => '0');
      fifo_rld_wr <= (others => '0');
      pifo_rld_wr <= '0';
      rld_find_earliest_non_empty_fifo_rsp <= '0';
      --      rld_find_next <= true;
      rld_find_next <= false;
      reload_fifo_valid <= '0';
      reload_fifo_busy  <= (others => '0');
      
      v_rld_fin_time := unsigned(fifo_rld_rd_data(to_integer(reload_fifo))(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
      rld_fin_time_dbg <= v_rld_fin_time;
 
      -- Keep track of migrate out FIFO to make sure reload FIFO is next non-empty FIFO
      if mig_out_cmd = '1' then
        mig_out_fifo_l <= mig_out_fifo;
        mig_out_cmd_l <= '1';
        mig_out_fifo_valid <= '1';
      -- When migrate out FIFO is empty, negate mig_out_fifo_valid
      elsif fifo_empty(to_integer(mig_out_fifo_l)) = '1' then
        mig_out_fifo_valid <= '0';
      end if;
      
      -- Reload state machine
      case rld_state is
        when IDLE => 
          if pifo_fill_level <= g_PIFO_LOW_THRESH and and_reduce(fifo_empty(g_FIFO_NUM-1 downto 0)) /= '1' and g_THIS_LEVEL > 0 then
            -- Set current_fifo_index according to migrate out FIFO 
            if mig_out_fifo_valid = '1' then
              v_current_fifo_index := mig_out_fifo_l;
              mig_out_cmd_l <= '0';
            elsif mig_out_cmd = '1' then
              v_current_fifo_index := mig_out_fifo;
            else
              v_current_fifo_index := vc((g_THIS_LEVEL+1)*g_L2_FIFO_NUM-1 downto g_THIS_LEVEL*g_L2_FIFO_NUM);
            end if;
            find_earliest_non_empty_fifo(clk, rld_find_next, fifo_empty, fifo_fill_level, v_current_fifo_index, rld_find_earliest_non_empty_fifo_rsp, 
                                         rld_earliest_fifo_index, rld_all_fifos_empty);
            rld_state <= WAIT_FIND_EARLIEST_NON_EMPTY_FIFO_RSP;
          end if;
	  --reload_fifo_busy(to_integer(reload_fifo)) <= '0';
	  reload_size_updated <= '0';
  
        when WAIT_FIND_EARLIEST_NON_EMPTY_FIFO_RSP =>
          if rld_find_earliest_non_empty_fifo_rsp = '1' and mig_out_cmd = '0' then
            if rld_all_fifos_empty = '0' then
              reload_fifo  <= rld_earliest_fifo_index;
	      reload_fifo_valid <= '1';
              reload_count <= (others => '0');
              fifo_rld_rd(to_integer(rld_earliest_fifo_index)) <= '1';
              rld_state <= WAIT_FIFO_READ_READY;
            else
              rld_state <= IDLE;
            end if;
          else
            rld_state <= IDLE;          
          end if;
        --!!!! Deal with migrate out cmd = 1         
        when WAIT_FIFO_READ_READY =>
          if fifo_rld_rd_data_valid(to_integer(reload_fifo)) = '1' then
            pifo_rld_wr_data <= fifo_rld_rd_data(to_integer(reload_fifo));
            fifo_rld_wr_data <= fifo_rld_rd_data(to_integer(reload_fifo));
            if (v_rld_fin_time <= sentinel) then
              pifo_rld_wr      <= '1';
              rld_state        <= WAIT_PIFO_WRITE_DONE;
            else
	      reload_fifo_busy(to_integer(reload_fifo)) <= '1';
              fifo_rld_wr(to_integer(reload_fifo)) <= '1';
              rld_state        <= WAIT_FIFO_WRITE_DONE;
            end if;  
            reload_count       <= reload_count + 1;
          end if;
	  if reload_size_updated = '0' then
              reload_size  <= fifo_fill_level(to_integer(reload_fifo));
	      reload_size_updated <= '1';
	  end if;
        
        when WAIT_PIFO_WRITE_DONE =>
          if pifo_rld_wr_done = '1' then
            if fifo_empty(to_integer(reload_fifo)) = '1' then
              rld_state <= IDLE;
            else
              rld_state <= CHECK_RELOAD_SIZE;
            end if;
          end if;    

        when WAIT_FIFO_WRITE_DONE =>
          if fifo_empty(to_integer(reload_fifo)) = '1' then
            rld_state <= IDLE;
          else
            rld_state <= CHECK_RELOAD_SIZE;
          end if;
          --reload_fifo_busy(to_integer(reload_fifo)) <= '0';
        
        when CHECK_RELOAD_SIZE =>
          if reload_count < reload_size and mig_out_cmd = '0' and mig_out_cmd_l = '0' then
            fifo_rld_rd(to_integer(reload_fifo)) <= '1';
            rld_state <= WAIT_FIFO_READ_READY;
          else
            rld_state <= IDLE;
          end if;
          
        when OTHERS =>
          rld_state <= IDLE;
      end case;
    end if;
  end process p_reload;
 
  -- sentinel update process
  p_sentinel: process(rst, clk)
  variable v_evct_fin_time: unsigned(g_RANK_WIDTH-1 downto 0);
  variable v_current_fifo_idx: unsigned(g_L2_FIFO_NUM-1 downto 0);
  begin
    if rst = '1' then
      sentinel <= (others => '1');
    elsif clk'event and clk = '1' then
      if enq_cmd = '1' then
        if and_reduce(fifo_empty(g_FIFO_NUM-1 downto 0)) = '1' and pifo_full = '0' then
	  -- Set sentinel to max value because all FIFOs are empty
	  sentinel <= (others => '1');
        end if;
      end if;	
      -- Update sentinel value if evicted finish time is smaller
      v_evct_fin_time := unsigned(pifo_evicted_data(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
      if pifo_evicted_data_valid = '1' then
        if v_evct_fin_time < sentinel then
          sentinel <= v_evct_fin_time;
        end if;
      end if;
      -- Update sentinel during reload
      v_current_fifo_idx := vc(g_L2_FIFO_NUM + g_L2_MIN_GRAN - 1 downto g_L2_MIN_GRAN);
      if rld_find_earliest_non_empty_fifo_rsp = '1' and rld_all_fifos_empty = '0' then
	if v_current_fifo_idx <= rld_earliest_fifo_index then
          sentinel <= vc(g_RANK_WIDTH-1 downto g_RANK_WIDTH - g_L2_FIFO_NUM - g_L2_FIFO_SIZE) & rld_earliest_fifo_index & to_unsigned(2**g_L2_FIFO_SIZE - 1, g_L2_FIFO_SIZE);
	else
          sentinel <= (vc(g_RANK_WIDTH-1 downto g_RANK_WIDTH - g_L2_FIFO_NUM - g_L2_FIFO_SIZE) & rld_earliest_fifo_index & to_unsigned(2**g_L2_FIFO_SIZE - 1, g_L2_FIFO_SIZE)) + 
		        to_unsigned(g_FIFO_NUM * 2**g_L2_MIN_GRAN, g_RANK_WIDTH);
	end if;
      end if; 
    end if;
  end process p_sentinel;

  -- counters process
  p_counters: process(rst, clk)
  begin
    if rst = '1' then
      get_fifo_cnts_rsp <= '0';    
    elsif clk'event and clk = '1' then
      get_fifo_cnts_rsp <= '0';
      if get_fifo_cnts_cmd = '1' then
        fifo_pkt_cnt      <= fifo_fill_level(to_integer(get_fifo_cnts_index));                       
        get_fifo_cnts_rsp <= '1';
      end if;
    end if;
  end process p_counters;
  
  -- level count i/f (always valid)
  level_pkt_cnt           <= enq_level_pkt_cnt - deq_level_pkt_cnt;

end sifter_level_arch;
