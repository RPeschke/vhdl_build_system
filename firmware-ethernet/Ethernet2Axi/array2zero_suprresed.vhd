library ieee;
library IEEE;
library UNISIM;
  use IEEE.numeric_std.all;
  use IEEE.std_logic_1164.all;
  use UNISIM.VComponents.all;
  use ieee.std_logic_unsigned.all;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

use work.UtilityPkg.all;
use work.axiDWORDbi_p.all;

use work.type_conversions_pgk.all;

use work.Imp_test_bench_pgk.all;

use work.xgen_axiStream_zerosupression.all;
use work.type_conversions_pgk.all;
use work.xgen_rollingCounter.all;
use work.zerosupression_p.all;

entity array2zero_suprresed is
  generic(
    COLNum : integer := 10;
    MaxChanges  : integer := 3
  );
  port (
    clk: in  std_logic;
    rst: in  std_logic;
    data_in  : in Word32Array(COLNum - 1 downto 0) := (others => (others => '0'));
    valid    : in std_logic;
    ToManyChangesError : out std_logic;
    zs_data_out_m2s : out axisStream_zerosupression_m2s_a(MaxChanges - 1 downto 0) := (others =>axisStream_zerosupression_m2s_null);
    zs_data_out_s2m : in  axisStream_zerosupression_s2m_a(MaxChanges - 1 downto 0) := (others =>axisStream_zerosupression_s2m_null);
    max_packet_nr : out slv(15 downto 0) := (others => '0')
  );
end entity;

architecture rtl of array2zero_suprresed is
  signal i_data_in_old  :  Word32Array(COLNum - 1 downto 0) := (others => (others => '0'));

begin



  Fill_FIFO_p : process (Clk) is
    variable  v_fifo_counter : rollingCounter := rollingCounter_null;

    variable packet_nr : slv(15 downto 0) := (others => '0');
    variable  TX : axisStream_zerosupression_master_a(MaxChanges -1 downto 0) := (others => axisStream_zerosupression_master_null);
    variable  buff : zerosupression:= zerosupression_null;

  begin
    if (rising_edge(Clk)) then
      ToManyChangesError <= '0';
    
     pull(TX,zs_data_out_s2m);
     

      if rst = '1' then
        reset(v_fifo_counter);
        packet_nr := (others => '0');
      elsif valid = '1' then
        i_data_in_old <= data_in;
        packet_nr := packet_nr +1;


          buff.array_index:= (others => '0');
          for i in 0 to i_data_in_old'length -1  loop
            if ready_to_send(TX(v_fifo_counter.Counter))  and  i_data_in_old(i) /= data_in(i) then 
              
              buff.time_index := packet_nr;
              buff.data := data_in(i);


              send_data(TX(v_fifo_counter.Counter), buff);
              incr(v_fifo_counter,  MaxChanges);
              
            elsif not ready_to_send(TX(v_fifo_counter.Counter))  and  i_data_in_old(i) /= data_in(i)  then 
              -- fifo full
              ToManyChangesError<= '1';
              reset(v_fifo_counter);
              packet_nr := (others => '0');
            end if;
            buff.array_index := buff.array_index +1;
          end loop;
        end if;





       
       push(tx,zs_data_out_m2s);
       max_packet_nr <= packet_nr;
      end if;
    end process;
  end architecture;