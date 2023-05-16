
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library lib_enyx;
use     lib_enyx.std_logic_pkg.all;
use     lib_enyx.math_pkg.all;
use     lib_enyx.nxavl_mm_slave_core_pkg.all;
use     lib_enyx.nxtcp_hdr_handler_pkg.all;
use     lib_enyx.reg_data_pkg.all;
use     lib_enyx.nxudp_hdr_handler_pkg.all;
use     lib_enyx.id_pkg.all;

entity nxuser_sandbox is
    generic (
        AVL_MM_ADDR_WIDTH                           : natural  := 20;

        EXTERNAL_MEMORY_COUNT                       : natural  := 0;
        EXTERNAL_MEMORY_ADDR_WIDTH                  : natural  := 28;
        EXTERNAL_MEMORY_DATA_WIDTH                  : natural  := 512;
        EXTERNAL_MEMORY_MASK_WIDTH                  : natural  := 64;
        EXTERNAL_MEMORY_BURST_SIZE_WIDTH            : natural  := 0;

        PHY_COUNT                                   : natural  := 0;

        TCP_COUNT                                   : natural  := 0;
        TCP_SANDBOX_ST_IN_DATA_WIDTH                : natural  := 256;
        TCP_SANDBOX_ST_IN_EMPTY_WIDTH               : natural  := 5;
        TCP_SANDBOX_ST_OUT_DATA_WIDTH               : natural  := 256;
        TCP_SANDBOX_ST_OUT_EMPTY_WIDTH              : natural  := 5;

        TCP_EMI_COUNT                               : natural  := 0;
        TCP_EMI_SANDBOX_ST_IN_DATA_WIDTH            : natural  := 256;
        TCP_EMI_SANDBOX_ST_IN_EMPTY_WIDTH           : natural  := 5;
        TCP_EMI_SANDBOX_ST_OUT_DATA_WIDTH           : natural  := 256;
        TCP_EMI_SANDBOX_ST_OUT_EMPTY_WIDTH          : natural  := 5;

        TCP_FILTERED_COUNT                          : natural  := 0;
        TCP_FILTERED_SANDBOX_ST_IN_DATA_WIDTH       : natural  := 256;
        TCP_FILTERED_SANDBOX_ST_IN_EMPTY_WIDTH      : natural  := 5;

        UDP_COUNT                                   : natural  := 0;
        UDP_SANDBOX_ST_IN_DATA_WIDTH                : natural  := 256;
        UDP_SANDBOX_ST_IN_EMPTY_WIDTH               : natural  := 5;
        UDP_SANDBOX_ST_OUT_DATA_WIDTH               : natural  := 256;
        UDP_SANDBOX_ST_OUT_EMPTY_WIDTH              : natural  := 5;

        UDP_FILTERED_COUNT                          : natural  := 0;
        UDP_FILTERED_SANDBOX_ST_IN_DATA_WIDTH       : natural  := 256;
        UDP_FILTERED_SANDBOX_ST_IN_EMPTY_WIDTH      : natural  := 5;

        RAW_COUNT                                   : natural  := 0;
        RAW_SANDBOX_ST_IN_DATA_WIDTH                : natural  := 256;
        RAW_SANDBOX_ST_IN_EMPTY_WIDTH               : natural  := 5;
        RAW_SANDBOX_ST_OUT_DATA_WIDTH               : natural  := 256;
        RAW_SANDBOX_ST_OUT_EMPTY_WIDTH              : natural  := 5;

        DMA_COUNT                                   : natural  := 0;
        DMA_SANDBOX_ST_IN_DATA_WIDTH                : natural  := 256;
        DMA_SANDBOX_ST_IN_EMPTY_WIDTH               : natural  := 5;
        DMA_SANDBOX_ST_OUT_DATA_WIDTH               : natural  := 256;
        DMA_SANDBOX_ST_OUT_EMPTY_WIDTH              : natural  := 5;

        NETIF_COUNT                                 : natural  := 0;
        NETIF_SANDBOX_ST_IN_DATA_WIDTH              : natural  := 256;
        NETIF_SANDBOX_ST_IN_EMPTY_WIDTH             : natural  := 5;
        NETIF_SANDBOX_ST_OUT_DATA_WIDTH             : natural  := 256;
        NETIF_SANDBOX_ST_OUT_EMPTY_WIDTH            : natural  := 5
    );
    port  (
        ---------------------------------------------
        -------------------- MM ---------------------
        ---------------------------------------------
            mm_slave_clk                : in  std_logic;
            mm_slave_reset              : in  std_logic;
            mm_slave_read               : in  std_logic;
            mm_slave_write              : in  std_logic;
            mm_slave_address            : in  std_logic_vector(AVL_MM_ADDR_WIDTH-1 downto 0);
            mm_slave_byteenable         : in  std_logic_vector(4-1 downto 0);
            mm_slave_writedata          : in  std_logic_vector(32-1 downto 0);
            mm_slave_burstcount         : in  std_logic_vector(8-1 downto 0);
            mm_slave_readdata           : out std_logic_vector(32-1 downto 0);
            mm_slave_readdatavalid      : out std_logic;
            mm_slave_waitrequest        : out std_logic;

        ---------------------------------------------
        ------------- EXTERNAL MEMOMRY --------------
        ---------------------------------------------
            external_memory_read_clk            : in  std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0) := (others => '0');
            external_memory_read_reset          : in  std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0) := (others => '0');
            external_memory_read_ready          : in  std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0) := (others => '0');
            external_memory_read_request        : out std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0);
            external_memory_read_addr           : out std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT*EXTERNAL_MEMORY_ADDR_WIDTH-1) downto 0);
            external_memory_read_burst_size     : out std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT*EXTERNAL_MEMORY_BURST_SIZE_WIDTH-1) downto 0);
            external_memory_read_valid          : in  std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0) := (others => '0');
            external_memory_read_data           : in  std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT*EXTERNAL_MEMORY_DATA_WIDTH-1) downto 0) := (others => '0');

            external_memory_write_clk           : in  std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0) := (others => '0');
            external_memory_write_reset         : in  std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0) := (others => '0');
            external_memory_write_ready         : in  std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0) := (others => '0');
            external_memory_write_request       : out std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT-1) downto 0);
            external_memory_write_addr          : out std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT*EXTERNAL_MEMORY_ADDR_WIDTH-1) downto 0);
            external_memory_write_data          : out std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT*EXTERNAL_MEMORY_DATA_WIDTH-1) downto 0);
            external_memory_write_mask          : out std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT*EXTERNAL_MEMORY_MASK_WIDTH-1) downto 0);
            external_memory_write_burst_size    : out std_logic_vector(int_to_natural(EXTERNAL_MEMORY_COUNT*EXTERNAL_MEMORY_BURST_SIZE_WIDTH-1) downto 0);

        ---------------------------------------------
        ------------------ PHY ----------------------
        ---------------------------------------------
            -- LINK IN
            phy_in_link_clk             : in std_logic_vector(int_to_natural(PHY_COUNT-1) downto 0) := (others=>'0');
            phy_in_link_reset           : in std_logic_vector(int_to_natural(PHY_COUNT-1) downto 0) := (others=>'0');
            phy_in_link_status          : in std_logic_vector(int_to_natural(PHY_COUNT-1) downto 0) := (others=>'0');

        ---------------------------------------------
        -------------------- TCP --------------------
        ---------------------------------------------
            -- tcp_user DATA IN
            tcp_user_in_clk             : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_in_reset           : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_in_ready           : out std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);
            tcp_user_in_valid           : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_in_data            : in  std_logic_vector(int_to_natural(TCP_COUNT*TCP_SANDBOX_ST_IN_DATA_WIDTH-1) downto 0) := (others => '0');
            tcp_user_in_empty           : in  std_logic_vector(int_to_natural(TCP_COUNT*TCP_SANDBOX_ST_IN_EMPTY_WIDTH-1) downto 0) := (others => '0');
            tcp_user_in_sop             : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_in_eop             : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_in_error           : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_in_session_id      : in  std_logic_vector(int_to_natural(TCP_COUNT*20-1) downto 0) := (others => '0');
            tcp_user_in_payload_size    : in  std_logic_vector(int_to_natural(TCP_COUNT*16-1) downto 0) := (others => '0');
            tcp_user_in_timestamp       : in  std_logic_vector(int_to_natural(TCP_COUNT*64-1) downto 0) := (others => '0');

            -- tcp_user DATA OUT
            tcp_user_out_clk            : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_out_reset          : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_out_ready          : in  std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0) := (others => '0');
            tcp_user_out_valid          : out std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);
            tcp_user_out_data           : out std_logic_vector(int_to_natural(TCP_COUNT*TCP_SANDBOX_ST_OUT_DATA_WIDTH-1) downto 0);
            tcp_user_out_empty          : out std_logic_vector(int_to_natural(TCP_COUNT*TCP_SANDBOX_ST_OUT_EMPTY_WIDTH-1) downto 0);
            tcp_user_out_sop            : out std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);
            tcp_user_out_eop            : out std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);
            tcp_user_out_error          : out std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);
            tcp_user_out_session_id     : out std_logic_vector(int_to_natural(TCP_COUNT*20-1) downto 0);
            tcp_user_out_payload_chk    : out std_logic_vector(int_to_natural(TCP_COUNT*32-1) downto 0);
            tcp_user_out_payload_size   : out std_logic_vector(int_to_natural(TCP_COUNT*16-1) downto 0);

            -- tcp_emi
            tcp_emi_in_clk              : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_in_reset            : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_in_ready            : out std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);
            tcp_emi_in_valid            : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_in_data             : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT*TCP_EMI_SANDBOX_ST_IN_DATA_WIDTH-1) downto 0) := (others => '0');
            tcp_emi_in_empty            : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT*TCP_EMI_SANDBOX_ST_IN_EMPTY_WIDTH-1) downto 0) := (others => '0');
            tcp_emi_in_sop              : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_in_eop              : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_in_error            : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_in_size             : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT*16-1) downto 0) := (others => '0');

            tcp_emi_out_clk             : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_out_reset           : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_out_ready           : in  std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0) := (others => '0');
            tcp_emi_out_valid           : out std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);
            tcp_emi_out_data            : out std_logic_vector(int_to_natural(TCP_EMI_COUNT*TCP_EMI_SANDBOX_ST_OUT_DATA_WIDTH-1) downto 0);
            tcp_emi_out_empty           : out std_logic_vector(int_to_natural(TCP_EMI_COUNT*TCP_EMI_SANDBOX_ST_OUT_EMPTY_WIDTH-1) downto 0);
            tcp_emi_out_sop             : out std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);
            tcp_emi_out_eop             : out std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);
            tcp_emi_out_error           : out std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);

            -- tcp non offloaded
            tcp_filtered_in_clk      : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0) := (others => '0');
            tcp_filtered_in_reset    : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0) := (others => '0');
            tcp_filtered_in_ready    : out std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0);
            tcp_filtered_in_valid    : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0) := (others => '0');
            tcp_filtered_in_data     : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT*TCP_FILTERED_SANDBOX_ST_IN_DATA_WIDTH-1) downto 0) := (others => '0');
            tcp_filtered_in_empty    : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT*TCP_FILTERED_SANDBOX_ST_IN_EMPTY_WIDTH-1) downto 0) := (others => '0');
            tcp_filtered_in_sop      : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0) := (others => '0');
            tcp_filtered_in_eop      : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0) := (others => '0');
            tcp_filtered_in_error    : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0) := (others => '0');
            tcp_filtered_in_size     : in  std_logic_vector(int_to_natural(TCP_FILTERED_COUNT*16-1) downto 0) := (others => '0');

            tcp_session_connected       : in std_logic_vector(int_to_natural(TCP_COUNT*128-1) downto 0) := (others => '0');
            tcp_session_closing         : in std_logic_vector(int_to_natural(TCP_COUNT*128-1) downto 0) := (others => '0');
            tcp_session_ready           : in std_logic_vector(int_to_natural(TCP_COUNT*128-1) downto 0) := (others => '0');

        ---------------------------------------------
        -------------------- UDP --------------------
        ---------------------------------------------
            -- udp_user IN
            udp_user_in_clk           : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_in_reset         : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_in_ready         : out std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);
            udp_user_in_valid         : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_in_data          : in  std_logic_vector(int_to_natural(UDP_COUNT*UDP_SANDBOX_ST_IN_DATA_WIDTH-1) downto 0) := (others => '0');
            udp_user_in_empty         : in  std_logic_vector(int_to_natural(UDP_COUNT*UDP_SANDBOX_ST_IN_EMPTY_WIDTH-1) downto 0) := (others => '0');
            udp_user_in_sop           : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_in_eop           : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_in_error         : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_in_session_id    : in  std_logic_vector(int_to_natural(UDP_COUNT*8-1) downto 0) := (others => '0');
            udp_user_in_payload_size  : in  std_logic_vector(int_to_natural(UDP_COUNT*16-1) downto 0) := (others => '0');
            udp_user_in_rem_port      : in  std_logic_vector(int_to_natural(UDP_COUNT*16-1) downto 0) := (others => '0');
            udp_user_in_rem_ip        : in  std_logic_vector(int_to_natural(UDP_COUNT*32-1) downto 0) := (others => '0');
            udp_user_in_timestamp     : in  std_logic_vector(int_to_natural(UDP_COUNT*64-1) downto 0) := (others => '0');

            -- udp_user OUT
            udp_user_out_clk          : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_out_reset        : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_out_ready        : in  std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0) := (others => '0');
            udp_user_out_valid        : out std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);
            udp_user_out_data         : out std_logic_vector(int_to_natural(UDP_COUNT*UDP_SANDBOX_ST_OUT_DATA_WIDTH-1) downto 0);
            udp_user_out_empty        : out std_logic_vector(int_to_natural(UDP_COUNT*UDP_SANDBOX_ST_OUT_EMPTY_WIDTH-1) downto 0);
            udp_user_out_sop          : out std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);
            udp_user_out_eop          : out std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);
            udp_user_out_error        : out std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);
            udp_user_out_session_id   : out std_logic_vector(int_to_natural(UDP_COUNT*8-1) downto 0);
            udp_user_out_payload_size : out std_logic_vector(int_to_natural(UDP_COUNT*16-1) downto 0);
            udp_user_out_payload_chk  : out std_logic_vector(int_to_natural(UDP_COUNT*32-1) downto 0);

            -- udp non offloaded

            udp_filtered_in_clk    : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0) := (others => '0');
            udp_filtered_in_reset  : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0) := (others => '0');
            udp_filtered_in_ready  : out std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0);
            udp_filtered_in_valid  : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0) := (others => '0');
            udp_filtered_in_data   : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT*UDP_FILTERED_SANDBOX_ST_IN_DATA_WIDTH-1) downto 0) := (others => '0');
            udp_filtered_in_empty  : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT*UDP_FILTERED_SANDBOX_ST_IN_EMPTY_WIDTH-1) downto 0) := (others => '0');
            udp_filtered_in_sop    : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0) := (others => '0');
            udp_filtered_in_eop    : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0) := (others => '0');
            udp_filtered_in_error  : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0) := (others => '0');
            udp_filtered_in_size   : in  std_logic_vector(int_to_natural(UDP_FILTERED_COUNT*16-1) downto 0) := (others => '0');

        ---------------------------------------------
        -------------------- RAW---------------------
        ---------------------------------------------
            -- RAW IN
            raw_user_in_clk           : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0) := (others => '0');
            raw_user_in_reset         : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0) := (others => '0');
            raw_user_in_ready         : out std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
            raw_user_in_valid         : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0) := (others => '0');
            raw_user_in_data          : in  std_logic_vector(int_to_natural(RAW_COUNT*RAW_SANDBOX_ST_IN_DATA_WIDTH-1) downto 0) := (others => '0');
            raw_user_in_empty         : in  std_logic_vector(int_to_natural(RAW_COUNT*RAW_SANDBOX_ST_IN_EMPTY_WIDTH-1) downto 0) := (others => '0');
            raw_user_in_sop           : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0) := (others => '0');
            raw_user_in_eop           : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0) := (others => '0');
            raw_user_in_error         : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0) := (others => '0');
            raw_user_in_size          : in  std_logic_vector(int_to_natural(RAW_COUNT*16-1) downto 0) := (others => '0');

            -- RAW OUT
            raw_user_out_clk          : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0):= (others => '0');
            raw_user_out_reset        : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0):= (others => '0');
            raw_user_out_ready        : in  std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0):= (others => '0');
            raw_user_out_valid        : out std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
            raw_user_out_data         : out std_logic_vector(int_to_natural(RAW_COUNT*RAW_SANDBOX_ST_OUT_DATA_WIDTH-1) downto 0);
            raw_user_out_empty        : out std_logic_vector(int_to_natural(RAW_COUNT*RAW_SANDBOX_ST_OUT_EMPTY_WIDTH-1) downto 0);
            raw_user_out_sop          : out std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
            raw_user_out_eop          : out std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
            raw_user_out_error        : out std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
            raw_user_out_size         : out std_logic_vector(int_to_natural(RAW_COUNT*16-1) downto 0);

        ---------------------------------------------
        -------------------- DMA --------------------
        ---------------------------------------------
            -- DMA IN
            dma_user_in_clk           : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0) := (others => '0');
            dma_user_in_reset         : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0) := (others => '0');
            dma_user_in_ready         : out std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
            dma_user_in_valid         : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0) := (others => '0');
            dma_user_in_data          : in  std_logic_vector(int_to_natural(DMA_COUNT*DMA_SANDBOX_ST_IN_DATA_WIDTH-1) downto 0) := (others => '0');
            dma_user_in_empty         : in  std_logic_vector(int_to_natural(DMA_COUNT*DMA_SANDBOX_ST_IN_EMPTY_WIDTH-1) downto 0) := (others => '0');
            dma_user_in_sop           : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0) := (others => '0');
            dma_user_in_eop           : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0) := (others => '0');
            dma_user_in_error         : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0) := (others => '0');
            dma_user_in_size          : in  std_logic_vector(int_to_natural(DMA_COUNT*16-1) downto 0) := (others => '0');

            -- DMA OUT
            dma_user_out_clk          : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0):= (others => '0');
            dma_user_out_reset        : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0):= (others => '0');
            dma_user_out_ready        : in  std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0):= (others => '0');
            dma_user_out_valid        : out std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
            dma_user_out_data         : out std_logic_vector(int_to_natural(DMA_COUNT*DMA_SANDBOX_ST_OUT_DATA_WIDTH-1) downto 0);
            dma_user_out_empty        : out std_logic_vector(int_to_natural(DMA_COUNT*DMA_SANDBOX_ST_OUT_EMPTY_WIDTH-1) downto 0);
            dma_user_out_sop          : out std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
            dma_user_out_eop          : out std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
            dma_user_out_error        : out std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
            dma_user_out_size         : out std_logic_vector(int_to_natural(DMA_COUNT*16-1) downto 0);

        ---------------------------------------------
        ------------------- NETIF--------------------
        ---------------------------------------------
            -- LINK_OUT
            netif_out_link_status     : out std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);

            -- NETIF IN
            netif_user_in_clk         : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0) := (others => '0');
            netif_user_in_reset       : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0) := (others => '0');
            netif_user_in_ready       : out std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
            netif_user_in_valid       : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0) := (others => '0');
            netif_user_in_data        : in  std_logic_vector(int_to_natural(NETIF_COUNT*NETIF_SANDBOX_ST_IN_DATA_WIDTH-1) downto 0) := (others => '0');
            netif_user_in_empty       : in  std_logic_vector(int_to_natural(NETIF_COUNT*NETIF_SANDBOX_ST_IN_EMPTY_WIDTH-1) downto 0) := (others => '0');
            netif_user_in_sop         : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0) := (others => '0');
            netif_user_in_eop         : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0) := (others => '0');
            netif_user_in_error       : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0) := (others => '0');
            netif_user_in_size        : in  std_logic_vector(int_to_natural(16*NETIF_COUNT-1) downto 0) := (others => '0');

            -- NETIF OUT
            netif_user_out_clk        : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0) := (others => '0');
            netif_user_out_reset      : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0) := (others => '0');
            netif_user_out_ready      : in  std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0):= (others => '0');
            netif_user_out_valid      : out std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
            netif_user_out_data       : out std_logic_vector(int_to_natural(NETIF_COUNT*NETIF_SANDBOX_ST_OUT_DATA_WIDTH-1) downto 0);
            netif_user_out_empty      : out std_logic_vector(int_to_natural(NETIF_COUNT*NETIF_SANDBOX_ST_OUT_EMPTY_WIDTH-1) downto 0);
            netif_user_out_sop        : out std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
            netif_user_out_eop        : out std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
            netif_user_out_error      : out std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
            netif_user_out_size       : out std_logic_vector(int_to_natural(16*NETIF_COUNT-1) downto 0)
    );
