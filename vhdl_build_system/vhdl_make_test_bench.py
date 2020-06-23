import argparse
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
#sys.path.insert(0,parentdir) 



from  .vhdl_get_dependencies      import *
from  .vhdl_parser                import *
from  .vhdl_get_entity_def        import *
from  .vhdl_get_type_def_from_db  import *
from  .vhdl_make_stand_alone_impl import *
from  .vhdl_db                    import *
from  .vhdl_make_test_bench_names import *

from  .vhdl_entity2FileName       import *
from  .vhdl_entity_class          import *
from  .vhdl_merge_split_test_cases import *

def make_test_bench_main(EntityName,NumberOfRows,OutputPath):
      
    InputFile = entity2FileName(EntityName)
    NumberOfRows = int(NumberOfRows)
    entityDef = vhdl_get_entity_def(InputFile)
    entetyCl  =  vhdl_entity(entityDef[0])
    vhdl_get_dependencies_internal(EntityName)
    
    ParsedFile = vhdl_parser.vhdl_parser(InputFile)

    make_package_file(entetyCl, ParsedFile["packageUSE"], OutputPath)
    

    read_entity = make_read_entity(entetyCl)
    write_entity = make_write_entity(entetyCl)
    tb_entity,test_bench = make_test_bench_for_test_cases(entetyCl)
  
    writeFile(OutputPath+"/"+get_test_bench_file_basename(entetyCl)+".vhd" ,  read_entity+write_entity+test_bench) 

    sim_in_filename =  OutputPath+"/"+get_test_bench_file_basename(entetyCl)+".csv"
    
    make_sim_csv_file(entetyCl,sim_in_filename,"out",NrOfEntires=NumberOfRows)
    sim_out_filename =  OutputPath+"/"+get_test_bench_file_basename(entetyCl)+"_out.csv"
    make_sim_csv_file(entetyCl,sim_out_filename,"none",NrOfEntires=NumberOfRows)
    
    make_xml_test_case(entetyCl, OutputPath)



    make_stand_alone_impl( entityDef = entetyCl , path =  OutputPath, suffix= "")

    print("generated test bench file", tb_entity)
    


def writeFile(FileName,Content):
    with open(FileName,'w',newline= "") as f:
        f.write(Content)





def make_IO_record(entityDef,inOutFilter):
    if inOutFilter == "none":
        IO_record_name = get_writer_record_name(entityDef)
    else :
        IO_record_name =get_reader_record_name(entityDef)
    
    ports = entityDef.ports(Filter= lambda a : a["InOut"] != inOutFilter)

    RecordMember = ""
    defaultsstr = ""
    start = "    "    
    for x in ports:
        RecordMember += "    " + x["name"] + " : "+ x["type"] +  ";  \n"
        defaultsstr += start + x["name"] + " => "+  x["default"]
        start = ",\n    "

    IO_record = '''
  type {IO_record_name} is record
{RecordMember}
  end record;

  constant {IO_record_name}_null : {IO_record_name} := ( 
{defaultsstr}
  );
    '''.format(
        IO_record_name=IO_record_name,
        RecordMember=RecordMember,
        defaultsstr=defaultsstr
    )
    return IO_record

def make_package_file(entityDef,PackagesUsed,path="."):
    et_name = entityDef.name()
    write_pgk_file = path+"/"+et_name +"_IO_pgk.vhd"
    
   
    write_pgk = get_IO_pgk_name(entityDef)
    
    
    userPackages = ""
    for package in PackagesUsed:
            userPackages += "use work." + package + ".all;\n"
    
    records =""
    records += make_IO_record(entityDef,"none")
    records +="\n\n"
    records += make_IO_record(entityDef,"out")

    write_pgk_str = '''
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.CSV_UtilityPkg.all;


-- Start Include user packages --
{userPackages}
-- End Include user packages --

package {write_pgk} is

{records}
end {write_pgk};

package body {write_pgk} is

end package body {write_pgk};

    '''.format(
        userPackages=userPackages,
        write_pgk=write_pgk,
        records=records
    )

    writeFile(write_pgk_file,write_pgk_str)

        

    return write_pgk



