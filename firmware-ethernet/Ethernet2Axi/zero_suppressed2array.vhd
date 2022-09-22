
library IEEE;
  use IEEE.STD_LOGIC_1164.all;

  use ieee.std_logic_unsigned.all;


  use ieee.numeric_std.all;



-- Start Include user packages --
  use work.utilitypkg.all;
  use work.axidwordbi_p.all;
  use work.type_conversions_pgk.all;
  use work.imp_test_bench_pgk.all;
  use work.xgen_axistream_zerosupression.all;
  use work.xgen_rollingcounter.all;
  use work.zerosupression_p.all;


entity zero_suppressed2array is
  generic(
    COLNum : integer := 10;
    MaxChanges  : integer := 3
  );
  port (
    clk: in  std_logic;
    rst: in  std_logic;
    zs_data_out_m2s : in   axisStream_zerosupression_m2s_a(MaxChanges - 1 downto 0) := (others =>axisStream_zerosupression_m2s_null);
    zs_data_out_s2m : out  axisStream_zerosupression_s2m_a(MaxChanges - 1 downto 0) := (others =>axisStream_zerosupression_s2m_null);
    ToManyChangesError : out std_logic;
    data_out  : out  Word32Array(COLNum - 1 downto 0) := (others => (others => '0'));
    valid    : out  std_logic := '0';
    ready_out : in std_logic;
    max_packet_nr : in slv(15 downto 0) := (others => '0')
  );
end entity;

architecture rtl of zero_suppressed2array is

  signal i_valid : std_logic := '0';
begin
  valid <= i_valid;
  process(clk) is
    variable  RX : axisStream_zerosupression_slave_a(MaxChanges -1 downto 0) := (others => axisStream_zerosupression_slave_null);
    variable  v_fifo_counter : rollingCounter := rollingCounter_null;
    variable  buff : zerosupression:= zerosupression_null;
    variable packet_nr : slv(15 downto 0) := (others => '0');
    variable index : integer := 0;
    variable running : boolean := false;
  begin 
    if rising_edge(clk) then 

      pull(RX,zs_data_out_m2s);

      ToManyChangesError<='0';

      if rst = '1' then
        reset(v_fifo_counter);
        packet_nr:=(others => '0');
        data_out<=(others => (others => '0'));
		    running := False;
        i_valid <= '0';			
      elsif  (i_valid = '1' and ready_out = '1') or packet_nr = 0 then 
     -- else
        for i in 0 to MaxChanges - 1 loop
          if isReceivingData(RX(v_fifo_counter.Counter)) then 
            observe_data(RX(v_fifo_counter.Counter), buff);

            if buff.time_index = packet_nr then 
              read_data(RX(v_fifo_counter.Counter),buff);
              index := to_integer(unsigned(buff.array_index));

              data_out(index) <= buff.data;
              i_valid <= '1';
              running := True;
            elsif buff.time_index > packet_nr then 
              running := True;
              i_valid <= '1';
              exit;
            else 
              ToManyChangesError<='1';
            end if;

            incr(v_fifo_counter,MaxChanges);

          end if;

        end loop;
        if running then 
          packet_nr := packet_nr+1;
          if packet_nr > max_packet_nr then 
            reset(v_fifo_counter);
            packet_nr:=(others => '0');
            data_out<=(others => (others => '0'));
            running := False;
            i_valid <= '0';    
          end if;
        end if;
      end if;
      
      push(RX,zs_data_out_s2m);
      
    end if;
  end process;

end architecture;