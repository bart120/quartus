library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! FIFO synchrone de profondeur 2**ADDR_W.
--! Lecture asynchrone : dout présente la donnée la plus ancienne tant que empty = '0'.
entity fifo_sync is
  generic (
    DATA_W : positive := 8;  --! largeur des données
    ADDR_W : positive := 4   --! profondeur = 2**ADDR_W
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;   --! reset synchrone, actif à '1'
    wr_en : in  std_logic;
    din   : in  std_logic_vector(DATA_W-1 downto 0);
    rd_en : in  std_logic;
    dout  : out std_logic_vector(DATA_W-1 downto 0);
    full  : out std_logic;
    empty : out std_logic
  );
end entity;

architecture rtl of fifo_sync is
  type mem_t is array (0 to 2**ADDR_W-1) of std_logic_vector(DATA_W-1 downto 0);
  signal mem             : mem_t;
  signal wr_ptr, rd_ptr  : unsigned(ADDR_W downto 0) := (others => '0');
  signal full_i, empty_i : std_logic;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');
      else
        if wr_en = '1' and full_i = '0' then
          mem(to_integer(wr_ptr(ADDR_W-1 downto 0))) <= din;
          wr_ptr <= wr_ptr + 1;
        end if;
        if rd_en = '1' and empty_i = '0' then
          rd_ptr <= rd_ptr + 1;
        end if;
      end if;
    end if;
  end process;

  empty_i <= '1' when wr_ptr = rd_ptr else '0';
  full_i  <= '1' when wr_ptr(ADDR_W) /= rd_ptr(ADDR_W)
                  and wr_ptr(ADDR_W-1 downto 0) = rd_ptr(ADDR_W-1 downto 0) else '0';

  dout  <= mem(to_integer(rd_ptr(ADDR_W-1 downto 0)));
  full  <= full_i;
  empty <= empty_i;
end architecture;