def make_read_entity(entityDef):
    et_name = entityDef.name()
    reader_entity = get_reader_entity_name(entityDef)
    reader_pgk = get_IO_pgk_name(entityDef)
    
    ports = entityDef.ports(Filter= lambda a : a["InOut"] == "in",  ExpandTypes = True)
    
    connections=""
    index = 0
    for x in ports:
        connections += "  integer_to_" + x["type_shorthand"] + '(csv_r_data(' +str(index) +'), data.' + x["name"] + ');\n'
        index+=1 

    reader_entity_str = '''

{includes}

use work.{reader_pgk}.all;


entity {reader_entity}  is
    generic (
        FileName : string := "./{et_name}_in.csv"
    );
    port (
        clk : in std_logic ;
        data : out {reader_record_name}
    );
end entity;   

architecture Behavioral of {reader_entity} is 

  constant  NUM_COL    : integer := {NUM_COL};
  signal    csv_r_data : c_integer_array(NUM_COL -1 downto 0)  := (others=>0)  ;
begin

  csv_r :entity  work.csv_read_file 
    generic map (
        FileName =>  FileName, 
        NUM_COL => NUM_COL,
        useExternalClk=>true,
        HeaderLines =>  2
    ) port map (
        clk => clk,
        Rows => csv_r_data
    );

{connections}

end Behavioral;
---------------------------------------------------------------------------------------------------
    '''.format(
    et_name=et_name,
    includes=get_includes(),
    reader_pgk=reader_pgk,
    reader_entity=reader_entity,
    reader_record_name=get_reader_record_name(entityDef),
    connections=connections,
    NUM_COL=str(len(ports))
    )
    

    return reader_entity_str

   
def make_out_header(entityDef):
    ports = entityDef.ports( ExpandTypes = True)

    HeaderLines=""
    start = ""
    for x in ports:
            
        HeaderLines += start + x["plainName"]
        start="; "

    return HeaderLines


def make_write_entity(entityDef,path="."):
    
    et_name = entityDef.name()
    write_entity = get_writer_entity_name(entityDef)
    write_pgk = get_IO_pgk_name(entityDef)

    ports = entityDef.ports(ExpandTypes = True)


    HeaderLines = make_out_header(entityDef)


    connections=""
    index = 0
    for x in ports:
        connections += "  " + x["type_shorthand"] + '_to_integer(data.' + x["name"] + ', data_int(' +str(index) +') );\n'
        index+=1 

    writer_entity_str='''

{includes}

use work.{write_pgk}.all;

entity {write_entity}  is
    generic ( 
        FileName : string := "./{et_name}_out.csv"
    ); port (
        clk : in std_logic ;
        data : in {writer_record_name}
    );
end entity;

architecture Behavioral of {write_entity} is 
  constant  NUM_COL : integer := {NUM_COL};
  signal data_int   : c_integer_array(NUM_COL - 1 downto 0)  := (others=>0);
begin

    csv_w : entity  work.csv_write_file 
        generic map (
            FileName => FileName,
            HeaderLines=> "{HeaderLines}",
            NUM_COL =>   NUM_COL 
        ) port map(
            clk => clk, 
            Rows => data_int
        );


{connections}

end Behavioral;
---------------------------------------------------------------------------------------------------
    '''.format(
        et_name=et_name,
        includes=get_includes(),
        write_entity=write_entity,
        write_pgk=write_pgk,
        writer_record_name=get_writer_record_name(entityDef),
        HeaderLines=HeaderLines,
        connections=connections,
        NUM_COL=str(len(ports))
    )

    return writer_entity_str
    

        

        
def get_test_bench_file_basename(entityDef):
    et_name = entityDef.name()
    tb_entity =  et_name +"_tb_csv"     
    return tb_entity


