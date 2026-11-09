library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Top-level DE10-Lite : envoie "HELLO\r\n" sur l'UART dès la sortie du reset,
--! puis toutes les PERIODE_ENVOI périodes d'horloge (une seconde par défaut).
--! Les octets passent par une FIFO (VHDL) avant l'émetteur UART (Verilog).
entity top is
  generic (
    CLK_HZ        : positive := 50_000_000;  --! fréquence de l'horloge
    BAUD          : positive := 115_200;     --! débit UART
    PERIODE_ENVOI : positive := 50_000_000   --! cycles entre deux messages
  );
  port (
    clk      : in  std_logic;                     --! MAX10_CLK1_50
    rst_n    : in  std_logic;                     --! KEY0, actif à '0'
    uart_txd : out std_logic;                     --! sortie série
    led      : out std_logic_vector(1 downto 0)   --! LEDR0 : émission, LEDR1 : FIFO non vide
  );
end entity;

architecture rtl of top is
  -- Émetteur UART écrit en Verilog
  component uart_tx is
    generic (CLK_HZ : integer; BAUD : integer);
    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      start : in  std_logic;
      data  : in  std_logic_vector(7 downto 0);
      tx    : out std_logic;
      busy  : out std_logic
    );
  end component;

  type msg_t is array (0 to 6) of std_logic_vector(7 downto 0);
  constant MSG : msg_t := (x"48", x"45", x"4C", x"4C", x"4F", x"0D", x"0A");  -- "HELLO\r\n"

  type etat_t is (ATTENTE, ENVOI, OCCUPE);

  signal rst_sync           : std_logic_vector(1 downto 0) := (others => '1');
  signal rst                : std_logic;
  signal compteur           : natural range 0 to PERIODE_ENVOI-1 := 0;
  signal index              : natural range 0 to 7 := 0;
  signal wr_en, rd_en       : std_logic := '0';
  signal din, dout, data_tx : std_logic_vector(7 downto 0) := (others => '0');
  signal full, empty        : std_logic;
  signal start, busy        : std_logic := '0';
  signal etat               : etat_t := ATTENTE;
begin
  -- Synchronisation du reset (bouton asynchrone)
  process (clk)
  begin
    if rising_edge(clk) then
      rst_sync <= rst_sync(0) & not rst_n;
    end if;
  end process;
  rst <= rst_sync(1);

  -- Écriture du message dans la FIFO
  process (clk)
  begin
    if rising_edge(clk) then
      wr_en <= '0';
      if rst = '1' then
        compteur <= 0;
        index    <= 0;
      else
        if compteur = PERIODE_ENVOI-1 then
          compteur <= 0;
          index    <= 0;
        else
          compteur <= compteur + 1;
        end if;
        if index < 7 and full = '0' then
          din   <= MSG(index);
          wr_en <= '1';
          index <= index + 1;
        end if;
      end if;
    end if;
  end process;

  -- Lecture de la FIFO et pilotage de l'émetteur
  process (clk)
  begin
    if rising_edge(clk) then
      start <= '0';
      rd_en <= '0';
      if rst = '1' then
        etat <= ATTENTE;
      else
        case etat is
          when ATTENTE =>
            if empty = '0' then
              data_tx <= dout;
              rd_en   <= '1';
              start   <= '1';
              etat    <= ENVOI;
            end if;
          when ENVOI =>
            if busy = '1' then
              etat <= OCCUPE;
            end if;
          when OCCUPE =>
            if busy = '0' then
              etat <= ATTENTE;
            end if;
        end case;
      end if;
    end if;
  end process;

  u_fifo : entity work.fifo_sync
    generic map (DATA_W => 8, ADDR_W => 4)
    port map (clk => clk, rst => rst, wr_en => wr_en, din => din,
              rd_en => rd_en, dout => dout, full => full, empty => empty);

  u_tx : uart_tx
    generic map (CLK_HZ => CLK_HZ, BAUD => BAUD)
    port map (clk => clk, rst => rst, start => start, data => data_tx,
              tx => uart_txd, busy => busy);

  led(0) <= busy;
  led(1) <= not empty;
end architecture;
