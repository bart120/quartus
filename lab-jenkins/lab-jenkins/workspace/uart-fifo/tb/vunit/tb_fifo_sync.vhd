library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_fifo_sync is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_fifo_sync is
  signal clk          : std_logic := '0';
  signal rst          : std_logic := '1';
  signal wr_en, rd_en : std_logic := '0';
  signal din, dout    : std_logic_vector(7 downto 0) := (others => '0');
  signal full, empty  : std_logic;

  function octet(i : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(i, 8));
  end function;
begin
  clk <= not clk after 5 ns;

  dut : entity work.fifo_sync
    generic map (DATA_W => 8, ADDR_W => 4)
    port map (clk => clk, rst => rst, wr_en => wr_en, din => din,
              rd_en => rd_en, dout => dout, full => full, empty => empty);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until rising_edge(clk);
    rst <= '0';
    wait for 1 ns;

    while test_suite loop
      if run("vide apres reset") then
        check_equal(empty, '1');
        check_equal(full, '0');

      elsif run("premier entre premier sorti") then
        for i in 1 to 3 loop
          din <= octet(i); wr_en <= '1';
          wait until rising_edge(clk);
        end loop;
        wr_en <= '0';
        wait for 1 ns;
        for i in 1 to 3 loop
          check_equal(dout, octet(i));
          rd_en <= '1';
          wait until rising_edge(clk);
          rd_en <= '0';
          wait for 1 ns;
        end loop;
        check_equal(empty, '1');

      elsif run("pleine apres 16 ecritures") then
        for i in 1 to 16 loop
          din <= octet(i); wr_en <= '1';
          wait until rising_edge(clk);
        end loop;
        wr_en <= '0';
        wait for 1 ns;
        check_equal(full, '1');
        check_equal(empty, '0');
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  test_runner_watchdog(runner, 10 us);
end architecture;