def make_test_bench_for_test_cases(entityDef):
    et_name = entityDef.name()

    tb_entity = get_test_bench_file_basename(entityDef)
    write_pgk = get_IO_pgk_name(entityDef)


    ports = entityDef.ports(Filter= lambda a : a["InOut"] == "in", RemoveClock = True)
    clk_port = entityDef.get_clock_port()
    input2OutputConnection = ""
    if entityDef.IsUsingGlobals():
        input2OutputConnection ="""  data_out.{globals}.clk <=clk;
  data_out.{globals}.reg <= data_in.{globals}.reg;
  data_out.{globals}.rst <= data_in.{globals}.rst;
  """.format(
      globals = clk_port["name"]
  )
    ports = [x for x in ports if x["type"] != "globals_t"]
    for x in ports:
        input2OutputConnection +=  'data_out.' + x['name'] + " <= data_in." + x['name'] +";\n"

    
    ports = entityDef.ports(RemoveClock = True)
    
    portsstr = ""
    start =""
    if not entityDef.IsUsingGlobals():
        start = "\n  clk => clk,\n  "
    else:
        start = "\n  " + clk_port["name"] + " => data_out."+ clk_port["name"] +",\n  "

    for x in ports:
        portsstr += start + x["name"] +" => data_out." + x["name"] 
        start = ",\n  " 
        

    testBenchStr = '''
{includes}
use work.{write_pgk}.all;

entity {tb_entity} is 
end entity;

architecture behavior of {tb_entity} is 
  signal clk : std_logic := '0';
  signal data_in : {readerRecordName} := {readerRecordName}_null;
  signal data_out : {writerRecordName} := {writerRecordName}_null;

begin 

  clk_gen : entity work.ClockGenerator generic map ( CLOCK_period => 10 ns) port map ( clk => clk );

  csv_read : entity work.{reader_entity_name} 
    generic map (
        FileName => "./{tb_entity}.csv" 
    ) port map (
        clk => clk ,data => data_in
    );
 
  csv_write : entity work.{writer_entity_name}
    generic map (
        FileName => "./{tb_entity}_out.csv" 
    ) port map (
        clk => clk ,data => data_out
    );
  

{input2OutputConnection}

DUT :  entity work.{et_name}  port map(
{ports}
    );

end behavior;
---------------------------------------------------------------------------------------------------
    '''.format(
  includes=get_includes(),
  write_pgk=write_pgk,
  tb_entity=tb_entity,
  et_name=et_name,
  readerRecordName=get_reader_record_name(entityDef),
  writerRecordName=get_writer_record_name(entityDef),
  reader_entity_name=get_reader_entity_name(entityDef),
  writer_entity_name= get_writer_entity_name(entityDef),
  input2OutputConnection=input2OutputConnection,
  ports=portsstr
    )



    return tb_entity,testBenchStr




def make_sim_csv_file(entityDef,FileName,FilterOut,NrOfEntires=1000):
    et_name = entityDef.name()
       
    ports = entityDef.ports(Filter= lambda a : a["InOut"] != FilterOut, ExpandTypes =True)
    
    if FilterOut == "out":
        delimiter=", "
    else:
        delimiter="; "
    
    with open(FileName,"w",newline="") as f:
   
        if FilterOut == "out":
            start = ""
        else :
            start = "time  " + delimiter
            
        for x in ports:
            
            f.write(start + x["plainName"])
            start = delimiter
            
        f.write('\n')
        
        for i in range(NrOfEntires):
            

            if FilterOut == "out":
                start = ""
            else :
                start = str(i) + delimiter
                

            for x in ports:
                f.write(start + "0")
                start = delimiter
                
            f.write('\n')


def make_xml_test_case(entityDef,path):
    et_name = get_test_bench_file_basename(entityDef)
    testCaseName = path+"/"+get_test_bench_file_basename(entityDef)+".testcase.xml"
    testCaseXml='''<?xml version="1.0"?>
<testcases>
    <testcase name="{et_name}empty_test01">
        <descitption> autogenerated empty test case</descitption>
        <inputfile>{sim_in_filename}</inputfile>
        <referencefile>{sim_out_filename}</referencefile>
        <entityname>{et_name}</entityname>
        <tc_type>Unclear</tc_type>
        <difftool>diff</difftool>
        <RegionOfInterest>
            <Headers></Headers>
            <Lines></Lines>
        </RegionOfInterest>
        <Stimulus/>
        <Reference/>
    </testcase>
</testcases>
    '''.format(
        et_name= et_name,
        sim_in_filename=get_test_bench_file_basename(entityDef)+".csv",
        sim_out_filename=get_test_bench_file_basename(entityDef)+"_out.csv",

    )

    writeFile(testCaseName, testCaseXml)
    merge_test_case(testCaseName)

  



        