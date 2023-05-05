-- gearbox top level module


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.ceil;
use IEEE.math_real.log2;
--library xpm;
--use xpm.vcomponents.all;
use work.gb_package.all;

entity sifter_lvl_top is
  generic (
    g_L2_FLOW_NUM       : integer := 10  ;     -- log2 number of flows
    g_L2_MIN_GRAN       : integer := 5   ;     -- Time granularity of each FIFO
    g_FIFO_NUM          : integer := 32  ;     -- number of FIFOs
    g_L2_FIFO_NUM       : integer := 5   ;     -- log2 of number of FIFOs
    g_L2_FIFO_SIZE      : integer := 5   ;     -- log2 size (depth) of each FIFO
    g_L2_PIFO_SIZE      : integer := 5   ;     -- log2 size (depth) of PIFO
    g_PIFO_LOW_THRESH   : integer := 16  ;     -- low threshold of PIFO
    g_DESC_BIT_WIDTH    : integer := 57  ;     -- Descriptor width
    g_RANK_LSB          : integer := 26  ;     -- Rank LSB position within descriptor
    g_RANK_WIDTH        : integer := 20  ;     -- Bit width of rank
    g_VC_BIT_WIDTH      : integer := 20  ;     -- Bit width of virtual clock !!! should it be same as rank?
    g_PKT_LEN_BIT_WIDTH : integer := 11  ;     -- Bit width of packet length
    g_PKT_ID_BIT_WIDTH  : integer := 16  ;     -- Bit width of packet ID
    g_PKT_CNT_WIDTH     : integer := 32        -- packet count width
  );
  port (
    rst                              : in  std_logic;
    clk                              : in  std_logic;
    
    -- enq i/f
    enq_rdy                          : out std_logic;
    enq_cmd                          : in  std_logic;
    enq_desc                         : in  std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
    enq_done                         : out std_logic;
        
    -- ovfl out i/f
    ovfl_out                         : out std_logic;
    ovfl_desc_out                    : out std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
    
    -- deq i/f
    deq_rdy                          : out std_logic;
    deq_cmd                          : in  std_logic;
    deq_desc                         : out std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
    deq_desc_valid                   : out std_logic;
        
    -- fifo pkt count i/f
    get_fifo_pkt_cnt_cmd             : in  std_logic;
    get_fifo_pkt_cnt_fifo            : in  unsigned(g_L2_FIFO_NUM-1 downto 0);
    get_fifo_pkt_cnt_rsp             : out std_logic;
    fifo_pkt_cnt                     : out unsigned(g_L2_FIFO_SIZE downto 0);
    
    -- level pkt count i/f
    level_pkt_cnt                    : out unsigned(g_L2_FIFO_NUM+g_PKT_CNT_WIDTH-1 downto 0)

  );
end sifter_lvl_top;

architecture sifter_lvl_top_arch of sifter_lvl_top is

----------------
-- COMPONENTS --
----------------

component sifter_level
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
end component;

COMPONENT fin_time_arr
--  generic (
--    g_L2_FLOW_NUM  : integer := 10;    -- log2 of number of flows
--    g_VC_BIT_WIDTH : integer := 20     -- VC bit width
--  );
  PORT (
    a    : IN STD_LOGIC_VECTOR(g_L2_FLOW_NUM-1 DOWNTO 0);
    d    : IN STD_LOGIC_VECTOR(g_VC_BIT_WIDTH-1 DOWNTO 0);
    dpra : IN STD_LOGIC_VECTOR(g_L2_FLOW_NUM-1 DOWNTO 0);
    clk  : IN STD_LOGIC;
    we   : IN STD_LOGIC;
    dpo  : OUT STD_LOGIC_VECTOR(g_VC_BIT_WIDTH-1 DOWNTO 0)
  );
END COMPONENT;

---------------
-- CONSTANTS --
---------------
  constant c_MIN_GRAN                     : integer := 2 ** g_L2_MIN_GRAN;
  
