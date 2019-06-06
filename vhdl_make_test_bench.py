import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_parser import *
from  vhdl_build_system.vhdl_get_dependencies import *
from  vhdl_build_system.vhdl_get_entity_def import *
import argparse

from vhdl_build_system.vhdl_get_type_def_from_db import *

knownName= list()

def isPrimitiveType(typeName):
    if typeName == "std_logic":
        return True
    elif "std_logic_vector" in typeName:
        return True
    elif typeName == "integer":
        return True

    return False

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

def expand_types(ports):
    ret = list()
    for p in ports:
        if isPrimitiveType(p["type"]):
            ret.append(p)
        else:
            type_def = get_type_from_name(p["type"])
            
            if type_def == None:
                continue
            elif type_def["vhdl_type"] == "record":
                array = expand_types_records(p,type_def)
                for a in array:
                    ret.append(a)
            elif type_def["vhdl_type"] == "array":
                array = expand_types_arrays(p,type_def)
                for a in array:
                    ret.append(a)
                
                
    return ret

def get_shortend_typename(portdef):
   
    ty = portdef["type"]
    if ty == "std_logic":
        return "sl"
    elif "std_logic_vector" in ty:
        return "slv"
    
    return ty

def get_reader_entity_name(entityDef):
    et_name = entityDef[0]["name"]
    reader_entity = et_name +"_reader_et"
    return reader_entity

def get_writer_entity_name(entityDef):
    et_name = entityDef[0]["name"]
    reader_entity = et_name +"_writer_et"
    return reader_entity

def get_reader_pgk_name(entityDef):
    et_name = entityDef[0]["name"]

    pgk_name = et_name +"_reader_pgk"
    return pgk_name

def get_writer_pgk_name(entityDef):
    et_name = entityDef[0]["name"]

    pgk_name = et_name +"_writer_pgk"
    return pgk_name

def get_reader_record_name(entityDef):
    et_name = entityDef[0]["name"]
    record_name = et_name +"_reader_rec"
    return record_name

def get_writer_record_name(entityDef):
    et_name = entityDef[0]["name"]
    record_name = et_name +"_writer_rec"
    return record_name

def make_package_file(entityDef,inOutFilter,suffix,PackagesUsed,path="."):
    et_name = entityDef[0]["name"]
    write_pgk_file = path+"/"+et_name +"_" + suffix +"_pgk.vhd"
    
    if suffix == "write":
        write_pgk = get_writer_pgk_name(entityDef)
        write_record = get_writer_record_name(entityDef)
    else :
        write_pgk = get_reader_pgk_name(entityDef)
        write_record =get_reader_record_name(entityDef)

    
    with open(write_pgk_file,'w',newline= "") as f:
        f.write("library IEEE;\nuse IEEE.STD_LOGIC_1164.all;\nuse ieee.std_logic_arith.all;\nuse ieee.std_logic_unsigned.all;\nuse work.UtilityPkg.all;\n\n")
        f.write("\n-- Start Include user packages --\n")
        for package in PackagesUsed:
            f.write("use work." + package + ".all;\n")
            
        f.write("-- End Include user packages --\n\n")
        f.write("package "+ write_pgk +" is\n")
        f.write("type "+ write_record +" is record \n")
        ports = entityDef[0]["port"]
      
        for x in ports:
            if inOutFilter in x["InOut"]:
                continue
            f.write("  " + x["name"] + " : "+ x["type"] +  ";  \n")

        f.write("end record;\n\n")

        f.write("constant " +write_record+"_null : " + write_record + " := ( \n" )
        start = "  "
        for x in ports:
            if inOutFilter in x["InOut"]:
                continue
            if x["default"]:
                nullValue = x["default"]
            elif x["type"] == "std_logic":
                nullValue = "'0'"
            elif "std_logic_vector" in x["type"] :
                nullValue = "(others => '0')"
            else:
                nullValue = x["type"]+"_null"

            line = start + x["name"] + " => "+ nullValue
            f.write(line)
            start = ",\n  "

        f.write(");\n\nend "+write_pgk+";\n\npackage body " + write_pgk +" is\n\nend package body "+write_pgk + ";")
    return write_pgk

def get_includes():
    return "library ieee;\nuse ieee.numeric_std.all;\nuse ieee.std_logic_1164.all;\nuse work.type_conversions_pgk.all;\nuse work.utilitypkg.all;\n\n"
def remove_clock_from_ports(ports):
    ports = [x for x in ports if x["name"] != "clk"]
    return ports

def port_to_plain_text(portName):
    ret = portName.replace(".","_").replace("(","_").replace(")","")
    return ret

