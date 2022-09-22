library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fifo_base_pkg is

  subtype  fifo_error_states_t is STD_LOGIC_VECTOR(31 downto 0);

  constant fifo_error_states_t_null : fifo_error_states_t := (others =>  '0');
  constant fifo_not_reading_data :         fifo_error_states_t := "00000000000000000000000000000001";
  constant fifo_not_writing_before_ready : fifo_error_states_t := "00000000000000000000000000000010";
  
  
end package fifo_base_pkg;