-------------
-- SIGNALS --
-------------
  type   t_pkt_cnt_array           is array(0 to g_FIFO_NUM-1)  of unsigned(g_PKT_CNT_WIDTH-1 downto 0);
  type   t_enq_state               is (IDLE, ENQ_OP);

  signal enq_cmd_lvl                      : std_logic;
  signal enq_desc_lvl                     : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal enq_done_lvl                     : std_logic;
  signal deq_cmd_d1                       : std_logic;
  signal deq_desc_valid_d1                : std_logic;
  signal status_rdy_lvl                   : std_logic;
  signal fifo_pkt_cnt_lvl                 : t_pkt_cnt_array;
  signal fifo_empty_lvl                   : std_logic_vector(g_FIFO_NUM-1 downto 0);
  signal ovfl_out_lvl                     : std_logic;
  signal ovfl_desc_out_lvl                : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal ovfl_out_ft                      : std_logic;
  signal ovfl_desc_out_ft                 : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal fin_time_dpra                    : std_logic_vector(g_L2_FLOW_NUM-1 downto 0);
  signal fin_time_we                      : std_logic;
  signal fin_time_dpo                     : std_logic_vector(g_RANK_WIDTH-1 downto 0);
  signal flow_id                          : unsigned(g_L2_FLOW_NUM-1 downto 0);
  signal fin_time                         : unsigned(g_RANK_WIDTH-1 downto 0);
  signal ft_incr                          : unsigned(g_RANK_WIDTH-1 downto 0);
  signal vc                               : unsigned(g_VC_BIT_WIDTH-1 downto 0);
  signal vc_update                        : std_logic;

  signal enq_state                        : t_enq_state;
  signal enq_desc_d1                      : std_logic_vector(g_DESC_BIT_WIDTH-1 downto 0);
  signal enq_fifo_pkt_cnt                 : t_pkt_cnt_array;
  
  signal deq_fifo_index_d1                : unsigned(g_L2_FIFO_NUM-1 downto 0) := (others => '0');
  signal deq_fifo_pkt_cnt                 : t_pkt_cnt_array;
 
begin
  
  i_sifter_level : sifter_level
  generic map (      
    g_THIS_LEVEL        => 1,                    -- This level's number
    g_L2_MIN_GRAN       => g_L2_MIN_GRAN,        -- log2 of min granularity
    g_FIFO_NUM          => g_FIFO_NUM,           -- number of FIFOs
    g_L2_FIFO_NUM       => g_L2_FIFO_NUM,        -- log2 of number of FIFOs
    g_L2_FIFO_SIZE      => g_L2_FIFO_SIZE,       -- log2 size (depth) of each FIFO
    g_L2_PIFO_SIZE      => g_L2_PIFO_SIZE,       -- log2 size (depth) of PIFO
    g_PIFO_LOW_THRESH   => g_PIFO_LOW_THRESH,    -- low threshold of PIFO
    g_DESC_BIT_WIDTH    => g_DESC_BIT_WIDTH,     -- Descriptor width
    g_RANK_LSB          => g_RANK_LSB,           -- Rank LSB position within descriptor
    g_RANK_WIDTH        => g_RANK_WIDTH,         -- Bit width of rank
    g_PKT_LEN_BIT_WIDTH => g_PKT_LEN_BIT_WIDTH,  -- Bit width of packet length
    g_PKT_CNT_WIDTH     => g_PKT_CNT_WIDTH       -- packet count width
  )
  port map (
    rst                 => rst,
    clk                 => clk,
      
    -- enq i/f
    enq_cmd             => enq_cmd_lvl,
    enq_desc            => enq_desc_lvl,
    enq_done            => enq_done_lvl,
    
    -- deq i/f
    deq_cmd             => deq_cmd,
    deq_desc            => deq_desc,
    deq_desc_valid      => deq_desc_valid,

    -- migrate i/f
    mig_in_cmd          => '0',
    mig_in_desc         => (others => '0'),
    mig_in_done         => open,
    mig_out_cmd         => '0',
    mig_out_fifo        => (others => '0'),
    mig_out_desc        => open,
    mig_out_desc_valid  => open,

    -- virtual clock i/f
    vc                  => vc,
    vc_update           => vc_update,
        
    -- No ovfl from lower level
    ovfl_in             => '0',
    ovfl_desc_in        => (others => '0'),
    
    -- ovfl to upper level
    ovfl_out            => ovfl_out_lvl,
    ovfl_desc_out       => ovfl_desc_out_lvl,
    
    -- status ready i/f
    status_rdy          => status_rdy_lvl,
    
    -- fifo count i/f
    get_fifo_cnts_cmd   => get_fifo_pkt_cnt_cmd,
    get_fifo_cnts_index => get_fifo_pkt_cnt_fifo,
    get_fifo_cnts_rsp   => get_fifo_pkt_cnt_rsp,
    fifo_pkt_cnt        => fifo_pkt_cnt,
    fifo_empty          => fifo_empty_lvl,
    
    -- level count i/f (always valid)
    level_pkt_cnt       => level_pkt_cnt
  );

  -- Finish time table
  fin_time_dpra <= enq_desc(g_DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - g_RANK_WIDTH - 1 downto 
                                        g_DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - g_RANK_WIDTH - g_L2_FLOW_NUM);
 
  i_fin_time_arr: fin_time_arr
