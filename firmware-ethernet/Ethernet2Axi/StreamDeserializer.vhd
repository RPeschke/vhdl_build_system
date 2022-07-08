library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

use work.UtilityPkg.all;
use work.axiDWORDbi_p.all;
use work.fifo_cc_pgk_32.all;
use work.type_conversions_pgk.all;
use work.axi_stream_pgk_32.all;


entity StreamDeserializer is 
generic ( 
  COLNum : integer := 10
        
);
port(
Clk      : in  sl := '0';
-- Incoming data
rxData      : in  slv(31 downto 0) := (others => '0');
rxDataValid : in  sl := '0';
rxDataLast  : in  sl := '0';
rxDataReady : out sl := '0';
data_out    : out Word32Array(COLNum - 1 downto 0) := (others => (others => '0'));
valid       : out sl := '0'
);
end entity;

architecture rtl of StreamDeserializer is 
    type state_t is (
        idle,
        make_packet,
        early_stream_ending, 
        late_stream_ending,
        stream_end
    );
    signal i_state : state_t := idle;
    
    signal axi_in_m2s    : axi_stream_32_m2s := axi_stream_32_m2s_null;
    signal axi_in_s2m    : axi_stream_32_s2m := axi_stream_32_s2m_null;
    signal i_data_out    :  Word32Array(COLNum - 1 downto 0) := (others => (others => '0'));
begin
    axi_in_m2s.data <= rxData;
    axi_in_m2s.last <=rxDataLast;
    axi_in_m2s.valid <= rxDataValid;
    rxDataReady <= axi_in_s2m.ready;
    seq : process (Clk) is
        variable rxbuffer      : slv(31 downto 0) := (others => '0');
        variable axi_in : axi_stream_32_slave_stream := axi_stream_32_slave_stream_null;
        variable index : integer := 0;
    begin
        if (rising_edge(Clk)) then
            pull_axi_stream_32_slave_stream(axi_in, axi_in_m2s);
            valid <= '0';
            if i_state = idle then 
                data_out <= (others => (others => '0'));
                i_data_out<= (others => (others => '0'));
                if isReceivingData(axi_in)  then 
                    Index := 0;
                    i_state <= make_packet;
                end if;
            elsif i_state = make_packet then 
                if isReceivingData(axi_in)  then 
                    read_data(axi_in,rxbuffer);
                    i_data_out(index) <= rxbuffer;
                    Index := Index + 1;
                    
                    if IsEndOfStream(axi_in) and Index >= COLNum then
                        -- normal Stream ending
                        i_state <= stream_end;
                    elsif  Index >= COLNum then
                        -- late stream ebnding
                        i_state <=  late_stream_ending;
                    elsif  IsEndOfStream(axi_in) then
                        -- early stream ending
                        i_state <= early_stream_ending;
                    end if ;

                end if;
            elsif i_state = late_stream_ending then 
                  -- Flushing stream
                if isReceivingData(axi_in) then 
                    read_data(axi_in,rxbuffer);
                    if IsEndOfStream(axi_in) then 
                    i_state <= stream_end;
                    end if;
                end if;
            elsif i_state = early_stream_ending then
                i_data_out(Index) <=  (others => '0');
                Index := Index + 1;
                if  Index >= COLNum then
                    i_state <= stream_end;
          
                end if ;
            elsif i_state = stream_end then
                data_out <= i_data_out;
                valid<='1';
                i_state <= idle;

            end if;

            push_axi_stream_32_slave_stream(axi_in,axi_in_s2m);
        end if;
    end process seq;
            
end rtl;