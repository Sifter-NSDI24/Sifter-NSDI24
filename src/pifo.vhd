-- PIFO module
-- TO DO:


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.log2;
--use work.gb_package.all;

entity pifo is
  generic (
    g_L2_PIFO_SIZE     : integer;    -- log2 of size
    g_PIFO_DATA_WIDTH  : integer;    -- Descriptor width
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
end pifo;

architecture pifo_arch of pifo is

  constant PIFO_SIZE : positive := 2**g_L2_PIFO_SIZE;

  type t_reg_array is array(PIFO_SIZE-1 downto 0) of std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);
  signal pifo_data   : t_reg_array;
  signal pifo_valid  : std_logic_vector(PIFO_SIZE-1 downto 0);
  signal insert_idx  : integer range -1 to PIFO_SIZE-1;
  signal insert_idx_dbg  : integer range -1 to PIFO_SIZE-1;
  signal insert_idx_found: boolean;
  signal push_rank   : unsigned(g_RANK_WIDTH-1 downto 0);
  signal pop_rank   : unsigned(g_RANK_WIDTH-1 downto 0);
  signal push_cmd_r  : std_logic;
  signal push_data_r : std_logic_vector(g_PIFO_DATA_WIDTH-1 downto 0);

begin

  push_rank <= unsigned(push_data(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));

  p_pifo: process(rst, clk)
  variable v_insert_idx_found: boolean := false;
  variable v_push_rank: unsigned(g_RANK_WIDTH-1 downto 0);
  type t_rank_array is array(PIFO_SIZE-1 downto 0) of unsigned(g_RANK_WIDTH-1 downto 0);
  variable v_pifo_rank: t_rank_array;

  begin
    if rst = '1' then
      evicted_valid    <= '0';
      fill_level       <= (others => '0');
      empty            <= '1';
      full             <= '0';
      pifo_data        <= (others => (others => '0'));
      pifo_valid       <= (others => '0');
      max_rank_valid   <= '0';
      v_insert_idx_found := false;
      insert_idx_found <= false;
      push_cmd_r       <= '0';
      
    elsif clk'event and clk = '1' then
      evicted_valid    <= '0';
      v_insert_idx_found := false;
      insert_idx_found <= false;
      push_cmd_r <= push_cmd;
      push_data_r <= push_data;

      -- Clk 1: find insertion point
      v_push_rank := unsigned(push_data(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
      --push_rank <= v_push_rank;
      if push_cmd = '1' then
        for i in 0 to PIFO_SIZE-1 loop
          v_pifo_rank(i) := unsigned(pifo_data(i)(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
          if (v_push_rank < v_pifo_rank(i) or pifo_valid(i) = '0') and not v_insert_idx_found then
            if pop_cmd = '0' then
              insert_idx <= i;
            elsif empty /= '1' then
              --if i > 0 then
                insert_idx <= i - 1;
              --else
              --  insert_idx <= 0;
              --end if;
            end if;
            v_insert_idx_found := true;
          end if;
        end loop;
      end if;
      insert_idx_found <= v_insert_idx_found;
      insert_idx_dbg <= insert_idx;
      
      -- Clk 2: shift stored PIFO data and insert new value
      if insert_idx_found then
        -- No simultaneous pop
        if pop_cmd = '0' then
          evicted_data  <= pifo_data(PIFO_SIZE-1);
          evicted_valid <= pifo_valid(PIFO_SIZE-1);
	  if insert_idx > -1 then
            for i in PIFO_SIZE-1 downto 1 loop
              if i >= insert_idx + 1 then
                pifo_data(i) <= pifo_data(i - 1);
                pifo_valid(i) <= pifo_valid(i - 1);
              end if;
            end loop;
            pifo_data(insert_idx)  <= push_data;
            pifo_valid(insert_idx) <= '1';
            empty                  <= '0';
            if fill_level < PIFO_SIZE then
              fill_level           <= fill_level + 1;
            end if;
	  end if;
          if fill_level = PIFO_SIZE - 1 then
            full                 <= '1';
          end if;
        else -- pop arrived 1 clock after push - insert_idx calculated prior to pop
          if insert_idx > 0 then
            for i in PIFO_SIZE-1 downto 0 loop
              if i <= insert_idx - 1 then
                pifo_data(i) <= pifo_data(i + 1);
                pifo_valid(i) <= pifo_valid(i + 1);
              end if;
            end loop;
            pifo_data(insert_idx-1) <= push_data;
            pifo_valid(insert_idx-1) <= '1';
          end if;
          --pifo_data(insert_idx-1) <= push_data;
          --pifo_valid(insert_idx-1) <= '1';
        end if;
      else
        --if pop_cmd = '1' and empty /= '1' then
        if pop_cmd = '1' and empty /= '1' and not (push_cmd = '1' and push_rank < pop_rank) then
          pifo_data(PIFO_SIZE-2 downto 0) <= pifo_data(PIFO_SIZE-1 downto 1);
          pifo_valid(PIFO_SIZE-2 downto 0) <= pifo_valid(PIFO_SIZE-1 downto 1);
          pifo_valid(PIFO_SIZE-1) <= '0';
          if fill_level = 1 then
            empty <= '1';
          end if;
          fill_level <= fill_level - 1;
          full       <= '0';
        end if;
        evicted_data  <= push_data;
        evicted_valid <= push_cmd_r;
      end if;
      -- Output max rank in PIFO
      if (empty = '0') then
        max_rank <= unsigned(pifo_data(to_integer(fill_level-1))(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
        max_rank_valid <= '1' when push_cmd = '0' and not insert_idx_found
                              else '0';
      else
        max_rank_valid <= '0';
      end if;

    end if;
  end process p_pifo;

  
  pop_rank <= unsigned(pifo_data(0)(g_RANK_LSB+g_RANK_WIDTH-1 downto g_RANK_LSB));
  --pop_data <= push_data_r when (push_cmd_r = '1' and insert_idx = 0) or insert_idx = -1  else pifo_data(0); 
  pop_data <= push_data when push_rank < pop_rank and push_cmd = '1' else
	      --push_data_r when (push_cmd_r = '1' and insert_idx = 0) or insert_idx = -1 else
	      push_data_r when (push_cmd_r = '1' and insert_idx = 0) else
	      pifo_data(0); 
  pop_valid <= not empty;
  
end pifo_arch;
