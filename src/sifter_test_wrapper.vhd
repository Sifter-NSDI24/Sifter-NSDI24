-- Sifter test wrapper module


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.ceil;
use IEEE.math_real.log2;
--library xpm;
--use xpm.vcomponents.all;
use work.gb_package.all;

entity sifter_test_wrapper is
  port (
    -- MM 
    mm_master_clk            : in  std_logic;
    mm_master_reset          : in  std_logic;
    mm_master_read           : in  std_logic;
    mm_master_write          : in  std_logic;
    mm_master_address        : in  std_logic_vector(19-1 downto 0);
    mm_master_byteenable     : in  std_logic_vector(4-1 downto 0);
    mm_master_writedata      : in  std_logic_vector(32-1 downto 0);
    mm_master_burstcount     : in  std_logic_vector(8-1 downto 0);
    mm_master_readdata       : out std_logic_vector(32-1 downto 0);
    mm_master_readdatavalid  : out std_logic;
    mm_master_waitrequest    : out std_logic

    -- DMA ENQUEUE IN
    --dma_enq_in_clk           : in  std_logic;
    --dma_enq_in_reset         : in  std_logic;
    --dma_enq_in_ready         : out std_logic;
    --dma_enq_in_valid         : in  std_logic;
    --dma_enq_in_data          : in  std_logic_vector(256-1 downto 0) := (others => '0');
    --dma_enq_in_empty         : in  std_logic_vector(5-1 downto 0) := (others => '0');
    --dma_enq_in_sop           : in  std_logic;
    --dma_enq_in_eop           : in  std_logic;
    --dma_enq_in_error         : in  std_logic;
    --dma_enq_in_size          : in  std_logic_vector(16-1 downto 0) := (others => '0');

    -- DMA DEQUEUE OUT
    --dma_deq_out_clk          : in  std_logic;
    --dma_deq_out_reset        : in  std_logic;
    --dma_deq_out_ready        : in  std_logic;
    --dma_deq_out_valid        : out std_logic;
    --dma_deq_out_data         : out std_logic_vector(256-1 downto 0);
    --dma_deq_out_empty        : out std_logic_vector(5-1 downto 0);
    --dma_deq_out_sop          : out std_logic;
    --dma_deq_out_eop          : out std_logic;
    --dma_deq_out_error        : out std_logic;
    --dma_deq_out_size         : out std_logic_vector(16-1 downto 0);

    -- DMA OVERFLOW OUT
    --dma_ovfl_out_clk         : in  std_logic;
    --dma_ovfl_out_reset       : in  std_logic;
    --dma_ovfl_out_ready       : in  std_logic;
    --dma_ovfl_out_valid       : out std_logic;
    --dma_ovfl_out_data        : out std_logic_vector(256-1 downto 0);
    --dma_ovfl_out_empty       : out std_logic_vector(5-1 downto 0);
    --dma_ovfl_out_sop         : out std_logic;
    --dma_ovfl_out_eop         : out std_logic;
    --dma_ovfl_out_error       : out std_logic;
    --dma_ovfl_out_size        : out std_logic_vector(16-1 downto 0)
  );
end sifter_test_wrapper;

architecture sifter_test_wrapper_arch of sifter_test_wrapper is

