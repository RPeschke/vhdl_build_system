library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.numeric_std.all;

  use work.CSV_UtilityPkg.all;
  
  use work.axiDWORDbi_p.all;
  use work.fifo_cc_pgk_32.all;
  use work.type_conversions_pgk.all;
  use work.axi_stream_pgk_32.all;
  use work.Imp_test_bench_pgk.all;

entity axiStreamThrottle is
    generic (
        max_counter : integer  := 100;
        wait_time : integer := 100
    );
    port (
        clk             : in   std_logic;

        rxData          : in   std_logic_vector(31 downto 0) := (others => '0');
        rxDataValid     : in   std_logic := '0';
        rxDataLast      : in   std_logic := '0';
        rxDataReady     : out  std_logic := '0';

        tXData          : out  std_logic_vector(31 downto 0) := (others => '0');
        txDataValid     : out  std_logic := '0';
        txDataLast      : out  std_logic := '0';
        txDataReady     : in   std_logic := '0'
    );
end entity axiStreamThrottle;

architecture rtl of axiStreamThrottle is
   



    signal axi_in_m2s    : axi_stream_32_m2s := axi_stream_32_m2s_null;
    signal axi_in_s2m    : axi_stream_32_s2m := axi_stream_32_s2m_null;

    signal  i_fifo_out_m2s :  axi_stream_32_m2s := axi_stream_32_m2s_null;
    signal  i_fifo_out_s2m :  axi_stream_32_s2m := axi_stream_32_s2m_null;
    signal  i_waiting      :  boolean           := false;
begin
    axi_in_m2s.data <= rxData;
    axi_in_m2s.last <=rxDataLast;
    axi_in_m2s.valid <= rxDataValid;
    rxDataReady <= axi_in_s2m.ready;

    tXData <= i_fifo_out_m2s.data;
    txDataValid <= i_fifo_out_m2s.valid;
    txDataLast <= i_fifo_out_m2s.last;
    i_fifo_out_s2m.ready <= txDataReady;

    process(clk) is 
        variable axi_in        : axi_stream_32_slave_stream := axi_stream_32_slave_stream_null;
        variable rxbuffer      : slv(31 downto 0) := (others => '0');
        variable out_fifo      : axi_stream_32_master_stream := axi_stream_32_master_stream_null;
        variable  counter      : integer := 0;
    begin
        if (rising_edge(Clk)) then
            pull_axi_stream_32_slave_stream(axi_in, axi_in_m2s);
            pull_axi_stream_32_master_stream(out_fifo , i_fifo_out_s2m);
            if i_waiting = false then 
                if isReceivingData(axi_in) and ready_to_send(out_fifo) then 
                    read_data(axi_in,rxbuffer);
                    send_data(out_fifo, rxbuffer);
                    if IsEndOfStream(axi_in) then 
                        Send_end_Of_Stream(out_fifo);
                        counter := counter + 1;
                        
                    end if;
                end if;

                if counter > max_counter then 
                    i_waiting <= true;
                    counter := 0;
                end if;
            else 

                counter := counter + 1;
                if counter > wait_time then 
                    i_waiting <= false;
                    counter := 0;
                end if;
                
            end if;
            

            
            push_axi_stream_32_slave_stream(axi_in,axi_in_s2m);
            push_axi_stream_32_master_stream(out_fifo, i_fifo_out_m2s);
        end if;
    end process;
    
end architecture rtl;