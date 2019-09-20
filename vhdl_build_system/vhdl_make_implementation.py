#!/usr/bin/python
import sys
import os,sys,inspect


from  .vhdl_parser import *
from  .vhdl_get_dependencies import *
from  .vhdl_make_simulation import *
from .vhdl_get_list_of_files import *

from shutil import copyfile


def File_get_base_name(FullName,DotIndex = -2):
    baseName = FullName.replace("\\","/").split("/")[-1].split(".")[DotIndex]
    return baseName

def FileBaseNameNotInList(FullName,FileList,DotIndex = -2):
    baseName = File_get_base_name(FullName,DotIndex)
    for x in FileList:
        x = File_get_base_name(x,DotIndex)
        if baseName == x:
            return False
    return True

def vhdl_make_implementation(Entity, UCF_file):

    build_path =  "build/"
    vhdl_make_simulation(Entity,build_path)
    Entity_build_path = build_path+  Entity +"/"
    project_file_path = Entity_build_path + Entity+ ".prj"


    IPcoreList_in = getListOfFiles(".","*.xco.in")
    
    IPcoreList = getListOfFiles(".","*.xco")
    IPcoreList = [x for x in IPcoreList if build_path not in x]

    
    
    IPcoreList = [x for x in IPcoreList if FileBaseNameNotInList(x, IPcoreList_in,0)]
    print(IPcoreList)
    print(IPcoreList_in)
    outPath = Entity_build_path +'/coregen/'
    try_make_dir(outPath)


    for x in IPcoreList:
        if build_path not in x:
            copyfile(x,outPath + x.split("/")[-1])

    


    with open(project_file_path) as f:
        
        files = list()
        for x in f:
            spl = x.split('"')
            if len(spl) > 1 and FileBaseNameNotInList(spl[1],IPcoreList) and FileBaseNameNotInList(spl[1],IPcoreList_in,0):
                files.append(spl[1])
        
    #print(files)
   
    with  open(Entity_build_path+Entity+"_proto_Project.in") as f:
        protoProject = f.read()
    
    print(protoProject)

    with open(Entity_build_path+Entity+".in",'w',newline="") as f:
        f.write(protoProject)
        f.write("InputFile = " +Entity + "_simpleTemplate.xise.in\n\n\n")

        f.write("[UCF Files]\n#Normally just one UCF file\n../../" + UCF_file +"\n\n\n") 
        f.write("[VHDL Files]\n#List of VHDL source files... by default added for sim + implementation\n") 
        for x in files:
            f.write(x+"\n")
        
        f.write("\n\n\n")
        f.write("[CoreGen Files]\n#Add XCO files. You can just list the filename, OR have the CoreGen files be\n#auto-generated as well by specifying the section name\n#fifoonly_adcfifo.xco = ADC FIFO CoreGen Setup\n")
        
        used_ip_cores =list()
        for x in IPcoreList:
            x = File_get_base_name(x)
            if x not in used_ip_cores:
                used_ip_cores.append(x)
                f.write("./"+ x+".xco\n")


        for x in IPcoreList_in:
            x1 = File_get_base_name(x,0)
            
            f.write(x1 + ".xco = " + x1 + "\n")
        f.write("\n\n\n")
        for x in IPcoreList_in:

            x1 = File_get_base_name(x,0)
            
            f.write("[" + x1 + "]\n")
            f.write("InputFile = ../../" + x + "\n\n") 
        f.write("\n\n\n")

        f.write("#[ADC FIFO CoreGen Setup]\n#InputFile = fifoonly_adcfifo.xco.in\n#input_depth = 8192\n#output_depth = CALCULATE $input_depth$ / 4\n#full_threshold_assert_value = CALCULATE $input_depth$ - 2\n#full_threshold_negate_value = CALCULATE $input_depth$ - 1\n##These are set to 16-bits for all systems... overkills most of the time\n#write_data_count_width = 16\n#read_data_count_width = 16\n#data_count_width = 16\n\n\n#[Setup File]\n#AVNET\n#UART_CLK = 40000000\n#UART_BAUD = 512000\n\n")



def make_build_script(Entity, UCF_file):


    script='''#/bin/bash
#syntesize
xst -intstyle ise -filter "./iseconfig/filter.filter" -ifn "{entityName}.xst" -ofn "{entityName}.syr"

#Translate:
ngdbuild -filter "iseconfig/filter.filter" -intstyle ise -dd _ngo -sd coregen -nt timestamp -uc {ucf_file} -p xc6slx150t-fgg676-3 {entityName}.ngc {entityName}.ngd

#MAP:
map -filter "iseconfig/filter.filter" -intstyle ise -p xc6slx150t-fgg676-3 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o {entityName}_map.ncd {entityName}.ngd {entityName}.pcf

#place and Route:
par -filter "iseconfig/filter.filter" -w -intstyle ise -ol high -mt off {entityName}_map.ncd {entityName}.ncd {entityName}.pcf

#tracer:
trce -filter iseconfig/filter.filter -intstyle ise -v 3 -s 3 -n 3 -fastpaths -xml {entityName}.twx {entityName}.ncd -o {entityName}.twr {entityName}.pcf


#Generate Bitfile:
bitgen -filter "iseconfig/filter.filter" -intstyle ise -f {entityName}.ut {entityName}.ncd
'''.format(
entityName=Entity,
ucf_file="../../" + UCF_file
)
    Entity_build_path =  "build/"
    with open(Entity_build_path+Entity+"/build_implementation.sh",'w',newline="") as f:
        f.write(script)
    
    synt = '''#/bin/bash
#syntesize
xst -intstyle ise -filter "./iseconfig/filter.filter" -ifn "{entityName}.xst" -ofn "{entityName}.syr"
'''.format(
entityName=Entity,
ucf_file="../../" + UCF_file
)
    Entity_build_path =  "build/"
    with open(Entity_build_path+Entity+"/build_syntesize.sh",'w',newline="") as f:
        f.write(script)

