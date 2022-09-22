library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



package Imp_test_bench_pgk is
    constant Imp_test_bench_reader_Control_t_length : integer := 5;
    type Imp_test_bench_reader_Control_t is record 
        timestampRec         : std_logic_vector(31 downto 0);
        timestampSend        : std_logic_vector(31 downto 0);
        maxPacketNr          : std_logic_vector(31 downto 0);
        numStream            : std_logic_vector(31 downto 0);
        Operation            : std_logic_vector(31 downto 0);
    end record;

    constant Imp_test_bench_reader_Control_t_null : Imp_test_bench_reader_Control_t := ( 
        timestampRec       =>  (others => '0'),
        timestampSend      =>  (others => '0'),
        maxPacketNr        =>  (others => '0'),
        numStream          =>  (others => '0'),
        Operation          =>  (others => '0')
    );
      
end Imp_test_bench_pgk;

package body Imp_test_bench_pgk is

end package body Imp_test_bench_pgk;