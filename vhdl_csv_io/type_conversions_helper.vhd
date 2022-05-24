library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package type_conversions_pgk is

procedure sl_to_slv(signal SL_in : in STD_LOGIC ; signal SLV_out : out STD_LOGIC_VECTOR) ;
procedure slv_to_slv(signal SLV_in : in STD_LOGIC_VECTOR ; signal SLV_out : out STD_LOGIC_VECTOR) ;
procedure slv_to_sl(signal  SLV_in : in STD_LOGIC_VECTOR ; signal SLV_out : out STD_LOGIC) ;

  

procedure integer_to_sl(signal I_in : in integer; signal SL_out : out STD_LOGIC);
procedure integer_to_slv(signal I_in : in integer; signal SLV_out : out STD_LOGIC_VECTOR);                                                                        
procedure integer_to_slv_var(signal I_in : in integer; SLV_out : out STD_LOGIC_VECTOR);   

procedure integer_to_integer(signal I_in : in integer; signal Int_out : out integer);      
procedure integer_to_natural(signal I_in : in integer; signal Natural_out : out natural);

procedure sl_to_integer(signal SL_in : in STD_LOGIC ; signal Int_out : out integer) ;

  procedure slv_to_integer(signal SLV_in : in STD_LOGIC_VECTOR ; signal Int_out : out integer);
  
  procedure natural_to_integer(signal Nat_in :in natural ; signal int_out :out integer);



  procedure csv_from_integer(signal I_in : in integer; signal SL_out : out STD_LOGIC);
  procedure csv_from_integer(signal I_in : in integer; signal SLV_out : out STD_LOGIC_VECTOR);                                                                        
  

  procedure csv_from_integer(signal I_in : in integer; signal Int_out : out integer);      
  
  

  procedure csv_to_integer(signal SL_in : in STD_LOGIC ; signal Int_out : out integer) ;

  procedure csv_to_integer(signal SLV_in : in STD_LOGIC_VECTOR ; signal Int_out : out integer);
  
  procedure csv_to_integer(signal I_in :in integer ; signal int_out :out integer) ;
end type_conversions_pgk;

package body type_conversions_pgk is
   

  
  procedure sl_to_slv(signal SL_in : in STD_LOGIC ; signal SLV_out : out STD_LOGIC_VECTOR) is begin 
  SLV_out(0) <= SL_in;
  end procedure;
  
  procedure slv_to_slv(signal SLV_in : in STD_LOGIC_VECTOR ; signal SLV_out : out STD_LOGIC_VECTOR) is 
  variable m1 : integer := 0;
  variable m2 : integer := 0;
  variable m : integer := 0;
  begin 
  m1 := SLV_out'length;
  m2 := SLV_in'length;
  
  if (m1 < m2) then 
   m := m1;
  else 
   m := m2;
  end if;

  SLV_out(   m - 1 downto 0) <= SLV_in(  m - 1 downto 0);
  
  end procedure;
  
 procedure slv_to_sl(signal  SLV_in : in STD_LOGIC_VECTOR ; signal SLV_out : out STD_LOGIC) is begin 
	SLV_out <= SLV_in(0);
end procedure; 
procedure natural_to_integer(signal Nat_in :in natural ; signal int_out :out integer) is begin 
  
  int_out <= Nat_in;
end procedure;


  procedure slv_to_integer(signal SLV_in : in STD_LOGIC_VECTOR ; signal Int_out : out integer) is begin
   
    
    for i in SLV_in'low to SLV_in'high loop
       if  not ( SLV_in(i) = '1' or SLV_in(i) = '0') then 
         Int_out <= -1;
         return;
       end if;
    end loop;
    
    Int_out <= to_integer(signed(SLV_in));
  end procedure;

  procedure sl_to_integer(signal SL_in : in STD_LOGIC ; signal Int_out : out integer) is begin
    if (SL_in = '1') then 
      Int_out <=1;
    elsif (SL_in = '0') then 
      Int_out <=0;
    else 
      Int_out <= -1;
    end if;

  end procedure;
  
  
  procedure integer_to_integer(signal I_in : in integer; signal Int_out : out integer) is begin

    Int_out<= I_in;
  end procedure;
  procedure integer_to_sl(signal I_in : in integer; signal SL_out : out STD_LOGIC) is begin 
    if (I_in>0) then 
      SL_out <= '1';
    else 
      SL_out <= '0';
    end if;

  end procedure;

  procedure integer_to_slv(signal I_in : in integer; signal SLV_out : out STD_LOGIC_VECTOR) is 
  variable temp : std_logic_vector(127 downto 0);
  begin
    temp:= std_logic_vector(to_signed(I_in, temp'length));
    SLV_out<= temp(SLV_out'range);
  end procedure;

  procedure integer_to_slv_var(signal I_in : in integer; SLV_out : out STD_LOGIC_VECTOR) is begin
    SLV_out:= std_logic_vector(to_signed(I_in, SLV_out'length));

  end procedure;
  
  procedure integer_to_natural(signal I_in : in integer; signal Natural_out : out natural) is 
    variable I_in_buffer1 : STD_LOGIC_VECTOR(31 downto 0);
    variable I_in_buffer2 : natural:=0;

  begin
    integer_to_slv_var(I_in ,I_in_buffer1);

    I_in_buffer2  :=  to_integer(signed(I_in_buffer1));
    Natural_out <=  I_in_buffer2 ;

  end procedure;






  procedure csv_from_integer(signal I_in : in integer; signal SL_out : out STD_LOGIC) is begin 
    integer_to_sl(I_in, SL_out);
  end procedure;


  procedure csv_from_integer(signal I_in : in integer; signal SLV_out : out STD_LOGIC_VECTOR)is begin
    integer_to_slv(I_in, SLV_out);
  end procedure;                                                                        


  procedure csv_from_integer(signal I_in : in integer; signal Int_out : out integer)  is begin
    integer_to_integer(I_in, Int_out);
  end procedure;



  procedure csv_to_integer(signal SL_in : in STD_LOGIC ; signal Int_out : out integer) is begin 
    sl_to_integer(SL_in, Int_out);
  end procedure;

  procedure csv_to_integer(signal SLV_in : in STD_LOGIC_VECTOR ; signal Int_out : out integer) is begin 
    slv_to_integer(SLV_in, Int_out);
  end procedure;
  
  procedure csv_to_integer(signal I_in :in integer ; signal int_out :out integer) is begin 
    integer_to_integer(I_in, Int_out);
  end procedure;
  
end package body type_conversions_pgk;
