#!/usr/bin/python
import sys

import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 
from  pyHelper.vhdl_parser import *
from  pyHelper.vhdl_get_dependencies import *

def vhdl_make_simulation_intern(entity,BuildFolder = "build/"):  
    OutputPath = BuildFolder + entity + "/"
    OutputBuild = OutputPath + "make.sh"
    outputExe =  entity + ".exe"
    inputPath =  entity+ ".prj"

    OutputRun = OutputPath + "run.sh"

    outputTCL = OutputPath + "isim.cmd"


    with open(outputTCL,'w') as f:
        f.write('onerror ' + '{resume' + '} \n')
        f.write('wave add / \n ')
        f.write('run 1000 ns; \n ')
        f.write('quit -f;  \n ')

    with open(OutputBuild,'w') as f:
        f.write("fuse -intstyle ise -incremental -lib secureip -o " + outputExe + " -prj " +  inputPath + "  work." + entity)


    with open(OutputRun,'w') as f:
        f.write("cd " +OutputPath+ "  \n")
        f.write("source ./make.sh \n")
        f.write("./"+ outputExe + " -intstyle ise -tclbatch isim.cmd  \n")
        f.write("cd -  \n")



def vhdl_make_simulation(Entity,BuildFolder = "build/"):
    DataBaseFile=BuildFolder+"DependencyBD"
    vhdl_parse_folder(Folder= ".",DataBaseFile=DataBaseFile)
    vhdl_get_dependencies(Entity,DataBaseFile=DataBaseFile)

    vhdl_make_simulation_intern(Entity,BuildFolder)



if len(sys.argv) > 1:
    Entity = sys.argv[1]
else:
    Entity= "tb_fifo_cc2"

print('Entity: ' , Entity)
vhdl_make_simulation(Entity)