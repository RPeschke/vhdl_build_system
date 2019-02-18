#!/usr/bin/python
import sys

import os,sys,inspect
from  vhdl_parser import *
from  vhdl_get_dependencies import *

def vhdl_make_simulation_intern(entity,BuildFolder = "build/"):  
    OutputPath = BuildFolder + entity + "/"
    OutputBuild = OutputPath + "make.sh"
    outputExe =  entity + ".exe"
    inputPath =  entity+ ".prj"
    
    CSV_readFile=OutputPath+Entity+".csv" 
    CSV_writeFile=OutputPath+Entity+"_out.csv" 

    OutputRun = OutputPath + "run.sh"

    outputTCL = OutputPath + "isim.cmd"


    with open(outputTCL,'w') as f:
        f.write('onerror ' + '{resume' + '} \n')
        f.write('wave add / \n ')
        f.write('run 1000 ns; \n ')
        f.write('quit -f;  \n ')



    with open(OutputRun,'w',newline="") as f:
        f.write('if [ "$1" != "" ]; then \n')
        f.write("   cp -f $1 " +CSV_readFile+ "  \n")
        f.write("fi \n")
        f.write("cd " +OutputPath+ "  \n")
        f.write("fuse -intstyle ise -incremental -lib secureip -o " + outputExe + " -prj " +  inputPath + "  work." + entity +" \n")
        f.write("./"+ outputExe + " -intstyle ise -tclbatch isim.cmd  \n")
        f.write("cd -  \n")
        f.write('if [ "$2" != "" ]; then \n')
        f.write("   cp -f " +CSV_writeFile+ " $2  \n")
        f.write("fi \n")



def vhdl_make_simulation(Entity,BuildFolder = "build/"):

    
    DataBaseFile=BuildFolder+"DependencyBD"
    vhdl_parse_folder(Folder= ".",DataBaseFile=DataBaseFile)
    vhdl_get_dependencies(Entity,DataBaseFile=DataBaseFile)

    vhdl_make_simulation_intern(Entity,BuildFolder)



if len(sys.argv) > 1:
    Entity = sys.argv[1]
else:
    Entity= "tb_fifo"

print('Entity: ' , Entity)
vhdl_make_simulation(Entity)