--    generic map (
--    g_L2_FLOW_NUM  => g_L2_FLOW_NUM,     -- log2 of number of flows
--    g_VC_BIT_WIDTH => g_VC_BIT_WIDTH     -- VC bit width
--  )
  PORT MAP (
    a    => std_logic_vector(flow_id),
    d    => std_logic_vector(fin_time),
    dpra => fin_time_dpra,
    clk  => clk,
    we   => fin_time_we,
    dpo  => fin_time_dpo
  );

  -- Enqueue process
  p_enqueue: process(rst, clk)
  variable v_pkt_time : unsigned(g_RANK_WIDTH-1 downto 0);
  variable v_flow_id  : unsigned(g_L2_FLOW_NUM-1 downto 0);
  begin
    if rst = '1' then
      enq_fifo_pkt_cnt   <= (others => (others => '0'));
      ovfl_out_ft        <= '0';
      enq_rdy            <= '1';
      enq_state          <= IDLE;
      fin_time_we        <= '0';
      enq_cmd_lvl        <= '0';
    elsif clk'event and clk = '1' then
      -- defaults
      ovfl_out_ft        <= '0';
      fin_time_we        <= '0';
      enq_cmd_lvl        <= '0';
            
      -- Enqueue state machine
      case enq_state is
        when IDLE => 
          if enq_cmd = '1' then
            -- extract packet time and flow id from descriptor
            v_pkt_time := unsigned(enq_desc(g_DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - 1 downto 
                                            g_DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - g_RANK_WIDTH));
            v_flow_id  := unsigned(enq_desc(g_DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - g_RANK_WIDTH - 1 downto 
                                            g_DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - g_RANK_WIDTH - g_L2_FLOW_NUM));
            flow_id    <= v_flow_id;
            -- calculate incremental and actual finish time
            if vc >= unsigned(fin_time_dpo) then
              ft_incr  <= v_pkt_time;
              fin_time <= v_pkt_time + vc;
            else
              ft_incr  <= v_pkt_time + unsigned(fin_time_dpo) - vc;
              fin_time <= v_pkt_time + unsigned(fin_time_dpo);
            end if;
            enq_desc_d1 <= enq_desc;
            enq_rdy     <= '0';
            enq_state   <= ENQ_OP;
          end if;
          
        when ENQ_OP =>
          -- Replace pkt time with finish time
          enq_desc_lvl <= enq_desc_d1(g_DESC_BIT_WIDTH-1 downto g_DESC_BIT_WIDTH-g_PKT_LEN_BIT_WIDTH) &
                         std_logic_vector(fin_time) & enq_desc_d1(g_L2_FLOW_NUM+g_PKT_ID_BIT_WIDTH-1 downto 0);
          -- if incremental finish time greater than max level capacity, drop pkt (check MSB bits)
          if ft_incr > vc + to_unsigned(g_FIFO_NUM*c_MIN_GRAN, g_RANK_WIDTH) then
            ovfl_desc_out_ft <= enq_desc;
            ovfl_out_ft <= '1';
          else
            -- Enqueue to level
            enq_cmd_lvl  <= '1';
            -- update fin_time_arr entry for flow_id
            fin_time_we <= '1';
          end if;
          
          -- Update enq packet counts
          enq_rdy      <= '1';
          enq_state    <= IDLE;

        when others =>
          enq_state   <= IDLE;
          
      end case;
        
    end if;
  end process p_enqueue;
  enq_done <= enq_done_lvl;
  ovfl_out <= ovfl_out_lvl or ovfl_out_ft;
  ovfl_desc_out <= ovfl_desc_out_lvl when ovfl_out_lvl = '1' else
		   ovfl_desc_out_ft;

  -- dequeue process
  deq_rdy <= status_rdy_lvl and deq_desc_valid and not deq_cmd and not deq_cmd_d1;
--  deq_rdy <= status_rdy_lvl;
  p_dequeue: process(rst, clk)  
  begin
    if rst = '1' then
      vc             <= (others => '0');
      vc_update      <= '0';
      deq_cmd_d1    <= '0';
    elsif clk'event and clk = '1' then
      vc_update      <= '0';
            
      if deq_cmd = '1' then
        vc <= unsigned(deq_desc(g_DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - 1 downto 
                                        g_DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - g_RANK_WIDTH));
        vc_update <= '1';
      end if;
      deq_cmd_d1       <= deq_cmd;
      deq_desc_valid_d1 <= deq_desc_valid;
    end if;
  end process p_dequeue;
       
end sifter_lvl_top_arch;
