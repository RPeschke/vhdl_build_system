--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
  use work.CSV_UtilityPkg.all;
  use STD.textio.all;
  
package text_io_import_csv is

constant NUM_COL : integer := 60;
	
type csv_file is record
	 data_vecotor_buffer  : c_integer_array(NUM_COL downto 0);
	 lineBuffer : line ;
	 Index : integer ;
   IsOpen : STD_LOGIC;
   columns: integer;
 end record;
 
 --constant csv_default : csv_file :=(data_vecotor_buffer => (others =>0),lineBuffer => "", Index => 0,IsOpen =>'0');

function csv_get  (csv  : in csv_file; RowIndex  : in integer) return integer;
function csv_getIndex(csv:in csv_file) return integer;
function csv_isOpen(csv: in csv_file) return boolean;


procedure csv_reset(csv: inout csv_file); 
procedure csv_close( csv : inout csv_file; file F: Text);

procedure csv_openFile(variable csv : inout csv_file ; file F: Text; FileName :  string;  HeaderLines : integer; NumOfcolumns : integer := NUM_COL);

procedure csv_readLine (variable csv  : inout csv_file; file F: TEXT);

procedure csv_skipHeader(variable csv: inout csv_file; file F:text ; headerLines: in integer);

end text_io_import_csv;

package body text_io_import_csv is

function csv_get(csv  : in csv_file; RowIndex  : in integer) return integer is begin
return csv.data_vecotor_buffer(RowIndex);
end csv_get;
 
procedure csv_readLine (variable csv  : inout csv_file; file F: TEXT) is begin
	readline(F, csv.lineBuffer);
	for i in 0 to csv.columns loop
		read(csv.lineBuffer,csv.data_vecotor_buffer(i));
	end loop;
	csv.Index := csv.Index +1;
end csv_readLine;


procedure csv_skipHeader(variable csv: inout csv_file; file F:text ; headerLines: in integer) is begin
  
  for i in 1 to headerLines loop
    readline(F, csv.lineBuffer);
  end loop;
  csv.Index:=0;
end csv_skipHeader;

function csv_getIndex(csv:in csv_file) return integer is begin 
  return csv.Index;
  
end csv_getIndex;

function csv_isOpen(csv: in csv_file) return boolean is begin
  return csv.IsOpen ='1';
end csv_isOpen;

procedure csv_openFile(variable csv : inout csv_file ; file F: Text; FileName :  string;  HeaderLines : integer; NumOfcolumns : integer := NUM_COL) is begin
  csv_reset(csv);
  csv.columns := NumOfcolumns;
  file_open(F, FileName,  read_mode); 
  csv_skipHeader(csv,F,HeaderLines);
  csv.IsOpen := '1';
end csv_openFile;


procedure csv_close( csv : inout csv_file; file F: Text) is begin
  if not csv_isOpen(csv) then 
    return;
  end if ;
  
  file_close(F);
  csv_reset(csv);
end csv_close;

procedure csv_reset(csv: inout csv_file) is begin
  csv.data_vecotor_buffer := (others => 0);
  csv.Index := 0;
  csv.IsOpen := '0';
  csv.columns := NUM_COL;
end csv_reset;
end text_io_import_csv;
