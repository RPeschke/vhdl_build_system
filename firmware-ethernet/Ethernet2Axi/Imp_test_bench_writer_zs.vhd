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
  use work.Imp_test_bench_pgk.all;
  use work.xgen_axistream_32.all;

entity Imp_test_bench_writer_zs is 
  generic ( 
    COLNum : integer := 10;
    FIFO_DEPTH : integer := 10;
    MaxChanges  : integer := 10
  );
  port(
    Clk      : in  sl;
    -- Incoming data
    tXData      : out  slv(31 downto 0);
    txDataValid : out sl;
    txDataLast  : out  sl;
    txDataReady : in sl;
    data_in     : in Word32Array(COLNum -1 downto 0) := (others => (others => '0'));
    controls_in : in Imp_test_bench_reader_Control_t  := Imp_test_bench_reader_Control_t_null;
    Valid      : in sl
  );
end entity;

architecture Behavioral of Imp_test_bench_writer_zs is 
  constant BOS       : std_logic_vector(31 downto 0) := "00001111111111111111111111111111";
  constant FIFO_FULL  : std_logic_vector(31 downto 0) := "00000000111111111111111111110000";
  constant EOS       : std_logic_vector(31 downto 0) := "00001111111111111111111111111110";



  signal Nr_of_streams : std_logic_vector(31 downto 0) := (others => '0');

  signal i_ToManyChangesError_a2z : std_logic := '0';
  signal i_ToManyChangesError_z2a : std_logic :='0';

  signal rst: std_logic :='0';

  signal i_data_out       :  Word32Array((COLNum -1)+2 downto 0) := (others => (others => '0'));
  signal i_valid : std_logic := '0';
  signal i_ready : std_logic := '0';

  signal TX_m2s : axisStream_32_m2s := axisStream_32_m2s_null;
  signal TX_s2m : axisStream_32_s2m := axisStream_32_s2m_null;


begin
  sqe_out : process(clk) is
    variable TX : axisStream_32_master_with_counter :=axisStream_32_master_with_counter_null;
    variable Counter : integer := 0;

    variable  v_data_out       :  Word32Array((COLNum -1)+2 downto 0) := (others => (others => '0'));
    variable v_data_valid: std_logic :='0';
  begin
    pull(TX, TX_s2m);
    i_ready <= '0';

    if i_valid ='1' and i_ready ='1' then
      v_data_out := i_data_out;
      Counter := 0;
      v_data_valid :='1';
    end if; 

    if v_data_valid = '1' then
      send_data_at(TX,0, BOS);
      send_data_at(TX,1, Nr_of_streams);
      if ready_to_send(TX) then
        send_data_begining_at(TX,2, v_data_out(Counter));
        Counter := Counter +1 ;

        if Counter >= i_data_out'length  then
          i_ready <='1';
          v_data_valid := '0';
          Nr_of_streams <= Nr_of_streams+1;
          Send_end_Of_Stream(TX);
        end if;
      end if;
    end if;
    send_data_at(TX, -1, EOS);




    push(TX,TX_m2s);

  end process;

  zs_fifo :  entity  work.zero_supression_test_connection generic map(
    COLNum =>  COLNum + 2,
    MaxChanges => MaxChanges,
    DEPTH => FIFO_DEPTH
  ) port map (
    clk => clk,
    rst => rst,

    data_in    => data_in,
    valid_in   => Valid,
    ToManyChangesError_a2z => i_ToManyChangesError_a2z,

    data_out    => i_data_out,
    valid_out   => i_valid,
    ready_out   => i_ready,
    ToManyChangesError_z2a =>i_ToManyChangesError_z2a
  );
end architecture;