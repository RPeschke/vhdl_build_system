library ieee;
  use ieee.std_logic_1164.all;


  use work.CSV_UtilityPkg.all;
  use STD.textio.all;
  use work.text_io_import_csv.all;


entity csv_read_file is
  generic (
    FileName : string := "read_file_ex.txt";
    NUM_COL : integer := 3;
    HeaderLines :integer :=1;
    Delay : time := 2 ns ;
    t_step : time := 1 ns;
    useExternalClk : boolean := false
  );
  port(
    clk : in STD_LOGIC;
    
    Rows : out c_integer_array(NUM_COL -1 downto 0) := (others => 0);

    Index : out integer := 0;
    eof : out STD_LOGIC := '0'
  ); 
end csv_read_file;

architecture Behavioral of csv_read_file is

begin
  noClk  : if useExternalClk = false generate 
    seq : process  is
      file input_buf : text;  -- text is keyword

      variable csv : csv_file;
      variable isEnd : boolean := False;
      variable  timeCounter: integer := 0;
      variable time_hasPassed: boolean := false;
    begin

      if not csv_isOpen(csv) and not isEnd then
        csv_openFile(csv,input_buf, FileName, HeaderLines, NUM_COL - 1);
      end if;

      while (not isEnd) loop
        if not endfile(input_buf) then 
          csv_readLine(csv,input_buf);
          time_hasPassed := false;


          while(not time_hasPassed) loop
            wait for t_step;
            timeCounter := timeCounter + 1;
            if timeCounter > csv_get(csv, 0)  then
              time_hasPassed := true;
            end if;
          end loop;

          for i in 0 to NUM_COL -1  loop
            Rows(i) <= csv_get(csv, i)  ;
          end loop;
          Index <= csv_getIndex(csv);
        else 
          csv_close(csv,input_buf);
          isEnd := True;
          eof <= '1';
        end if;
      end loop;     
      while (TRUE) loop
        wait for 100 ns;
      end loop;
    end process seq;

  end generate noClk;
  
    useClk  : if useExternalClk = true generate 
      seq1 : process(clk)  is
        file input_buf : text;  -- text is keyword

        variable csv : csv_file;
        variable isEnd : boolean := False;


      begin
        if(falling_edge(clk)) then
        if not csv_isOpen(csv) and not isEnd then
          csv_openFile(csv,input_buf, FileName, HeaderLines, NUM_COL -1);
        end if;

        
          if not endfile(input_buf) then 
            csv_readLine(csv,input_buf);
   
            for i in 0 to NUM_COL -1 loop
              Rows(i) <= csv_get(csv, i)  ;
            end loop;
            Index <= csv_getIndex(csv);
          else 
            csv_close(csv,input_buf);
            isEnd := True;
            eof <='1';
          end if;
       

        
      end if;
      end process seq1;
      
     end generate useClk;   
end Behavioral;


