import argparse
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
#sys.path.insert(0,parentdir) 

print("vhdl_make_test_bench", currentdir)

from  vhdl_build_system.vhdl_get_dependencies      import *
from  vhdl_build_system.vhdl_parser                import *
from  vhdl_build_system.vhdl_get_entity_def        import *
from  vhdl_build_system.vhdl_get_type_def_from_db  import *
from  vhdl_build_system.vhdl_make_stand_alone_impl import *
from  vhdl_build_system.vhdl_db                    import *
from  vhdl_build_system.vhdl_make_test_bench_names import *



knownName= list()

def writeFile(FileName,Content):
    with open(FileName,'w',newline= "") as f:
        f.write(Content)

def expand_types_records(portDef,TypeDef):
    ret = list()
    for x in TypeDef['record']:
        e = {}
        e['name'] = portDef['name'] + "." + x['name']
        e['type'] = x['type'] 
        e['InOut'] =  'in'
        e['default'] =  None
        ret.append(e)


    return ret

def input_get_constant(numStr):
    try:
        i0 = int(numStr)
    except:
        for x in knownName:
            if x["name"] == numStr.strip():
                i0 = x["value"]
                return i0


        i0 = input("unkown Variable: "+ numStr+"\nplease enter its value:")
        i0 =input_get_constant(i0)
        newName = {}
        newName["name"] = numStr.strip()
        newName["value"] = i0
        knownName.append(newName)

    return i0


def expand_types_arrays(portDef,TypeDef):
    ret = list()
    array_length = TypeDef["array_length"]
    sp = array_length.split("downto")
    if len(sp) == 1:
         sp = array_length.split("to")
    
    i0 = input_get_constant(sp[0])
    i1 = input_get_constant(sp[1])
    
    max_index = max(i0,i1)

    min_index = min(i0,i1)

    
    for x in range(min_index,max_index):
        e = {}
        e['name'] = portDef['name'] + "(" + str(x) +")"
        
        e['type'] = TypeDef['BaseType']
        e['InOut'] =  'in'
        e['default'] =  None
        ret.append(e)
    return ret






def make_package_file(entityDef,inOutFilter,suffix,PackagesUsed,path="."):
    et_name = entityDef.name()
    write_pgk_file = path+"/"+et_name +"_" + suffix +"_pgk.vhd"
    
    if suffix == "write":
        write_pgk = get_writer_pgk_name(entityDef)
        write_record = get_writer_record_name(entityDef)
    else :
        write_pgk = get_reader_pgk_name(entityDef)
        write_record =get_reader_record_name(entityDef)
    
    userPackages = ""
    for package in PackagesUsed:
            userPackages += "use work." + package + ".all;\n"
    
    ports = entityDef.ports(Filter= lambda a : a["InOut"] != inOutFilter, RemoveClock = True)

    RecordMember = ""
    defaultsstr = ""
    start = "    "    
    for x in ports:
        RecordMember += "    " + x["name"] + " : "+ x["type"] +  ";  \n"
        defaultsstr += start + x["name"] + " => "+  x["default"]
        start = ",\n    "

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

  type {write_record} is record
{RecordMember}
  end record;

  constant {write_record}_null : {write_record} := ( 
{defaultsstr}
  );

end {write_pgk};

package body {write_pgk} is

end package body {write_pgk};

    '''.format(
        userPackages=userPackages,
        write_pgk=write_pgk,
        write_record=write_record,
        RecordMember=RecordMember,
        defaultsstr=defaultsstr
    )

    writeFile(write_pgk_file,write_pgk_str)

        

    return write_pgk



def make_read_entity(entityDef,path="."):
    suffix = "reader"
    inOut = "out"
    et_name = entityDef.name()
    reader_entity_file = path+"/"+et_name +"_" + suffix +"_entity.vhd"
    reader_entity = get_reader_entity_name(entityDef)
    reader_pgk = get_reader_pgk_name(entityDef)
    
    ports = entityDef.ports(Filter= lambda a : a["InOut"] == "in", RemoveClock = True, ExpandTypes = True)
    
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
  signal    csv_r_data : c_integer_array(NUM_COL downto 0)  := (others=>0)  ;
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
    '''.format(
    et_name=et_name,
    includes=get_includes(),
    reader_pgk=reader_pgk,
    reader_entity=reader_entity,
    reader_record_name=get_reader_record_name(entityDef),
    connections=connections,
    NUM_COL=str(len(ports))
    )
    

    writeFile(reader_entity_file, reader_entity_str)

   

def make_write_entity(entityDef,path="."):
    inOut = "in"
    suffix = "writer"
    
    et_name = entityDef.name()
    write_entity_file = path+"/"+et_name +"_" + suffix +"_entity.vhd"
    write_entity = get_writer_entity_name(entityDef)
    write_pgk = get_writer_pgk_name(entityDef)

    ports = entityDef.ports(RemoveClock = True, ExpandTypes = True)


    HeaderLines=""
    start = ""
    for x in ports:
            
        HeaderLines += start + x["plainName"]
        start="; "

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
  signal data_int   : c_integer_array(NUM_COL downto 0)  := (others=>0);
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

    writeFile(write_entity_file, writer_entity_str)
    

        

        
def get_test_bench_file_basename(entityDef):
    et_name = entityDef.name()
    tb_entity =  et_name +"_tb_csv"     
    return tb_entity


def make_test_bench_for_test_cases(entityDef,path="."):
    et_name = entityDef.name()
    tb_entity_file = path+"/"+et_name +"_tb_csv.vhd"
    tb_entity = get_test_bench_file_basename(entityDef)
    write_pgk = get_writer_pgk_name(entityDef)
    reader_pgk = get_reader_pgk_name(entityDef)

    ports = entityDef.ports(Filter= lambda a : a["InOut"] == "in", RemoveClock = True)
 
    input2OutputConnection = ""
    for x in ports:
        input2OutputConnection +=  'data_out.' + x['name'] + " <= data_in." + x['name'] +";\n"

    
    ports = entityDef.ports(RemoveClock = True)
    portsstr =""
    start ="  "
    for x in ports:
        portsstr += start + x["name"] +" => data_out." + x["name"] 
        start = ",\n  "

    testBenchStr = '''
{includes}
use work.{write_pgk}.all;
use work.{reader_pgk}.all;
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
    clk => clk,
    {ports}
    );

end behavior;
    '''.format(
  includes=get_includes(),
  write_pgk=write_pgk,
  reader_pgk=reader_pgk,
  tb_entity=tb_entity,
  et_name=et_name,
  readerRecordName=get_reader_record_name(entityDef),
  writerRecordName=get_writer_record_name(entityDef),
  reader_entity_name=get_reader_entity_name(entityDef),
  writer_entity_name= get_writer_entity_name(entityDef),
  input2OutputConnection=input2OutputConnection,
  ports=portsstr
    )

    writeFile(tb_entity_file, testBenchStr)




def make_sim_csv_file(entityDef,FileName,FilterOut,NrOfEntires=1000):
    et_name = entityDef.name()
       
    ports = entityDef.ports(Filter= lambda a : a["InOut"] != FilterOut, RemoveClock = True,ExpandTypes =True)
    
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
    testCaseXml='''
<?xml version="1.0"?>
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
    </testcase>
</testcases>
    '''.format(
        et_name= et_name,
        sim_in_filename=get_test_bench_file_basename(entityDef)+".csv",
        sim_out_filename=get_test_bench_file_basename(entityDef)+"_out.csv",

    )

    writeFile(testCaseName, testCaseXml)



        