end entity;


architecture nxuser_sandbox_smartnic_arch of nxuser_sandbox is

    component sifter_test_wrapper
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
      );
    end component;

    signal reg_scratch_register                     : std_logic_vector(32-1 downto 0);
    signal reg2_scratch_register                    : std_logic_vector(32-1 downto 0);

    signal reg_tcp_in_pkt_cnt                       : std_logic_vector(32-1 downto 0);
    signal reg_tcp_emi_in_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg_tcp_filtered_in_pkt_cnt              : std_logic_vector(32-1 downto 0);
    signal reg_udp_in_pkt_cnt                       : std_logic_vector(32-1 downto 0);
    signal reg_udp_filtered_in_pkt_cnt              : std_logic_vector(32-1 downto 0);
    signal reg_raw_0_in_pkt_cnt                     : std_logic_vector(32-1 downto 0);
    signal reg_raw_0_out_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg_raw_1_in_pkt_cnt                     : std_logic_vector(32-1 downto 0);
    signal reg_raw_1_out_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg_raw_2_in_pkt_cnt                     : std_logic_vector(32-1 downto 0);
    signal reg_raw_2_out_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg_dma_0_in_pkt_cnt                     : std_logic_vector(32-1 downto 0);
    signal reg_dma_1_in_pkt_cnt                     : std_logic_vector(32-1 downto 0);
    signal reg_dma_2_in_pkt_cnt                     : std_logic_vector(32-1 downto 0);
    signal reg_dma_3_in_pkt_cnt                     : std_logic_vector(32-1 downto 0);
    signal reg_dma_4_in_pkt_cnt                     : std_logic_vector(32-1 downto 0);
    signal reg_dma_0_out_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg_dma_1_out_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg_dma_2_out_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg_dma_3_out_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg_dma_4_out_pkt_cnt                    : std_logic_vector(32-1 downto 0);

    signal reg_netif_0_in_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg_netif_1_in_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg_netif_2_in_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg_netif_3_in_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg_netif_0_out_pkt_cnt                  : std_logic_vector(32-1 downto 0);
    signal reg_netif_1_out_pkt_cnt                  : std_logic_vector(32-1 downto 0);
    signal reg_netif_2_out_pkt_cnt                  : std_logic_vector(32-1 downto 0);
    signal reg_netif_3_out_pkt_cnt                  : std_logic_vector(32-1 downto 0);

    signal reg2_tcp_in_pkt_cnt                      : std_logic_vector(32-1 downto 0);
    signal reg2_resync_tcp_in_pkt_cnt               : std_logic_vector(32-1 downto 0);

    signal reg2_tcp_emi_in_pkt_cnt                  : std_logic_vector(32-1 downto 0);
    signal reg2_resync_tcp_emi_in_pkt_cnt           : std_logic_vector(32-1 downto 0);

    signal reg2_tcp_filtered_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_resync_tcp_filtered_in_pkt_cnt      : std_logic_vector(32-1 downto 0);
    signal reg2_udp_in_pkt_cnt                      : std_logic_vector(32-1 downto 0);
    signal reg2_resync_udp_in_pkt_cnt               : std_logic_vector(32-1 downto 0);
    signal reg2_udp_filtered_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_resync_udp_filtered_in_pkt_cnt      : std_logic_vector(32-1 downto 0);
    signal reg2_raw_0_in_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg2_resync_raw_0_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_raw_0_out_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg2_resync_raw_0_out_pkt_cnt            : std_logic_vector(32-1 downto 0);
    signal reg2_raw_1_in_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg2_resync_raw_1_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_raw_1_out_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg2_resync_raw_1_out_pkt_cnt            : std_logic_vector(32-1 downto 0);
    signal reg2_raw_2_in_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg2_resync_raw_2_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_raw_2_out_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg2_resync_raw_2_out_pkt_cnt            : std_logic_vector(32-1 downto 0);

    signal reg2_dma_0_in_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_0_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_dma_1_in_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_1_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_dma_2_in_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_2_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_dma_3_in_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_3_in_pkt_cnt             : std_logic_vector(32-1 downto 0);
    signal reg2_dma_4_in_pkt_cnt                    : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_4_in_pkt_cnt             : std_logic_vector(32-1 downto 0);

    signal reg2_dma_0_out_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_0_out_pkt_cnt            : std_logic_vector(32-1 downto 0);
    signal reg2_dma_1_out_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_1_out_pkt_cnt            : std_logic_vector(32-1 downto 0);
    signal reg2_dma_2_out_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_2_out_pkt_cnt            : std_logic_vector(32-1 downto 0);
    signal reg2_dma_3_out_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_3_out_pkt_cnt            : std_logic_vector(32-1 downto 0);
    signal reg2_dma_4_out_pkt_cnt                   : std_logic_vector(32-1 downto 0);
    signal reg2_resync_dma_4_out_pkt_cnt            : std_logic_vector(32-1 downto 0);

    signal reg2_netif_0_in_pkt_cnt                  : std_logic_vector(32-1 downto 0);
    signal reg2_resync_netif_0_in_pkt_cnt           : std_logic_vector(32-1 downto 0);
    signal reg2_netif_0_out_pkt_cnt                 : std_logic_vector(32-1 downto 0);
    signal reg2_resync_netif_0_out_pkt_cnt          : std_logic_vector(32-1 downto 0);

    signal reg2_netif_1_in_pkt_cnt                  : std_logic_vector(32-1 downto 0);
    signal reg2_resync_netif_1_in_pkt_cnt           : std_logic_vector(32-1 downto 0);
    signal reg2_netif_1_out_pkt_cnt                 : std_logic_vector(32-1 downto 0);
    signal reg2_resync_netif_1_out_pkt_cnt          : std_logic_vector(32-1 downto 0);


    -- 0-3 addresses are reserved by Enyx, set REGISTER_OFFSET to 4 if you want your sandbox register mapping to start at 0,
    -- The translation will be done by nxavl_mm_slave_core
    -- For example the software writing to register MM_SCRATCH_REGISTER at address 16 (in Bytes) will be translated to address 0 in the sandbox.

    constant REGISTER_OFFSET                        : natural := 4;

    -- Start at 4 in order to generate proper XML, it will be removed later on
    constant MM_SCRATCH_REGISTER                    : natural := 4;  --%32@hex@CFG: MM_SCRATCH_REGISTER

    constant MM_TCP_PKT_COUNT                       : natural := 5;  --%32@int@MON: MM_TCP_PKT_COUNT
    constant MM_TCP_EMI_PKT_COUNT                   : natural := 6;  --%32@int@MON: MM_TCP_EMI_PKT_COUNT
    constant MM_TCP_FILTERED_PKT_COUNT              : natural := 7;  --%32@int@MON: MM_TCP_FILTERED_PKT_COUNT

    constant MM_UDP_PKT_COUNT                       : natural := 8;  --%32@int@MON: MM_UDP_PKT_COUNT
    constant MM_UDP_FILTERED_PKT_COUNT              : natural := 9;  --%32@int@MON: MM_UDP_FILTERED_PKT_COUNT

    constant MM_RAW_0_IN_PKT_COUNT                  : natural := 10;  --%32@int@MON: MM_RAW_0_IN_PKT_COUNT
    constant MM_RAW_0_OUT_PKT_COUNT                 : natural := 11;  --%32@int@MON: MM_RAW_0_OUT_PKT_COUNT
    constant MM_RAW_1_IN_PKT_COUNT                  : natural := 12;  --%32@int@MON: MM_RAW_1_IN_PKT_COUNT
    constant MM_RAW_1_OUT_PKT_COUNT                 : natural := 13;  --%32@int@MON: MM_RAW_1_OUT_PKT_COUNT
    constant MM_RAW_2_IN_PKT_COUNT                  : natural := 14;  --%32@int@MON: MM_RAW_2_IN_PKT_COUNT
    constant MM_RAW_2_OUT_PKT_COUNT                 : natural := 15;  --%32@int@MON: MM_RAW_2_OUT_PKT_COUNT

    constant MM_DMA_0_IN_PKT_COUNT                  : natural := 16; --%32@int@MON: MM_DMA_0_IN_PKT_COUNT
    constant MM_DMA_0_OUT_PKT_COUNT                 : natural := 17; --%32@int@MON: MM_DMA_0_OUT_PKT_COUNT
    constant MM_DMA_1_IN_PKT_COUNT                  : natural := 18; --%32@int@MON: MM_DMA_1_IN_PKT_COUNT
    constant MM_DMA_1_OUT_PKT_COUNT                 : natural := 19; --%32@int@MON: MM_DMA_1_OUT_PKT_COUNT
    constant MM_DMA_2_IN_PKT_COUNT                  : natural := 20; --%32@int@MON: MM_DMA_2_IN_PKT_COUNT
    constant MM_DMA_2_OUT_PKT_COUNT                 : natural := 21; --%32@int@MON: MM_DMA_2_OUT_PKT_COUNT
    constant MM_DMA_3_IN_PKT_COUNT                  : natural := 22; --%32@int@MON: MM_DMA_3_IN_PKT_COUNT
    constant MM_DMA_3_OUT_PKT_COUNT                 : natural := 23; --%32@int@MON: MM_DMA_3_OUT_PKT_COUNT
    constant MM_DMA_4_IN_PKT_COUNT                  : natural := 24; --%32@int@MON: MM_DMA_4_IN_PKT_COUNT
    constant MM_DMA_4_OUT_PKT_COUNT                 : natural := 25; --%32@int@MON: MM_DMA_4_OUT_PKT_COUNT

    constant MM_NETIF_0_IN_PKT_COUNT                : natural := 26; --%32@int@MON: MM_NETIF_0_IN_PKT_COUNT
    constant MM_NETIF_0_OUT_PKT_COUNT               : natural := 27; --%32@int@MON: MM_NETIF_0_OUT_PKT_COUNT
    constant MM_NETIF_1_IN_PKT_COUNT                : natural := 28; --%32@int@MON: MM_NETIF_1_IN_PKT_COUNT
    constant MM_NETIF_1_OUT_PKT_COUNT               : natural := 29; --%32@int@MON: MM_NETIF_1_OUT_PKT_COUNT

    constant MINOR                                  : natural := 0;
    constant MAJOR                                  : natural := 2;
    --! Version History
    --! Major = 1
    --!     ->>>  Minor = 0 = Initial Release of nxuser_sandbox_smartnic
    --! Major = 2
    --!     ->>>  Minor = 0 = Rename nonoffloaded to filtered, separate TCP adn UDP on different PHY (add one RAW and one NETIF interface)

    signal w_mm_local_reset                             : std_logic;
    signal w_mm_master_in_user_sandbox_read             : std_logic;
    signal w_mm_master_in_user_sandbox_write            : std_logic;
    signal w_mm_master_in_user_sandbox_address          : std_logic_vector(AVL_MM_ADDR_WIDTH-1 downto 0);
    signal w_mm_master_in_user_sandbox_byteenable       : std_logic_vector(4-1 downto 0);
    signal w_mm_master_in_user_sandbox_writedata        : std_logic_vector(32-1 downto 0);
    signal w_mm_master_in_user_sandbox_burstcount       : std_logic_vector(8-1 downto 0);

    signal w_mm_master_out_user_sandbox_readdata        : std_logic_vector(32-1 downto 0);
    signal w_mm_master_out_user_sandbox_readdatavalid   : std_logic;
    signal w_mm_master_out_user_sandbox_waitrequest     : std_logic;

    --ST_FILTER TO ARBITER SIGNAL
    signal w_raw_filtered_user_out_ready                : std_logic;
    signal w_raw_filtered_user_out_valid                : std_logic;
    signal w_raw_filtered_user_out_data                 : std_logic_vector(RAW_SANDBOX_ST_OUT_DATA_WIDTH-1 downto 0);
    signal w_raw_filtered_user_out_empty                : std_logic_vector(RAW_SANDBOX_ST_OUT_EMPTY_WIDTH-1 downto 0);
    signal w_raw_filtered_user_out_sop                  : std_logic;
    signal w_raw_filtered_user_out_eop                  : std_logic;
    signal w_raw_filtered_user_out_error                : std_logic;
    signal w_raw_filtered_user_out_size                 : std_logic_vector(16-1 downto 0);

    signal w_tcp_user_in_ready                          : std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);
    signal r_tcp_user_in_ready                          : std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);
    signal r_tcp_user_in_valid                          : std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);
    signal r_tcp_user_in_eop                            : std_logic_vector(int_to_natural(TCP_COUNT-1) downto 0);

    signal w_tcp_emi_in_ready                           : std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);
    signal r_tcp_emi_in_ready                           : std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);
    signal r_tcp_emi_in_valid                           : std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);
    signal r_tcp_emi_in_eop                             : std_logic_vector(int_to_natural(TCP_EMI_COUNT-1) downto 0);

    signal w_tcp_filtered_in_ready                      : std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0);
    signal r_tcp_filtered_in_ready                      : std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0);
    signal r_tcp_filtered_in_valid                      : std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0);
    signal r_tcp_filtered_in_eop                        : std_logic_vector(int_to_natural(TCP_FILTERED_COUNT-1) downto 0);

    signal w_udp_user_in_ready                          : std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);
    signal r_udp_user_in_ready                          : std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);
    signal r_udp_user_in_valid                          : std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);
    signal r_udp_user_in_eop                            : std_logic_vector(int_to_natural(UDP_COUNT-1) downto 0);

    signal w_udp_filtered_in_ready                      : std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0);
    signal r_udp_filtered_in_ready                      : std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0);
    signal r_udp_filtered_in_valid                      : std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0);
    signal r_udp_filtered_in_eop                        : std_logic_vector(int_to_natural(UDP_FILTERED_COUNT-1) downto 0);

    signal w_raw_user_in_ready                          : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
    signal r_raw_user_in_ready                          : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
    signal r_raw_user_in_valid                          : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
    signal r_raw_user_in_eop                            : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);

    signal w_raw_user_out_valid                         : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
    signal w_raw_user_out_eop                           : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
    signal r_raw_user_out_ready                         : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
    signal r_raw_user_out_valid                         : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);
    signal r_raw_user_out_eop                           : std_logic_vector(int_to_natural(RAW_COUNT-1) downto 0);

    signal w_dma_user_in_ready                          : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
    signal r_dma_user_in_ready                          : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
    signal r_dma_user_in_valid                          : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
    signal r_dma_user_in_eop                            : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);

    signal w_dma_user_out_valid                         : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
    signal w_dma_user_out_eop                           : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
    signal r_dma_user_out_ready                         : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
    signal r_dma_user_out_valid                         : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);
    signal r_dma_user_out_eop                           : std_logic_vector(int_to_natural(DMA_COUNT-1) downto 0);

    signal w_netif_user_in_ready                        : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal r_netif_user_in_ready                        : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal r_netif_user_in_valid                        : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal r_netif_user_in_eop                          : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);

    signal w_netif_user_out_valid                       : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal w_netif_user_out_eop                         : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal r_netif_user_out_ready                       : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal r_netif_user_out_valid                       : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal r_netif_user_out_eop                         : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);

    signal w_netif_user_out_ready                       : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0):= (others => '0');
    signal w_netif_user_out_data                        : std_logic_vector(int_to_natural(NETIF_COUNT*NETIF_SANDBOX_ST_OUT_DATA_WIDTH-1) downto 0);
    signal w_netif_user_out_empty                       : std_logic_vector(int_to_natural(NETIF_COUNT*NETIF_SANDBOX_ST_OUT_EMPTY_WIDTH-1) downto 0);
    signal w_netif_user_out_sop                         : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal w_netif_user_out_error                       : std_logic_vector(int_to_natural(NETIF_COUNT-1) downto 0);
    signal w_netif_user_out_size                        : std_logic_vector(int_to_natural(16*NETIF_COUNT-1) downto 0);