def make_read_entity(entityDef,path="."):
    suffix = "reader"
    inOut = "out"
    et_name = entityDef[0]["name"]
    reader_entity_file = path+"/"+et_name +"_" + suffix +"_entity.vhd"
    reader_entity = get_reader_entity_name(entityDef)
    reader_pgk = get_reader_pgk_name(entityDef)
    with open(reader_entity_file,'w',newline= "") as f:
        f.write(get_includes())
        f.write("use work." +reader_pgk+".all;\n\n")
        f.write("entity " +reader_entity +" is\n")
        f.write("generic ( \n")
        f.write('  FileName : string := "./' +et_name + '_in.csv"\n);\n')
        f.write('port (\n')
        f.write("  clk : in std_logic ;\n")
        f.write("  data : out "+ get_reader_record_name(entityDef) +"\n);\nend entity;\n\n")
        f.write("architecture Behavioral of " + reader_entity  +" is \n")
        ports = entityDef[0]["port"]
        ports = [x for x in ports if x["InOut"] == "in"]
        ports = remove_clock_from_ports(ports)
        ports_ex = expand_types(ports)
        f.write("constant  NUM_COL : integer := "+ str(len(ports_ex)) +";\n")
        f.write("signal csv_r_data : t_integer_array(NUM_COL downto 0)  := (others=>0)  ;")
        f.write("begin\n\n")
        f.write("csv_r :entity  work.csv_read_file \n    generic map (\n       FileName =>  FileName, \n       NUM_COL => NUM_COL,\n       useExternalClk=>true,\n       HeaderLines =>  2\n       )\n        port map(\n       clk => clk,\n       Rows => csv_r_data\n       );\n\n\n")
        index = 0
        for x in ports_ex:
            f.write("integer_to_" + get_shortend_typename(x) + '(csv_r_data(' +str(index) +'), data.' + x["name"] + ');\n')
            index+=1 

        f.write("end Behavioral;")


def make_write_entity(entityDef,path="."):
    inOut = "in"
    suffix = "writer"
    
    et_name = entityDef[0]["name"]
    write_entity_file = path+"/"+et_name +"_" + suffix +"_entity.vhd"
    write_entity = get_writer_entity_name(entityDef)
    write_pgk = get_writer_pgk_name(entityDef)

    with open(write_entity_file,'w',newline= "") as f:
        f.write(get_includes())
        f.write("use work." +write_pgk+".all;\n\n")
        f.write("entity " +write_entity +" is\n")
        f.write("generic ( \n")
        f.write('  FileName : string := "./' +et_name + '_out.csv"\n);\n')
        f.write('port (\n')
        f.write("  clk : in std_logic ;\n")
        f.write("  data : in " + get_writer_record_name(entityDef) +"\n);\nend entity;\n\n")
        f.write("architecture Behavioral of " + write_entity  +" is \n")
        ports = entityDef[0]["port"]
        ports = remove_clock_from_ports(ports)
        ports_ex = expand_types(ports)
        f.write("constant  NUM_COL : integer := " + str(len(ports_ex))  +" ;\n")
        f.write("signal data_int : t_integer_array(NUM_COL downto 0)  := (others=>0)  ;\nbegin\n\n")
        f.write("csv_w : entity  work.csv_write_file \n")
        f.write('    generic map (\n         FileName => FileName,\n         HeaderLines=> "')
        start = ""
        for x in ports_ex:
            
            f.write(start + port_to_plain_text(x["name"]))
            start="; "
        
        f.write('",\n         NUM_COL =>   NUM_COL ) \n    port map(\n         clk => clk, \n         Rows => data_int\n    );\n\n')
        
        index = 0
        for x in ports_ex:
            f.write(get_shortend_typename(x) + '_to_integer(data.' + x["name"] + ', data_int(' +str(index) +') );\n')
            index+=1 
            
        f.write("end Behavioral;")
        
def get_test_bench_file_basename(entityDef):
    et_name = entityDef[0]["name"]  
    tb_entity =  et_name +"_tb_csv"     
    return tb_entity


