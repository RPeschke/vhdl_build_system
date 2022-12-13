library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.axi_stream_s32.all;

entity axi4stream_example is

  port (
    clk :std_logic;
    rx_m2s : in axi_stream_32_m2s;
    rx_s2m : out axi_stream_32_s2m;

    tx_m2s : out axi_stream_32_m2s;
    tx_s2m : in axi_stream_32_s2m
  );
end entity;


architecture rtl of axi4stream_example is
  signal tx: axi_stream_32_master:= axi_stream_32_master_null;
  signal rx: axi_stream_32_slave:= axi_stream_32_slave_null;
begin

    tx_m2s<= tx.m2s;
    tx.s2m <= tx_s2m;

    rx.m2s <= rx_m2s;
    rx_s2m <= rx.s2m;

process(clk) is 
    variable buff: std_logic_vector(31 downto 0 ) := (others =>'0');
begin 

if rising_edge(clk) then 
    pull(tx);
    pull(rx);

    if isReceivingData(rx) and ready_to_send(tx) then 
        read_data(rx, buff);
        send_data(tx , buff);
        if IsEndOfStream(rx) then
            Send_end_Of_Stream(tx);
        end if;

    end if;


end if;

end process;
end architecture;