begin

    inst_nxavl_mm_slave_core : nxavl_mm_slave_core
    generic map(
        COMPONENT_IDENTIFIER      => core_id_enum'pos(NXUSER_SANDBOX_SMARTNIC_ID)+1,
        COMPONENT_MAJOR_VERSION   => MAJOR,
        COMPONENT_MINOR_VERSION   => MINOR,
        ADDR_WIDTH                => AVL_MM_ADDR_WIDTH,
        IN_ADDR_OFFSET            => REGISTER_OFFSET,
        OUT_ADDR_OFFSET           => 0
    )
    port map(
        mm_clk                  => mm_slave_clk,
        mm_reset                => mm_slave_reset,
        mm_local_reset          => w_mm_local_reset,

        mm_slave_read           => mm_slave_read,
        mm_slave_write          => mm_slave_write,
        mm_slave_address        => mm_slave_address,
        mm_slave_byteenable     => mm_slave_byteenable,
        mm_slave_writedata      => mm_slave_writedata,
        mm_slave_burstcount     => mm_slave_burstcount,

        mm_slave_readdata       => mm_slave_readdata,
        mm_slave_readdatavalid  => mm_slave_readdatavalid,
        mm_slave_waitrequest    => mm_slave_waitrequest,

        mm_master_read          => w_mm_master_in_user_sandbox_read,
        mm_master_write         => w_mm_master_in_user_sandbox_write,
        mm_master_address       => w_mm_master_in_user_sandbox_address,
        mm_master_byteenable    => w_mm_master_in_user_sandbox_byteenable,
        mm_master_writedata     => w_mm_master_in_user_sandbox_writedata,
        mm_master_burstcount    => w_mm_master_in_user_sandbox_burstcount,

        mm_master_readdata      => w_mm_master_out_user_sandbox_readdata,
        mm_master_readdatavalid => w_mm_master_out_user_sandbox_readdatavalid,
        mm_master_waitrequest   => w_mm_master_out_user_sandbox_waitrequest
    );

    ------------
    -- TCP IN --
    ------------
    p_packet_counters_tcp_in : process(tcp_user_in_clk)
    begin
        if rising_edge(tcp_user_in_clk(0)) then
            r_tcp_user_in_ready(0)  <= w_tcp_user_in_ready(0);
            r_tcp_user_in_valid(0)  <= tcp_user_in_valid(0);
            r_tcp_user_in_eop(0)    <= tcp_user_in_eop(0);
            reg2_tcp_in_pkt_cnt     <= reg_tcp_in_pkt_cnt;
            if (r_tcp_user_in_valid(0) = '1' and r_tcp_user_in_eop(0) = '1' and r_tcp_user_in_ready(0) = '1')then
                reg_tcp_in_pkt_cnt <= std_inc(reg_tcp_in_pkt_cnt,1);
            end if;
            if tcp_user_in_reset(0) = '1' then
                reg_tcp_in_pkt_cnt      <= (others => '0');
                reg2_tcp_in_pkt_cnt     <= (others => '-');
                r_tcp_user_in_ready(0)  <= '-';
                r_tcp_user_in_valid(0)  <= '-';
                r_tcp_user_in_eop(0)    <= '0';
            end if;
        end if;
    end process;

    mm_resync_tcp_in : reg_data
    generic map(
        DATA_WIDTH  => reg2_tcp_in_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_tcp_in_pkt_cnt,
        out_data    => reg2_resync_tcp_in_pkt_cnt
    );

    -------------
    -- TCP EMI --
    -------------
    p_packet_counters_tcp_emi_in : process(tcp_emi_in_clk)
    begin
        if rising_edge(tcp_emi_in_clk(0)) then
            r_tcp_emi_in_ready(0)       <= w_tcp_emi_in_ready(0);
            r_tcp_emi_in_valid(0)       <= tcp_emi_in_valid(0);
            r_tcp_emi_in_eop(0)         <= tcp_emi_in_eop(0);
            reg2_tcp_emi_in_pkt_cnt     <= reg_tcp_emi_in_pkt_cnt;
            if (r_tcp_emi_in_valid(0)='1' and r_tcp_emi_in_eop(0)='1' and r_tcp_emi_in_ready(0)='1') then
                reg_tcp_emi_in_pkt_cnt <= std_inc(reg_tcp_emi_in_pkt_cnt,1);
            end if;
            if tcp_emi_in_reset(0) = '1' then
                reg_tcp_emi_in_pkt_cnt      <= (others => '0');
                reg2_tcp_emi_in_pkt_cnt     <= (others => '-');
                r_tcp_emi_in_ready(0)       <= '-';
                r_tcp_emi_in_valid(0)       <= '-';
                r_tcp_emi_in_eop(0)         <= '0';
            end if;
        end if;
    end process;

    mm_resync_tcp_emi_in : reg_data
    generic map(
        DATA_WIDTH  => reg2_tcp_emi_in_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_tcp_emi_in_pkt_cnt,
        out_data    => reg2_resync_tcp_emi_in_pkt_cnt
    );

    ------------
    -- RAW 0 IN --
    ------------
    p_packet_counters_raw_0_in : process(raw_user_in_clk)
    begin
        if rising_edge(raw_user_in_clk(0)) then
            r_raw_user_in_ready(0)    <= w_raw_user_in_ready(0);
            r_raw_user_in_valid(0)    <= raw_user_in_valid(0);
            r_raw_user_in_eop(0)      <= raw_user_in_eop(0);
            reg2_raw_0_in_pkt_cnt     <= reg_raw_0_in_pkt_cnt;
            if (r_raw_user_in_valid(0)='1' and r_raw_user_in_eop(0)='1' and r_raw_user_in_ready(0)='1') then
                reg_raw_0_in_pkt_cnt <= std_inc(reg_raw_0_in_pkt_cnt,1);
            end if;
            if raw_user_in_reset(0) = '1' then
                reg_raw_0_in_pkt_cnt      <= (others => '0');
                reg2_raw_0_in_pkt_cnt     <= (others => '-');
                r_raw_user_in_ready(0)    <= '-';
                r_raw_user_in_valid(0)    <= '-';
                r_raw_user_in_eop(0)      <= '0';
            end if;
        end if;
    end process;

    mm_resync_raw_0_in : reg_data
    generic map(
        DATA_WIDTH  => reg2_raw_0_in_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_raw_0_in_pkt_cnt,
        out_data    => reg2_resync_raw_0_in_pkt_cnt
    );

    ---------------
    -- RAW 0 OUT --
    ---------------
    p_packet_counters_raw_0_out : process(raw_user_out_clk)
    begin
        if rising_edge(raw_user_out_clk(0)) then
            r_raw_user_out_ready(0)    <= raw_user_out_ready(0);
            r_raw_user_out_valid(0)    <= w_raw_user_out_valid(0);
            r_raw_user_out_eop(0)      <= w_raw_user_out_eop(0);
            reg2_raw_0_out_pkt_cnt     <= reg_raw_0_out_pkt_cnt;
            if (r_raw_user_out_valid(0)='1' and r_raw_user_out_eop(0)='1' and r_raw_user_out_ready(0)='1') then
                reg_raw_0_out_pkt_cnt <= std_inc(reg_raw_0_out_pkt_cnt,1);
            end if;
            if raw_user_out_reset(0) = '1' then
                reg_raw_0_out_pkt_cnt      <= (others => '0');
                reg2_raw_0_out_pkt_cnt     <= (others => '-');
                r_raw_user_out_ready(0)    <= '-';
                r_raw_user_out_valid(0)    <= '-';
                r_raw_user_out_eop(0)      <= '0';
            end if;
        end if;
    end process;

    mm_resync_raw_0_out : reg_data
    generic map(
        DATA_WIDTH  => reg2_raw_0_out_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_raw_0_out_pkt_cnt,
        out_data    => reg2_resync_raw_0_out_pkt_cnt
    );

    ------------
    -- RAW 1 IN --
    ------------
    p_packet_counters_raw_1_in : process(raw_user_in_clk)
    begin
        if rising_edge(raw_user_in_clk(1)) then
            r_raw_user_in_ready(1)    <= w_raw_user_in_ready(1);
            r_raw_user_in_valid(1)    <= raw_user_in_valid(1);
            r_raw_user_in_eop(1)      <= raw_user_in_eop(1);
            reg2_raw_1_in_pkt_cnt     <= reg_raw_1_in_pkt_cnt;
            if (r_raw_user_in_valid(1)='1' and r_raw_user_in_eop(1)='1' and r_raw_user_in_ready(1)='1') then
                reg_raw_1_in_pkt_cnt <= std_inc(reg_raw_1_in_pkt_cnt,1);
            end if;
            if raw_user_in_reset(1) = '1' then
                reg_raw_1_in_pkt_cnt      <= (others => '0');
                reg2_raw_1_in_pkt_cnt     <= (others => '-');
                r_raw_user_in_ready(1)    <= '-';
                r_raw_user_in_valid(1)    <= '-';
                r_raw_user_in_eop(1)      <= '0';
            end if;
        end if;
    end process;

    mm_resync_raw_1_in : reg_data
    generic map(
        DATA_WIDTH  => reg2_raw_1_in_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_raw_1_in_pkt_cnt,
        out_data    => reg2_resync_raw_1_in_pkt_cnt
    );

    ---------------
    -- RAW 1 OUT --
    ---------------
    p_packet_counters_raw_1_out : process(raw_user_out_clk)
    begin
        if rising_edge(raw_user_out_clk(1)) then
            r_raw_user_out_ready(1)    <= raw_user_out_ready(1);
            r_raw_user_out_valid(1)    <= w_raw_user_out_valid(1);
            r_raw_user_out_eop(1)      <= w_raw_user_out_eop(1);
            reg2_raw_1_out_pkt_cnt     <= reg_raw_1_out_pkt_cnt;
            if (r_raw_user_out_valid(1) = '1' and r_raw_user_out_eop(1) = '1' and r_raw_user_out_ready(1) = '1') then
                reg_raw_1_out_pkt_cnt <= std_inc(reg_raw_1_out_pkt_cnt,1);
            end if;
            if raw_user_out_reset(1) = '1' then
                reg_raw_1_out_pkt_cnt      <= (others => '0');
                reg2_raw_1_out_pkt_cnt     <= (others => '-');
                r_raw_user_out_ready(1)    <= '-';
                r_raw_user_out_valid(1)    <= '-';
                r_raw_user_out_eop(1)      <= '0';
            end if;
        end if;
    end process;

    mm_resync_raw_1_out : reg_data
    generic map(
        DATA_WIDTH  => reg2_raw_1_out_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_raw_1_out_pkt_cnt,
        out_data    => reg2_resync_raw_1_out_pkt_cnt
    );


    -------------------------------
    -- DMA 0 IN TCP2USER PAYLOAD --
    -------------------------------
    p_packet_counters_dma_0_in : process(dma_user_in_clk)
    begin
        if rising_edge(dma_user_in_clk(0)) then
            r_dma_user_in_ready(0)    <= w_dma_user_in_ready(0);
            r_dma_user_in_valid(0)    <= dma_user_in_valid(0);
            r_dma_user_in_eop(0)      <= dma_user_in_eop(0);
            reg2_dma_0_in_pkt_cnt     <= reg_dma_0_in_pkt_cnt;
            if (r_dma_user_in_valid(0)='1' and r_dma_user_in_eop(0)='1' and r_dma_user_in_ready(0)='1') then
                reg_dma_0_in_pkt_cnt <= std_inc(reg_dma_0_in_pkt_cnt,1);
            end if;
            if dma_user_in_reset(0) = '1' then
                reg_dma_0_in_pkt_cnt      <= (others => '0');
                reg2_dma_0_in_pkt_cnt     <= (others => '-');
                r_dma_user_in_ready(0)    <= '-';
                r_dma_user_in_valid(0)    <= '-';
                r_dma_user_in_eop(0)      <= '0';
            end if;
        end if;
    end process;

    mm_resync_dma_0_in : reg_data
    generic map(
        DATA_WIDTH  => reg2_dma_0_in_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_dma_0_in_pkt_cnt,
        out_data    => reg2_resync_dma_0_in_pkt_cnt
    );

    --------------------------------
    -- DMA 0 OUT USER2TCP PAYLOAD --
    --------------------------------
    p_packet_counters_dma_0_out : process(dma_user_out_clk)
    begin
        if rising_edge(dma_user_out_clk(0)) then
            r_dma_user_out_ready(0)    <= dma_user_out_ready(0);
            r_dma_user_out_valid(0)    <= w_dma_user_out_valid(0);
            r_dma_user_out_eop(0)      <= w_dma_user_out_eop(0);
            reg2_dma_0_out_pkt_cnt     <= reg_dma_0_out_pkt_cnt;
            if (r_dma_user_out_valid(0)='1' and r_dma_user_out_eop(0)='1' and r_dma_user_out_ready(0)='1') then
                reg_dma_0_out_pkt_cnt <= std_inc(reg_dma_0_out_pkt_cnt,1);
            end if;
            if dma_user_out_reset(0) = '1' then
                reg_dma_0_out_pkt_cnt      <= (others => '0');
                reg2_dma_0_out_pkt_cnt     <= (others => '-');
                r_dma_user_out_ready(0)    <= '-';
                r_dma_user_out_valid(0)    <= '-';
                r_dma_user_out_eop(0)      <= '0';
            end if;
        end if;
    end process;

    mm_resync_dma_0_out : reg_data
    generic map(
        DATA_WIDTH  => reg2_dma_0_out_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_dma_0_out_pkt_cnt,
        out_data    => reg2_resync_dma_0_out_pkt_cnt
    );

    -----------------------
    -- DMA 1 IN  TCP EMI --
    -----------------------
    p_packet_counters_dma_1_in : process(dma_user_in_clk)
    begin
        if rising_edge(dma_user_in_clk(1)) then
            r_dma_user_in_ready(1)    <= w_dma_user_in_ready(1);
            r_dma_user_in_valid(1)    <= dma_user_in_valid(1);
            r_dma_user_in_eop(1)      <= dma_user_in_eop(1);
            reg2_dma_1_in_pkt_cnt <= reg_dma_1_in_pkt_cnt;
            if (r_dma_user_in_valid(1)='1' and r_dma_user_in_eop(1)='1' and r_dma_user_in_ready(1)='1') then
                reg_dma_1_in_pkt_cnt <= std_inc(reg_dma_1_in_pkt_cnt,1);
            end if;
            if dma_user_in_reset(1) = '1' then
                reg_dma_1_in_pkt_cnt      <= (others => '0');
                reg2_dma_1_in_pkt_cnt     <= (others => '-');
                r_dma_user_in_ready(1)    <= '-';
                r_dma_user_in_valid(1)    <= '-';
                r_dma_user_in_eop(1)      <= '0';
            end if;
        end if;
    end process;

    mm_resync_dma_1_in : reg_data
    generic map(
        DATA_WIDTH  => reg2_dma_1_in_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_dma_1_in_pkt_cnt,
        out_data    => reg2_resync_dma_1_in_pkt_cnt
    );

    ---------------------------------
    -- DMA 1 IN  TCP EMI (USELESS) --
    ---------------------------------
    p_packet_counters_dma_1_out : process(dma_user_out_clk)
    begin
        if rising_edge(dma_user_out_clk(1)) then
            r_dma_user_out_ready(1)    <= dma_user_out_ready(1);
            r_dma_user_out_valid(1)    <= w_dma_user_out_valid(1);
            r_dma_user_out_eop(1)      <= w_dma_user_out_eop(1);
            reg2_dma_1_out_pkt_cnt     <= reg_dma_1_out_pkt_cnt;
            if (r_dma_user_out_valid(1)='1' and r_dma_user_out_eop(1)='1' and r_dma_user_out_ready(1)='1') then
                reg_dma_1_out_pkt_cnt <= std_inc(reg_dma_1_out_pkt_cnt,1);
            end if;
            if dma_user_out_reset(1) = '1' then
                reg_dma_1_out_pkt_cnt      <= (others => '0');
                reg2_dma_1_out_pkt_cnt     <= (others => '-');
                r_dma_user_out_ready(1)    <= '-';
                r_dma_user_out_valid(1)    <= '-';
                r_dma_user_out_eop(1)      <= '0';
            end if;
        end if;
    end process;

    mm_resync_dma_1_out : reg_data
    generic map(
        DATA_WIDTH  => reg2_dma_1_out_pkt_cnt'length,
        REG_COUNT   => 3,
        DUAL_CLOCK  => true,
        SHIFT_REG   => false
    )
    port map(
        clk         => mm_slave_clk,
        reset       => mm_slave_reset,

        in_data     => reg2_dma_1_out_pkt_cnt,
        out_data    => reg2_resync_dma_1_out_pkt_cnt
    );


    i_sifter_test_wrapper: sifter_test_wrapper 
      port map (
        -- MM 
        mm_master_clk            => mm_slave_clk,
        mm_master_reset          => w_mm_local_reset,
        mm_master_read           => w_mm_master_in_user_sandbox_read,
        mm_master_write          => w_mm_master_in_user_sandbox_write,
        mm_master_address        => w_mm_master_in_user_sandbox_address(19-1 downto 0),
        mm_master_byteenable     => w_mm_master_in_user_sandbox_byteenable,
        mm_master_writedata      => w_mm_master_in_user_sandbox_writedata,
        mm_master_burstcount     => w_mm_master_in_user_sandbox_burstcount,
        mm_master_readdata       => w_mm_master_out_user_sandbox_readdata,
        mm_master_readdatavalid  => w_mm_master_out_user_sandbox_readdatavalid,
        mm_master_waitrequest    => w_mm_master_out_user_sandbox_waitrequest
    );
 
    -------------------
    -- DMA   MAPPING --
    -------------------
    dma_user_in_ready   <= w_dma_user_in_ready;
    dma_user_out_valid  <= w_dma_user_out_valid;
    dma_user_out_eop    <= w_dma_user_out_eop;


    --TCP 0 DMA 0
    inst_tcp_hdr_handler : nxtcp_hdr_handler
    generic map (
        TCP_IN_DATA_WIDTH        => TCP_SANDBOX_ST_IN_DATA_WIDTH,
        TCP_USER_IN_DATA_WIDTH   => TCP_SANDBOX_ST_OUT_DATA_WIDTH,
        ADD_OUTPUT_PIPE          => 1,
        ADD_INPUT_PIPE           => 1
    )
    port map (
        clk                  => tcp_user_in_clk(0),
        reset                => tcp_user_in_reset(0),

        tcp_in_ready         => w_tcp_user_in_ready(0),
        tcp_in_valid         => tcp_user_in_valid(0),
        tcp_in_data          => tcp_user_in_data(TCP_SANDBOX_ST_IN_DATA_WIDTH-1 downto 0),
        tcp_in_empty         => tcp_user_in_empty(TCP_SANDBOX_ST_IN_EMPTY_WIDTH-1 downto 0),
        tcp_in_sop           => tcp_user_in_sop(0),
        tcp_in_eop           => tcp_user_in_eop(0),
        tcp_in_error         => tcp_user_in_error(0),
        tcp_in_session_id    => tcp_user_in_session_id(20-1 downto 0),
        tcp_in_payload_size  => tcp_user_in_payload_size(16-1 downto 0),

        tcp_out_ready        => tcp_user_out_ready(0),
        tcp_out_valid        => tcp_user_out_valid(0),
        tcp_out_data         => tcp_user_out_data(TCP_SANDBOX_ST_OUT_DATA_WIDTH-1 downto 0),
        tcp_out_empty        => tcp_user_out_empty(TCP_SANDBOX_ST_OUT_EMPTY_WIDTH-1 downto 0),
        tcp_out_sop          => tcp_user_out_sop(0),
        tcp_out_eop          => tcp_user_out_eop(0),
        tcp_out_error        => tcp_user_out_error(0),
        tcp_out_session_id   => tcp_user_out_session_id(20-1 downto 0), --out std_logic_vector(TCP_MULTI_SESSION_ID_WIDTH-1 downto );

        tcp_user_in_ready    => w_dma_user_in_ready(0),
        tcp_user_in_valid    => dma_user_in_valid(0),
        tcp_user_in_data     => dma_user_in_data(TCP_SANDBOX_ST_IN_DATA_WIDTH-1 downto 0),
        tcp_user_in_empty    => dma_user_in_empty(TCP_SANDBOX_ST_IN_EMPTY_WIDTH-1 downto 0),
        tcp_user_in_sop      => dma_user_in_sop(0),
        tcp_user_in_eop      => dma_user_in_eop(0),
        tcp_user_in_error    => dma_user_in_error(0),

        tcp_user_out_ready   => dma_user_out_ready(0),
        tcp_user_out_valid   => w_dma_user_out_valid(0),
        tcp_user_out_data    => dma_user_out_data(TCP_SANDBOX_ST_OUT_DATA_WIDTH-1 downto 0),
        tcp_user_out_empty   => dma_user_out_empty(TCP_SANDBOX_ST_OUT_EMPTY_WIDTH-1 downto 0),
        tcp_user_out_sop     => dma_user_out_sop(0),
        tcp_user_out_eop     => w_dma_user_out_eop(0),
        tcp_user_out_error   => dma_user_out_error(0),
        tcp_user_out_size    => open --Size is fed to the HFP core. It is provided by the input tcp_user_in_payload_size signal which is itself computed by the TCP to Sandbox FIFO (with the Store and Forward feature enabled)
    );

    dma_user_out_size(16-1 downto 0)    <=  (others =>'0') ;
    tcp_user_in_ready(0)                <= w_tcp_user_in_ready(0);
    tcp_user_out_payload_size           <= (others =>'0') ;
    tcp_user_out_payload_chk            <= (others =>'0') ;


    --TCP 0 EMI DMA 1
    w_tcp_emi_in_ready(0)   <= dma_user_out_ready(1);
    tcp_emi_in_ready(0)     <= w_tcp_emi_in_ready(0);
    w_dma_user_out_valid(1) <= tcp_emi_in_valid(0);
    dma_user_out_data ((1+1)*DMA_SANDBOX_ST_OUT_DATA_WIDTH-1  downto 1*DMA_SANDBOX_ST_OUT_DATA_WIDTH)  <= tcp_emi_in_data;
    dma_user_out_empty((1+1)*DMA_SANDBOX_ST_OUT_EMPTY_WIDTH-1 downto 1*DMA_SANDBOX_ST_OUT_EMPTY_WIDTH) <= tcp_emi_in_empty;
    dma_user_out_sop(1)     <= tcp_emi_in_sop(0);
    w_dma_user_out_eop(1)   <= tcp_emi_in_eop(0);
    dma_user_out_error(1)   <= tcp_emi_in_error(0);
    dma_user_out_size((1+1)*16-1 downto (1)*16) <= (others => '0');

    w_dma_user_in_ready(1)      <= tcp_emi_out_ready(0);
    tcp_emi_out_valid(0)        <= dma_user_in_valid(1);
    tcp_emi_out_data            <= dma_user_in_data((1+1)*DMA_SANDBOX_ST_IN_DATA_WIDTH-1 downto 1*DMA_SANDBOX_ST_IN_DATA_WIDTH);
    tcp_emi_out_empty           <= dma_user_in_empty((1+1)*DMA_SANDBOX_ST_IN_EMPTY_WIDTH-1 downto 1*DMA_SANDBOX_ST_IN_EMPTY_WIDTH);
    tcp_emi_out_sop(0)          <= dma_user_in_sop(1);
    tcp_emi_out_eop(0)          <= dma_user_in_eop(1);
    tcp_emi_out_error(0)        <= dma_user_in_error(1);

end architecture;
