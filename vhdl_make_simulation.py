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
    OutputBuild_only = OutputPath + "build_only.sh"
    OutputRun_only = OutputPath + "run_only.sh"
    
    outputTCL = OutputPath + "isim.cmd"
    make_TCL(outputTCL)

    handle_input_csv = 'if [ "$1" != "" ]; then \n' + '   echo "copy $1  ' +CSV_readFile+ '"  \n'+ "   cp -f $1 " +CSV_readFile+ "  \n" + "   sed -i 's/,/ /g' " +CSV_readFile+ "  \n"+ "fi \n"
    build_command = "rm -rf " +outputExe+ "  \n" + "fuse -intstyle ise -incremental -lib secureip -o " + outputExe + " -prj " +  inputPath + "  work." + entity +" \n"
    handle_isimBatchFile = 'if [ "$3" != "" ]; then \n  tclbatchfile=$1\nelse\n  tclbatchfile=isim.cmd\nfi\n\n'

    run_and_backup = "./"+ outputExe + " -intstyle ise -tclbatch $tclbatchfile  \n" + "entity_name=\"" + entity +"\" \n" + "inFile=\"" + entity +".csv\" \n" + "outFile=\"" + entity +"_out.csv\" \n" + "Simcount=`date +%Y%m%d%H%M%S`\n"+ "backupIn=\"backup/\"$entity_name\"_\"$Simcount\".csv\" \n" + "backupOUT=\"backup/\"$entity_name\"_\"$Simcount\"_out.csv\" \n" + 'echo "copy $inFile $backupIn"  \n' + "cp -f $inFile  $backupIn \n"+ 'echo "copy $outFile $backupOUT"  \n' + "cp -f $outFile $backupOUT \n"             
    handle_output_csv = 'if [ "$2" != "" ]; then \n' + '   echo "copy ' +CSV_writeFile+ '  $2"  \n'+ "   cp -f " +CSV_writeFile+ " $2  \n" + "fi \n"
    
    with open(OutputBuild_only,'w',newline="") as f:
        f.write("cd " +OutputPath+ "  \n")
        f.write(build_command)
        f.write("cd -  \n")


    with open(OutputRun_only,'w',newline="") as f:
        f.write(handle_input_csv)

        f.write("cd " +OutputPath+ "  \n")
        f.write(handle_isimBatchFile)
        f.write(run_and_backup)
    
        f.write("cd -  \n")
        f.write(handle_output_csv)


    with open(OutputRun,'w',newline="") as f:
        f.write(handle_input_csv)
        f.write("cd " +OutputPath+ "  \n")
        f.write(build_command)

        f.write(handle_isimBatchFile)
        f.write(run_and_backup)
      

        f.write("cd -  \n")
        f.write(handle_output_csv)





def vhdl_make_simulation(Entity,BuildFolder = "build/",reparse=True):

    
    DataBaseFile=BuildFolder+"DependencyBD"
    if reparse:
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