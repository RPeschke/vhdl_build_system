from  vhdl_parser import *
from  vhdl_get_dependencies import *
from  vhdl_get_entity_def import *



def get_shortend_typename(portdef):
    ty = portdef["type"]
    if ty == "std_logic":
        return "sl"
    elif "std_logic_vector" in ty:
        return "slv"
    
    return ty

def get_reader_entity_name(entityDef):
    et_name = entityDef[0]["name"]
    reader_entity = et_name +"_reader_entity"
    return reader_entity

def get_writer_entity_name(entityDef):
    et_name = entityDef[0]["name"]
    reader_entity = et_name +"_writer_entity"
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

def make_package_file(entityDef,inOutFilter,suffix,path="."):
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

            f.write(start + x["name"] + " => "+ nullValue)
            start = ",\n  "

        f.write(");\n\nend "+write_pgk+";\n\npackage body " + write_pgk +" is\n\nend package body "+write_pgk + ";")
    return write_pgk

def get_includes():
    return "library ieee;\nuse ieee.numeric_std.all;\nuse ieee.std_logic_1164.all;\nuse work.type_conversions_pgk.all;\nuse work.utilitypkg.all;\n\n"
def remove_clock_from_ports(ports):
    ports = [x for x in ports if x["name"] != "clk"]
    return ports

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
        f.write("constant  NUM_COL : integer := "+ str(len(ports)) +";\n")
        f.write("signal csv_r_data : t_integer_array(NUM_COL downto 0)  := (others=>0)  ;")
        f.write("begin\n\n")
        f.write("csv_r :entity  work.csv_read_file \n    generic map (\n       FileName =>  FileName, \n       NUM_COL => NUM_COL,\n       useExternalClk=>true,\n       HeaderLines =>  2\n       )\n        port map(\n       clk => clk,\n       Rows => csv_r_data\n       );\n\n\n")
        index = 0
        for x in ports:
            f.write("integer_to_" + get_shortend_typename(x) + '(data_int(' +str(index) +'), data.' + x["name"] + ') );\n')
            index+=1 

        f.write("end Behavioral;")


def make_write_entity(entityDef,path="."):
    inOut = "in"
    suffix = "writer"
    
    et_name = entityDef[0]["name"]
    write_entity_file = path+"/"+et_name +"_" + suffix +"_entity.vhd"
    write_entity = get_writer_entity_name(entityDef)
    write_pgk = et_name +"_" + suffix +"_pgk"

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
        f.write("constant  NUM_COL : integer := " + str(len(ports))  +" ;\n")
        f.write("signal data_int : t_integer_array(NUM_COL downto 0)  := (others=>0)  ;\nbegin\n\n")
        f.write("csv_w : entity  work.csv_write_file \n")
        f.write('    generic map (\n         FileName => FileName,\n         HeaderLines=> "')
        start = ""
        for x in ports:
            f.write(start + x["name"])
            start=", "
        
        f.write('",\n         NUM_COL =>   NUM_COL ) \n    port map(\n         clk => clk, \n         Rows => data_int\n    );\n\n')
        
        index = 0
        for x in ports:
            f.write(get_shortend_typename(x) + '_to_integer(data.' + x["name"] + ', data_int(' +str(index) +') );\n')
            index+=1 
            
        f.write("end Behavioral;")
        
        

def make_test_bench_for_test_cases(entityDef,path="."):
    et_name = entityDef[0]["name"]
    tb_entity_file = path+"/tb_"+et_name +".vhd"
    tb_entity = "tb_" + et_name 
    write_pgk = et_name +"_" + "write_pgk"
    reader_pgk = et_name +"_" + "reader_pgk"

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
            f.write(";\n  " + x["name"] +" => data_out." + x["name"] )
        
        f.write("\n);\nend behavior;\n")


entityDef = vhdl_get_entity_def("klm_scint/source/Readout_Simple.vhd")
write_pgk = make_package_file(entityDef,"none","write")
read_pgk = make_package_file(entityDef,"out","read")

make_read_entity(entityDef)
make_write_entity(entityDef)
make_test_bench_for_test_cases(entityDef)