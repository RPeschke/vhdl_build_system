library ieee;
  use ieee.std_logic_1164.all;
  use IEEE.NUMERIC_STD.all;



entity  ClockGenerator is 
  generic(
    CLOCK_period : time := 16 ns
  );
  port(
    clk : out STD_LOGIC := '0'
  );
end ClockGenerator;


architecture Behavioral of ClockGenerator is
begin


FPGA_LOGIC_CLOCK_process :process
begin
  clk <= '0';
  wait for CLOCK_period/2;
  clk <= '1';
  wait for CLOCK_period/2;
end process;

end Behavioral;