def make_test_bench_for_test_cases(entityDef,path="."):
    et_name = entityDef[0]["name"]
    tb_entity_file = path+"/"+et_name +"_tb_csv.vhd"
    tb_entity = get_test_bench_file_basename(entityDef)
    write_pgk = get_writer_pgk_name(entityDef)
    reader_pgk = get_reader_pgk_name(entityDef)

    with open(tb_entity_file,'w',newline= "") as f:
        f.write(get_includes())
        f.write("  use work." + write_pgk +".all;\n")
        f.write("  use work." + reader_pgk +".all;\n")
        f.write("entity " + tb_entity + " is \nend " + tb_entity + ";\n\n")
        f.write("architecture behavior of " + tb_entity + " is \n  signal clk : std_logic := '0';\n")
        f.write("  signal data_in : " + get_reader_record_name(entityDef) + " := " + get_reader_record_name(entityDef) + "_null;\n")
        f.write("  signal data_out : " + get_writer_record_name(entityDef) + " := " + get_writer_record_name(entityDef) + "_null;\n")
        f.write("\n\nbegin \n\n  clk_gen : entity work.ClockGenerator generic map ( CLOCK_period => 10 ns) port map ( clk => clk );\n")
        
        f.write('  csv_read : entity work.' + get_reader_entity_name(entityDef) + ' generic map (FileName => "./' + tb_entity +'.csv" ) port map (clk => clk ,data => data_in);\n')
        f.write('  csv_write : entity work.' + get_writer_entity_name(entityDef) + ' generic map (FileName => "./' + tb_entity +'_out.csv" ) port map (clk => clk ,data => data_out);\n\n')
        
        ports = entityDef[0]["port"]
        ports = [x for x in ports if x["InOut"] == "in"]
        ports = remove_clock_from_ports(ports)

        for x in ports:
            f.write('data_out.' + x['name'] + " <= data_in." + x['name'] +";\n")

        f.write("\n\n")

        ports = entityDef[0]["port"]
        ports = remove_clock_from_ports(ports)    
        f.write("DUT :  entity work." + et_name + " port map(\n  clk => clk")
        for x in ports:
            f.write(",\n  " + x["name"] +" => data_out." + x["name"] )
        
        f.write("\n);\nend behavior;\n")


def make_sim_csv_file(entityDef,FileName,FilterOut):
    et_name = entityDef[0]["name"]
    ports = entityDef[0]["port"]
    ports = [x for x in ports if x["InOut"] != FilterOut]
    ports = remove_clock_from_ports(ports)
    ports_ex = expand_types(ports)
    if FilterOut == "out":
        delimiter=", "
    else:
        delimiter="; "
    
    with open(FileName,"w",newline="") as f:
   
        if FilterOut == "out":
            start = ""
        else :
            start = "time  " + delimiter
            
        for x in ports_ex:
            
            f.write(start + port_to_plain_text(x["name"]))
            start = delimiter
            
        f.write('\n')
        
        for i in range(1000):
            

            if FilterOut == "out":
                start = ""
            else :
                start = str(i) + delimiter
                

            for x in ports_ex:
                f.write(start + "0")
                start = delimiter
                
            f.write('\n')


def make_xml_test_case(entityDef,path):
    et_name = get_test_bench_file_basename(entityDef)
    sim_out_filename = path+"/"+get_test_bench_file_basename(entityDef)+".testcase.xml"
    with open(sim_out_filename,"w",newline="") as f:
        f.write('<?xml version="1.0"?>\n')
        f.write("<testcases>\n")
        f.write('  <testcase name="' + et_name+'empty_test01">\n')
        f.write('    <descitption> autogenerated empty test case</descitption>\n')
        sim_in_filename =get_test_bench_file_basename(entityDef)+".csv"
        f.write('    <inputfile>' + sim_in_filename+'</inputfile>\n')
        sim_out_filename = get_test_bench_file_basename(entityDef)+"_out.csv"
        f.write('    <referencefile>' + sim_out_filename+'</referencefile>\n')
        f.write('    <entityname>' + et_name+'</entityname>\n')
        f.write('    <tc_type>Unclear</tc_type>\n')
        f.write('    <difftool>diff</difftool>\n')
        f.write('    <RegionOfInterest>\n')
        f.write('      <Headers>\n      </Headers>\n')
        f.write('      <Lines>\n      </Lines>\n')
        f.write('    </RegionOfInterest>\n')
        f.write('  </testcase>\n</testcases>\n')
        


        

def main():
    parser = argparse.ArgumentParser(description='Creates Test benches for a given entity')
    parser.add_argument('--OutputPath', help='Path to where the test bench should be created',default="TargetX/tests/StandardOP2")
    parser.add_argument('--InputFile', help='File containing the Test bench',default="TargetX/Components/TXWaveFormOutputStorage.vhd")
    

    args = parser.parse_args()
    
    cwd = os.getcwd()
    print(cwd)
    entityDef = vhdl_get_entity_def(args.InputFile)
    ParsedFile = vhdl_parser(args.InputFile)
    make_package_file(entityDef,"none","write",ParsedFile["packageUSE"], args.OutputPath)
    make_package_file(entityDef,"out","read",ParsedFile["packageUSE"], args.OutputPath)

    make_read_entity(entityDef,args.OutputPath)
    make_write_entity(entityDef,args.OutputPath)
    make_test_bench_for_test_cases(entityDef,args.OutputPath)
    sim_in_filename = args.OutputPath+"/"+get_test_bench_file_basename(entityDef)+".csv"
    
    make_sim_csv_file(entityDef,sim_in_filename,"out")
    sim_out_filename = args.OutputPath+"/"+get_test_bench_file_basename(entityDef)+"_out.csv"
    make_sim_csv_file(entityDef,sim_out_filename,"none")
    
    make_xml_test_case(entityDef,args.OutputPath)


if __name__== "__main__":
    main()