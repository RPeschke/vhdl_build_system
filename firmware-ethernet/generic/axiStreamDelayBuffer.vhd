library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use work.xgen_axistream_32.all;
  use work.klm_scint_globals.all;

entity axiStreamDelayBuffer is
  generic(
    Depth : integer := 5
  );
  port (
    globals : globals_t := globals_t_null;

    data_in_m2s : in  axisStream_32_m2s := axisStream_32_m2s_null;
    data_in_s2m : out axisStream_32_s2m := axisStream_32_s2m_null;

    data_out_m2s : out  axisStream_32_m2s := axisStream_32_m2s_null;
    data_out_s2m : in   axisStream_32_s2m := axisStream_32_s2m_null

  );
end entity;

architecture rtl of axiStreamDelayBuffer is
  signal i_buff_m2s :  axisStream_32_m2s_a(Depth downto 0) := (others => axisStream_32_m2s_null);
  signal i_buff_s2m :  axisStream_32_s2m_a(Depth downto 0) := (others => axisStream_32_s2m_null);

begin
  i_buff_m2s(0) <= data_in_m2s;
  data_in_s2m<= i_buff_s2m(0);


  data_out_m2s       <= i_buff_m2s(Depth);
  i_buff_s2m(Depth)  <= data_out_s2m;

  gen_buff : 
  for I in 0 to Depth -1 generate
    process(globals.clk) is 
      variable axRX :  axisStream_32_slave := axisStream_32_slave_null;
      variable axTX :  axisStream_32_master:= axisStream_32_master_null;
      variable buff :  STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    begin
      if rising_edge(globals.clk) then 
        pull(axRX , i_buff_m2s(I));
        pull(axTX , i_buff_s2m(I+1));

        if isReceivingData(axRX) and ready_to_send(axTX) then

          read_data(axRX,buff);
          send_data(axTX, buff);
          Send_end_Of_Stream(axTX , IsEndOfStream(axRX));
        end if;

        push(axTX , i_buff_m2s(I+1));
        push(axRX , i_buff_s2m(I));
      end if;
    end process;
  end generate gen_buff;

end architecture;