---------------
-- CONSTANTS --
---------------
  constant BYTES_PER_CLK          : integer := 37;
  constant L2_MIN_GRAN            : integer := 5;
  constant L2_FIFO_NUM            : integer := 5;
  constant FIFO_NUM               : integer := 2**L2_FIFO_NUM;
  constant L2_FIFO_SIZE           : integer := 5;
  constant L2_PIFO_SIZE           : integer := 5;
  constant PIFO_THRESH            : integer := 16;
  constant PKT_CNT_WIDTH          : integer := 32;
  constant DESC_BUFF_ADDR_WIDTH   : integer := 14;
  constant DESC_BIT_WIDTH         : integer := 57;
  constant RANK_WIDTH             : integer := 20; 
  constant L2_FLOW_NUM            : integer := 10;
  constant PKT_ID_BIT_WIDTH       : integer := 16;
  constant RANK_LSB               : integer := L2_FLOW_NUM + PKT_ID_BIT_WIDTH;
  constant VC_BIT_WIDTH           : integer := 20;
  constant PKT_LEN_BIT_WIDTH      : integer := 11;
  constant ENQ_GAP_BIT_WIDTH      : integer := 16;
  constant AVL_MM_ADDR_WIDTH      : integer := 19;
  constant TS_BIT_WIDTH           : integer := 32;
  constant REGISTER_OFFSET        : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0004";
  constant MM_SCRATCH_REGISTER    : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0000";
  constant MM_START               : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0001";
  constant MM_ENQ_MAX_CNT         : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0002";
  constant MM_ENQ_GAP             : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0003";
  constant MM_DEQ_DELAY           : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0004";
  constant MM_ENQ_COUNT           : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0005";
  constant MM_DEQ_COUNT           : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0006";
  constant MM_OVFL_COUNT          : unsigned(AVL_MM_ADDR_WIDTH-1 downto 0) := "000" & X"0007";
  constant MM_ENQ_BUFFER          : unsigned(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH+1) := "0001";
  constant MM_ENQ_GAP_BUFFER      : unsigned(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH+1) := "0010";
  constant MM_DEQ_BUFFER          : unsigned(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH+1) := "0011";
  constant MM_DEQ_TS_BUFFER       : unsigned(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH+1) := "0100";
  constant MM_OVFL_BUFFER         : unsigned(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH+1) := "0101";

----------------
-- COMPONENTS --
----------------

