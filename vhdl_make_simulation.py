#!/usr/bin/python
import sys

import os,sys,inspect
from  vhdl_parser import *
from  vhdl_get_dependencies import *

def vhdl_create_file(FileName,Content=""):
    with open(FileName,'w') as f:
        f.write(Content)


def make_TCL(name):
    with open(name,'w',newline="") as f:
        f.write('onerror ' + '{resume' + '} \n')
        f.write('wave add / \n ')
        f.write('run 2000 ns; \n ')
        f.write('quit -f;  \n ')


def vhdl_make_simulation_intern(entity,BuildFolder = "build/"):  
    OutputPath = BuildFolder + entity + "/"
    OutputBuild = OutputPath + "make.sh"
    outputExe =  entity + ".exe"
    inputPath =  entity+ ".prj"
    
    CSV_readFile=OutputPath+entity+".csv" 
    CSV_writeFile=OutputPath+entity+"_out.csv" 
    
    vhdl_create_file(CSV_readFile)
    vhdl_create_file(CSV_writeFile)


    try_make_dir(OutputPath+"/backup")

    OutputRun = OutputPath + "run.sh"
    outputTCL = OutputPath + "isim.cmd"
    make_TCL(outputTCL)





    with open(OutputRun,'w',newline="") as f:
        f.write('if [ "$1" != "" ]; then \n')
        f.write('   echo "copy $1  ' +CSV_readFile+ '"  \n')
        f.write("   cp -f $1 " +CSV_readFile+ "  \n")
        f.write("   sed -i 's/,/ /g' " +CSV_readFile+ "  \n")    
        f.write("fi \n")
        f.write("cd " +OutputPath+ "  \n")
        f.write("rm -rf " +outputExe+ "  \n")
        f.write("fuse -intstyle ise -incremental -lib secureip -o " + outputExe + " -prj " +  inputPath + "  work." + entity +" \n")
        f.write("./"+ outputExe + " -intstyle ise -tclbatch isim.cmd  \n")
        
        f.write("entity_name=\"" + entity +"\" \n")
        f.write("inFile=\"" + entity +".csv\" \n")
        f.write("outFile=\"" + entity +"_out.csv\" \n")
        
        f.write("Simcount=`date +%Y%m%d%H%M%S`\n")
       
      
        f.write("backupIn=\"backup/\"$entity_name\"_\"$Simcount\".csv\" \n")
        f.write("backupOUT=\"backup/\"$entity_name\"_\"$Simcount\"_out.csv\" \n")
        f.write('echo "copy $inFile $backupIn"  \n')
        f.write("cp -f $inFile  $backupIn \n")
        f.write('echo "copy $outFile $backupOUT"  \n')
        f.write("cp -f $outFile $backupOUT \n")

        f.write("cd -  \n")
        f.write('if [ "$2" != "" ]; then \n')
        f.write('   echo "copy ' +CSV_writeFile+ '  $2"  \n')
        f.write("   cp -f " +CSV_writeFile+ " $2  \n")
        f.write("fi \n")





def vhdl_make_simulation(Entity,BuildFolder = "build/"):

    
    DataBaseFile=BuildFolder+"DependencyBD"
    vhdl_parse_folder(Folder= ".",DataBaseFile=DataBaseFile)
    vhdl_get_dependencies(Entity,DataBaseFile=DataBaseFile)

    vhdl_make_simulation_intern(Entity,BuildFolder)


def main():
    if len(sys.argv) > 1:
        Entity = sys.argv[1]
    else:
        Entity= "tb_fifo"

    print('Entity: ' , Entity)
    vhdl_make_simulation(Entity)

if __name__== "__main__":
    main()