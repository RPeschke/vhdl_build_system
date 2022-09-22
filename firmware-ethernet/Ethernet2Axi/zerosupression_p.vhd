library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

package zerosupression_p is
  type zerosupression is record  
  array_index : STD_LOGIC_VECTOR(15 downto 0);  
  time_index  : STD_LOGIC_VECTOR(15 downto 0); 
  data        : std_logic_vector(31 downto 0); 

end record;

constant zerosupression_null : zerosupression:= (
  array_index=> (others => '0'),
  time_index  => (others => '0'),
  data  => (others  => '0')
);
end package;

package body zerosupression_p is
end package body;