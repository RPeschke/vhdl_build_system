#!/usr/bin/python
import sys

import os,sys,inspect
from  vhdl_parser import *
from  vhdl_get_dependencies import *
from vhdl_make_simulation import *
from shutil import copyfile


def File_get_base_name(FullName):
    baseName = FullName.replace("\\","/").split("/")[-1].split(".")[-2]
    return baseName

def FileBaseNameNotInList(FullName,FileList):
    baseName = File_get_base_name(FullName)
    for x in FileList:
        x = File_get_base_name(x)
        if baseName == x:
            return False
    return True

def vhdl_make_implementation(Entity, UCF_file):

    build_path =  "build/"
    vhdl_make_simulation(Entity,build_path)
    Entity_build_path = build_path+  Entity +"/"
    project_file_path = Entity_build_path + Entity+ ".prj"

    IPcoreList = getListOfFiles(".","*.xco")
    IPcoreList = [x for x in IPcoreList if build_path not in x]
    try:  
        pwd = os.getcwd()
        outPath = Entity_build_path +'/ipcores/'
        os.mkdir(pwd+"/" +outPath)
    except OSError:  
        print ("Creation of the directory %s failed" % outPath)
    else:  
        print ("Successfully created the directory %s " % outPath)
    for x in IPcoreList:
        if build_path not in x:
            copyfile(x,outPath + x.split("/")[-1])

    


    with open(project_file_path) as f:
        
        files = list()
        for x in f:
            spl = x.split('"')
            if len(spl) > 1 and FileBaseNameNotInList(spl[1],IPcoreList) :
                files.append(spl[1])
        
    #print(files)
   
    
    with open(Entity_build_path+Entity+".in",'w',newline="") as f:
        f.write("# Input file for MakeISE\n[ISE Configuration]\n#Generate project configuration\n#You can specify any parameter here which will override the input file 'defaults'\n")
        f.write("InputFile = " +Entity + "_simpleTemplate.xise.in\nVersion = 14.7\nDevice Family = Spartan6\nPackage = fgg676\nDevice = xc6slx150t\nSpeed Grade = -3\n#Verilog Include Directories = ../../../hdl|../../../../../openadc/hdl/hdl\n\n\n")
        f.write("[UCF Files]\n#Normally just one UCF file\n../../" + UCF_file +"\n\n\n") 
        f.write("[VHDL Files]\n#List of VHDL source files... by default added for sim + implementation\n") 
        for x in files:
            f.write(x+"\n")
        
        f.write("\n\n\n")
        f.write("[CoreGen Files]\n#Add XCO files. You can just list the filename, OR have the CoreGen files be\n#auto-generated as well by specifying the section name\n#fifoonly_adcfifo.xco = ADC FIFO CoreGen Setup")
        
        used_ip_cores =list()
        for x in IPcoreList:
            x = File_get_base_name(x)
            if x not in used_ip_cores:
                used_ip_cores.append(x)
                f.write("./ipcore/"+ x+".xco\n")
        f.write("\n\n\n")

        f.write("#[ADC FIFO CoreGen Setup]\n#InputFile = fifoonly_adcfifo.xco.in\n#input_depth = 8192\n#output_depth = CALCULATE $input_depth$ / 4\n#full_threshold_assert_value = CALCULATE $input_depth$ - 2\n#full_threshold_negate_value = CALCULATE $input_depth$ - 1\n##These are set to 16-bits for all systems... overkills most of the time\n#write_data_count_width = 16\n#read_data_count_width = 16\n#data_count_width = 16\n\n\n#[Setup File]\n#AVNET\n#UART_CLK = 40000000\n#UART_BAUD = 512000\n\n")






def main():
    if len(sys.argv) > 2:
        Entity = sys.argv[1]
        UCF_FILE = sys.argv[2]
    else:
        Entity= "klm_scint"
        UCF_FILE = "./klm_scrod/constraint/klm_scrod.ucf"

    print('Entity: ', Entity)
    vhdl_make_implementation(Entity, UCF_FILE)

if __name__== "__main__":
    main()