component sifter_lvl_top 
  generic ( 
    g_L2_FLOW_NUM       : integer;     -- log2 number of flows
    g_L2_MIN_GRAN       : integer;     -- Time granularity of each FIFO
    g_FIFO_NUM          : integer;     -- number of FIFOs
    g_L2_FIFO_NUM       : integer;     -- log2 of number of FIFOs
    g_L2_FIFO_SIZE      : integer;     -- log2 size (depth) of each FIFO
    g_L2_PIFO_SIZE      : integer;     -- log2 size (depth) of PIFO
    g_PIFO_LOW_THRESH   : integer;     -- low threshold of PIFO
    g_DESC_BIT_WIDTH    : integer;     -- Descriptor width
    g_RANK_LSB          : integer;     -- Rank LSB position within descriptor
    g_RANK_WIDTH        : integer;     -- Bit width of rank
    g_VC_BIT_WIDTH      : integer;     -- Bit width of virtual clock !!! should it be same as rank?
    g_PKT_LEN_BIT_WIDTH : integer;     -- Bit width of packet length
    g_PKT_ID_BIT_WIDTH  : integer;     -- Bit width of packet ID
    g_PKT_CNT_WIDTH     : integer      -- packet count width
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
end component;

component dma_buf
  generic (
    ADDR_WIDTH  : integer := 15;    
    DATA_WIDTH  : integer := 20
  );
  port (
    a    : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    d    : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    dpra : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    clk  : IN STD_LOGIC;
    we   : IN STD_LOGIC;
    dpo  : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
  );
end component;


-------------
-- SIGNALS --
-------------

  signal reg_scratch_register  : std_logic_vector(32-1 downto 0);
  signal mm_master_read_r      : std_logic;
  signal mm_wr_holding_reg     : std_logic_vector(32-1 downto 0);
  signal mm_rd_holding_reg     : std_logic_vector(32-1 downto 0);
  signal enq_gap_buff_wr_addr  : std_logic_vector(DESC_BUFF_ADDR_WIDTH-1 downto 0);
  signal enq_gap_buff_wr_data  : std_logic_vector(ENQ_GAP_BIT_WIDTH-1 downto 0);
  signal enq_gap_buff_rd_data  : std_logic_vector(ENQ_GAP_BIT_WIDTH-1 downto 0);
  signal enq_gap_buff_we       : std_logic;
  signal enq_buff_wr_addr      : std_logic_vector(DESC_BUFF_ADDR_WIDTH-1 downto 0);
  signal enq_buff_wr_data      : std_logic_vector(DESC_BIT_WIDTH-1 downto 0);
  signal enq_buff_we           : std_logic;
  signal enq_buff_rd_addr      : std_logic_vector(DESC_BUFF_ADDR_WIDTH-1 downto 0);
  signal enq_buff_rd_data      : std_logic_vector(DESC_BIT_WIDTH-1 downto 0);
  signal deq_buff_wr_addr      : std_logic_vector(DESC_BUFF_ADDR_WIDTH-1 downto 0);
  signal deq_buff_we           : std_logic;
  signal deq_buff_rd_data      : std_logic_vector(DESC_BIT_WIDTH-1 downto 0);
  signal ovfl_buff_wr_data     : std_logic_vector(DESC_BIT_WIDTH-1 downto 0);
  signal ovfl_buff_we          : std_logic;
  signal ovfl_buff_rd_data     : std_logic_vector(DESC_BIT_WIDTH-1 downto 0);
  signal start_reg             : std_logic;
  signal enq_gap               : unsigned(ENQ_GAP_BIT_WIDTH-1 downto 0);
  signal enq_gap_reg           : unsigned(ENQ_GAP_BIT_WIDTH-1 downto 0);
  signal enq_gap_cnt           : unsigned(ENQ_GAP_BIT_WIDTH-1 downto 0);
  signal enq_max_cnt_reg       : unsigned(DESC_BUFF_ADDR_WIDTH-1 downto 0);
  signal enq_count             : unsigned(DESC_BUFF_ADDR_WIDTH-1 downto 0);
  signal deq_delay_reg         : unsigned(16-1 downto 0);
  signal deq_delay_cnt         : unsigned(16-1 downto 0);
  signal deq_gap_cnt           : unsigned(PKT_LEN_BIT_WIDTH-1 downto 0);
  signal deq_count             : unsigned(DESC_BUFF_ADDR_WIDTH-1 downto 0);
  signal ovfl_count            : unsigned(DESC_BUFF_ADDR_WIDTH-1 downto 0);
  type t_enq_state is (IDLE, WAIT_RDY, WAIT_ENQ_GAP);
  signal enq_state             : t_enq_state;
  type t_deq_state is (IDLE, DEQ_DELAY, DEQ_LOOP, DEQ_GAP);
  signal deq_state             : t_deq_state;
  signal enq_rdy               : std_logic;
  signal enq_cmd               : std_logic;
  signal enq_desc              : std_logic_vector(DESC_BIT_WIDTH-1 downto 0);
  signal enq_done              : std_logic;
  signal deq_rdy               : std_logic;
  signal deq_cmd               : std_logic;
  signal deq_desc              : std_logic_vector(DESC_BIT_WIDTH-1 downto 0);
  signal deq_desc_valid        : std_logic;
  signal deq_pkt_len           : unsigned(PKT_LEN_BIT_WIDTH-1 downto 0);
  signal deq_ts_rd_data        : std_logic_vector(TS_BIT_WIDTH-1 downto 0);
  signal get_fifo_pkt_cnt_cmd  : std_logic := '0';
  signal get_fifo_pkt_cnt_fifo : unsigned(L2_FIFO_NUM-1 downto 0) := (others => '0');
  signal get_fifo_pkt_cnt_rsp  : std_logic;
  signal fifo_pkt_cnt          : unsigned(L2_FIFO_SIZE downto 0);
  signal level_pkt_cnt         : unsigned(L2_FIFO_NUM+PKT_CNT_WIDTH-1 downto 0);
  signal timestamp             : unsigned(TS_BIT_WIDTH - 1 downto 0);

begin
    p_mm_management : process(mm_master_reset, mm_master_clk)
    begin
        if mm_master_reset = '1' then
            mm_master_readdata       <= (others => '0');
            mm_master_readdatavalid  <= '0';
            mm_master_waitrequest    <= '1';
	    mm_master_read_r         <= '0';
            enq_gap_buff_we          <= '0';
            enq_buff_we              <= '0';
            reg_scratch_register     <= (others => '0');
	    start_reg                <= '0';
            mm_wr_holding_reg        <= (others => '0');
            enq_gap_reg              <= (others => '0');
	    deq_delay_reg            <= (others => '0');

        elsif rising_edge(mm_master_clk) then
            mm_master_readdatavalid  <= '0';
            mm_master_waitrequest    <= '0';
            enq_gap_buff_we          <= '0';
            enq_buff_we              <= '0';
	    start_reg                <= '0';
	    mm_master_read_r         <= mm_master_read;

            if mm_master_read_r = '1' then
                if unsigned(mm_master_address) = MM_SCRATCH_REGISTER then
                    mm_master_readdata <= reg_scratch_register;
                    mm_master_readdatavalid  <= '1';

                -- Start
                elsif unsigned(mm_master_address) = MM_START then
                    mm_master_readdata <= (32-1 downto 1 => '0') & start_reg;
                    mm_master_readdatavalid  <= '1';

                -- Enq max count
                elsif unsigned(mm_master_address) = MM_ENQ_MAX_CNT then
                    mm_master_readdata <= (32-1 downto enq_max_cnt_reg'LENGTH => '0') & std_logic_vector(enq_max_cnt_reg);
                    mm_master_readdatavalid  <= '1';

                -- Enq gap
                elsif unsigned(mm_master_address) = MM_ENQ_GAP then
                    mm_master_readdata <= (32-1 downto enq_gap_reg'LENGTH => '0') & std_logic_vector(enq_gap_reg);
                    mm_master_readdatavalid  <= '1';

                -- Deq delay
                elsif unsigned(mm_master_address) = MM_DEQ_DELAY then
                    mm_master_readdata <= X"0000" & std_logic_vector(deq_delay_reg);
                    mm_master_readdatavalid  <= '1';

                -- Holding reg
                elsif unsigned(mm_master_address(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH + 1)) = MM_ENQ_BUFFER then 
                    mm_master_readdata <= mm_wr_holding_reg;
                    mm_master_readdatavalid  <= '1';

                -- Enq count
                elsif unsigned(mm_master_address) = MM_ENQ_COUNT then
                    mm_master_readdata <= (32-1 downto enq_count'LENGTH => '0') & std_logic_vector(enq_count);
                    mm_master_readdatavalid  <= '1';

                -- Deq count
                elsif unsigned(mm_master_address) = MM_DEQ_COUNT then
                    mm_master_readdata <= (32-1 downto deq_count'LENGTH => '0') & std_logic_vector(deq_count);
                    mm_master_readdatavalid  <= '1';

                -- Ovfl count
                elsif unsigned(mm_master_address) = MM_OVFL_COUNT then
                    mm_master_readdata <= (32-1 downto ovfl_count'LENGTH => '0') & std_logic_vector(ovfl_count);
                    mm_master_readdatavalid  <= '1';

                -- Deq buffer    
                elsif unsigned(mm_master_address(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH + 1)) = MM_DEQ_BUFFER then 
                    if mm_master_address(0) = '0' then
                        mm_master_readdata <= (32-1 downto deq_buff_rd_data'LENGTH - 32 => '0') & deq_buff_rd_data(deq_buff_rd_data'LEFT downto 32);
                        mm_rd_holding_reg <= deq_buff_rd_data(32-1 downto 0);
                    else
                        mm_master_readdata <= mm_rd_holding_reg; 
                    end if;
                    mm_master_readdatavalid <= '1';

                -- Deq timestamp buffer    
                elsif unsigned(mm_master_address(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH + 1)) = MM_DEQ_TS_BUFFER then 
                    mm_master_readdata <= deq_ts_rd_data;
                    mm_master_readdatavalid <= '1';

                -- Ovfl buffer    
                elsif unsigned(mm_master_address(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH + 1)) = MM_OVFL_BUFFER then 
                    if mm_master_address(0) = '0' then
                        mm_master_readdata <= (32-1 downto ovfl_buff_rd_data'LENGTH - 32 => '0') & ovfl_buff_rd_data(ovfl_buff_rd_data'LEFT downto 32);
                        mm_rd_holding_reg <= ovfl_buff_rd_data(32-1 downto 0);
                    else
                        mm_master_readdata <= mm_rd_holding_reg;
                    end if;
                    mm_master_readdatavalid <= '1';
                end if;
	   end if;

           if mm_master_write = '1' then
                if unsigned(mm_master_address) = MM_SCRATCH_REGISTER then
                    reg_scratch_register <= mm_master_writedata;

                -- Start
                elsif unsigned(mm_master_address) = MM_START then
                    start_reg <= mm_master_writedata(0);

                -- Enq max count
                elsif unsigned(mm_master_address) = MM_ENQ_MAX_CNT then
                    enq_max_cnt_reg <= unsigned(mm_master_writedata(enq_max_cnt_reg'LENGTH - 1 downto 0));

                -- Enq gap register
                elsif unsigned(mm_master_address) = MM_ENQ_GAP then
                    enq_gap_reg <= unsigned(mm_master_writedata(enq_gap_reg'LENGTH - 1 downto 0));

                -- Deq delay
                elsif unsigned(mm_master_address) = MM_DEQ_DELAY then
                    deq_delay_reg <= unsigned(mm_master_writedata(deq_delay_reg'LENGTH -1 downto 0));

                -- Enq desc gap buffer
                elsif unsigned(mm_master_address(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH + 1)) = MM_ENQ_GAP_BUFFER then
                    enq_gap_buff_wr_addr <= mm_master_address(DESC_BUFF_ADDR_WIDTH downto 1);
                    enq_gap_buff_wr_data <= mm_master_writedata(ENQ_GAP_BIT_WIDTH - 1 downto 0);
                    enq_gap_buff_we      <= '1';

                -- Enq desc buffer
                elsif unsigned(mm_master_address(AVL_MM_ADDR_WIDTH-1 downto DESC_BUFF_ADDR_WIDTH + 1)) = MM_ENQ_BUFFER then
                    if mm_master_address(0) = '0' then
                        mm_wr_holding_reg <= mm_master_writedata;
                    else
                        enq_buff_wr_addr <= mm_master_address(DESC_BUFF_ADDR_WIDTH downto 1);
                        enq_buff_wr_data <= mm_wr_holding_reg(DESC_BIT_WIDTH - 32 - 1 downto 0) & mm_master_writedata;
                        enq_buff_we      <= '1';
                    end if;

                end if;
            end if;
        end if;
    end process;

    p_enq: process(mm_master_reset, mm_master_clk)
    begin
        if mm_master_reset = '1' then
	    enq_count <= (others => '0');
            enq_state <= IDLE;
            enq_cmd   <= '0';

	elsif rising_edge(mm_master_clk) then
            enq_cmd   <= '0';
            enq_buff_rd_addr <= std_logic_vector(enq_count);
	    -- Reclock output of memory to improve timing
	    -- Also ensure that enq_desc and enq_cmd are aligned
            enq_desc <= enq_buff_rd_data;

            case enq_state is
            when IDLE =>
                if start_reg = '1' then
                    enq_state <= WAIT_RDY;
                end if;

	    when WAIT_RDY => 
                enq_gap_cnt <= to_unsigned(2, enq_gap_cnt'LENGTH);
                if enq_gap_reg /= 0 then
		   enq_gap <= enq_gap_reg;
                else
		   enq_gap <= unsigned(enq_gap_buff_rd_data);
                end if;
                if enq_rdy = '1' then 
                    enq_state <= WAIT_ENQ_GAP;
                end if;

            when WAIT_ENQ_GAP =>
                if enq_gap_cnt >= enq_gap then
                    enq_cmd <= '1';
                    if enq_count < enq_max_cnt_reg - 1 then
                        enq_state <= WAIT_RDY;
		    else
			enq_state <= IDLE;
		    end if;
                    enq_count <= enq_count + 1;
                else
                    enq_gap_cnt <= enq_gap_cnt + 1;
                end if;

            when OTHERS =>
                enq_state <= IDLE;

            end case;

        end if;
    end process;

    p_deq: process(mm_master_reset, mm_master_clk)
    begin
	if mm_master_reset = '1' then
	    deq_count     <= (others => '0');
	    deq_delay_cnt <= (others => '0');
            deq_buff_we   <= '0';
	    deq_cmd       <= '0';
	    deq_state     <= IDLE;

        elsif rising_edge(mm_master_clk) then
            deq_buff_we   <= '0';
	    deq_cmd       <= '0';
            case deq_state is
            when IDLE =>
                if start_reg = '1' then
                    if deq_delay_reg > 0 then
                        deq_delay_cnt <= to_unsigned(1, deq_delay_cnt'LENGTH);
                        deq_state <= DEQ_DELAY;
                    else
			deq_state <= DEQ_LOOP;    
		    end if;
                end if;

            when DEQ_DELAY =>
                if deq_delay_cnt = deq_delay_reg then
                    deq_state <= DEQ_LOOP;
                else
                    deq_delay_cnt <= deq_delay_cnt + 1;
                end if;

            when DEQ_LOOP =>
                if deq_rdy = '1' and deq_desc_valid = '1' then 
                    deq_buff_wr_addr <= std_logic_vector(deq_count);
		    deq_cmd          <= '1';
		    -- 64 bytes is the equivalent of 2 mm_master_clk cycles at 100Gb/s line rate (~300-350 MHz) 
                    deq_gap_cnt      <= to_unsigned(2 * BYTES_PER_CLK, deq_gap_cnt'LENGTH);
                    deq_pkt_len <= unsigned(deq_desc(DESC_BIT_WIDTH-1 downto DESC_BIT_WIDTH - PKT_LEN_BIT_WIDTH));
                    deq_state        <= DEQ_GAP;
                end if;

            when DEQ_GAP =>
		-- Deq desc must be grabbed/written to deq buff 1 clock after deq_cmd in case an enq comes in at the same time
		if deq_cmd = '1' then
                    deq_count        <= deq_count + 1;
                    deq_buff_we      <= '1';
		end if;
                if deq_gap_cnt >= deq_pkt_len then
                    if deq_count = enq_max_cnt_reg - ovfl_count then
		        deq_state <= IDLE;	
                    else
                        deq_state <= DEQ_LOOP;
                    end if;
	        else    
		    deq_gap_cnt <= deq_gap_cnt + BYTES_PER_CLK;
                end if;
            end case;
	end if;
    end process;

    p_deq_ts: process(mm_master_reset, mm_master_clk)
    begin
        if mm_master_reset = '1' then
	    timestamp <= (others => '0');
	elsif rising_edge(mm_master_clk) then
	    if start_reg = '1' then
                timestamp <= (others => '0');
	    else
		timestamp <= timestamp + 1;
	    end if;
	end if;
    end process;

    p_ovfl: process(mm_master_reset, mm_master_clk)
    begin
	if mm_master_reset = '1' then
	    ovfl_count <= (others => '0');
        elsif rising_edge(mm_master_clk) then
	    if ovfl_buff_we = '1' then
                ovfl_count <= ovfl_count + 1;
	    end if;
	end if;
    end process;

    i_dma_enq_gap_buf : dma_buf
    generic map(
      ADDR_WIDTH  => DESC_BUFF_ADDR_WIDTH,
      DATA_WIDTH  => ENQ_GAP_BIT_WIDTH
    )
    port map (
      a    => enq_gap_buff_wr_addr,
      d    => enq_gap_buff_wr_data,
      dpra => enq_buff_rd_addr,
      clk  => mm_master_clk,
      we   => enq_gap_buff_we,
      dpo  => enq_gap_buff_rd_data
    );

    i_dma_enq_buf : dma_buf
    generic map(
      ADDR_WIDTH  => DESC_BUFF_ADDR_WIDTH,
      DATA_WIDTH  => DESC_BIT_WIDTH
    )
    port map (
      a    => enq_buff_wr_addr,
      d    => enq_buff_wr_data,
      dpra => enq_buff_rd_addr,
      clk  => mm_master_clk,
      we   => enq_buff_we,
      dpo  => enq_buff_rd_data
    );

    i_dma_deq_buf : dma_buf
    generic map(
      ADDR_WIDTH  => DESC_BUFF_ADDR_WIDTH,
      DATA_WIDTH  => DESC_BIT_WIDTH
    )
    port map (
      a    => deq_buff_wr_addr,
      d    => deq_desc,
      dpra => mm_master_address(DESC_BUFF_ADDR_WIDTH downto 1),
      clk  => mm_master_clk,
      we   => deq_buff_we,
      dpo  => deq_buff_rd_data
    );

    i_dma_deq_ts_buf : dma_buf
    generic map(
      ADDR_WIDTH  => DESC_BUFF_ADDR_WIDTH,
      DATA_WIDTH  => TS_BIT_WIDTH
    )
    port map (
      a    => deq_buff_wr_addr,
      d    => std_logic_vector(timestamp),
      dpra => mm_master_address(DESC_BUFF_ADDR_WIDTH downto 1),
      clk  => mm_master_clk,
      we   => deq_buff_we,
      dpo  => deq_ts_rd_data
    );

    i_dma_ovfl_buf : dma_buf
    generic map(
      ADDR_WIDTH  => DESC_BUFF_ADDR_WIDTH,
      DATA_WIDTH  => DESC_BIT_WIDTH
    )
    port map (
      a    => std_logic_vector(ovfl_count),
      d    => ovfl_buff_wr_data,
      dpra => mm_master_address(DESC_BUFF_ADDR_WIDTH downto 1),
      clk  => mm_master_clk,
      we   => ovfl_buff_we,
      dpo  => ovfl_buff_rd_data
    );

  i_sifter_lvl_top: sifter_lvl_top 
  generic map (
      g_L2_FLOW_NUM         => L2_FLOW_NUM      ,     -- log2 number of flows
      g_L2_MIN_GRAN         => L2_MIN_GRAN      ,     -- Time granularity of each FIFO
      g_FIFO_NUM            => FIFO_NUM         ,     -- number of FIFOs
      g_L2_FIFO_NUM         => L2_FIFO_NUM      ,     -- log2 of number of FIFOs
      g_L2_FIFO_SIZE        => L2_FIFO_SIZE     ,     -- log2 size (depth) of each FIFO
      g_L2_PIFO_SIZE        => L2_PIFO_SIZE     ,     -- log2 size (depth) of PIFO
      g_PIFO_LOW_THRESH     => PIFO_THRESH      ,     -- low threshold of PIFO
      g_DESC_BIT_WIDTH      => DESC_BIT_WIDTH   ,     -- Descriptor width
      g_RANK_LSB            => RANK_LSB         ,     -- Rank LSB position within descriptor
      g_RANK_WIDTH          => RANK_WIDTH       ,     -- Bit width of rank
      g_VC_BIT_WIDTH        => VC_BIT_WIDTH     ,     -- Bit width of virtual clock !!! should it be same as rank?
      g_PKT_LEN_BIT_WIDTH   => PKT_LEN_BIT_WIDTH,     -- Bit width of packet length
      g_PKT_ID_BIT_WIDTH    => PKT_ID_BIT_WIDTH ,     -- Bit width of packet ID
      g_PKT_CNT_WIDTH       => PKT_CNT_WIDTH          -- packet count width
    )
    port map (
      rst                   => mm_master_reset,
      clk                   => mm_master_clk,
    
      -- enq i/f
      enq_rdy               => enq_rdy,
      enq_cmd               => enq_cmd,
      enq_desc              => enq_desc, 
      enq_done              => enq_done,
        
      -- ovfl out i/f
      ovfl_out              => ovfl_buff_we,
      ovfl_desc_out         => ovfl_buff_wr_data,
    
      -- deq i/f
      deq_rdy               => deq_rdy,
      deq_cmd               => deq_cmd,
      deq_desc              => deq_desc,
      deq_desc_valid        => deq_desc_valid,
        
      -- fifo pkt count i/f
      get_fifo_pkt_cnt_cmd  => get_fifo_pkt_cnt_cmd,
      get_fifo_pkt_cnt_fifo => get_fifo_pkt_cnt_fifo,
      get_fifo_pkt_cnt_rsp  => get_fifo_pkt_cnt_rsp,
      fifo_pkt_cnt          => fifo_pkt_cnt,
    
      -- level pkt count i/f
      level_pkt_cnt         => level_pkt_cnt

    );
       
end sifter_test_wrapper_arch;
