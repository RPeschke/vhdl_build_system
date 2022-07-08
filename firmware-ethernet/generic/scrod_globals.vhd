library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use work.roling_register_p.all;


package klm_scint_globals is
  type globals_t is record 
    clk : std_logic;
    rst : std_logic;
    reg : registerT;
  end record;
  
  constant globals_t_null : globals_t := (
    clk   =>  '0',
    rst   =>  '0',
    reg   =>  registerT_null
  );


end package;
