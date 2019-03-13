#!/usr/bin/python
import sys

import os,sys,inspect
from  vhdl_parser import *
from  vhdl_get_dependencies import *

def vhdl_create_file(FileName,Content=""):
    with open(FileName,'w') as f:
        f.write(Content)


def make_TCL(name,with_quit=True):
    with open(name,'w',newline="") as f:
        f.write('onerror ' + '{resume' + '} \n')
        f.write('wave add / \n ')
        f.write('run 2000 ns; \n ')
        if with_quit:
            f.write('quit -f;  \n ')

def get_handle_isim_script(isim_file="isim.cmd"):
    handle_isimBatchFile = 'if [ "$3" != "" ]; then \n  tclbatchfile=$1\nelse\n  tclbatchfile=' + isim_file + '\nfi\n\n'
    return handle_isimBatchFile


def make_run_build_scripts(FileName,build=False,run=False,with_gui=False,entity='',OutputPath=''):
    CSV_readFile=OutputPath+entity+".csv" 
    CSV_writeFile=OutputPath+entity+"_out.csv" 
    outputExe =  entity + ".exe"
    inputPath =  entity+ ".prj"
    
    use_GUI_command=" "
    if with_gui:
        outputTCL = "isim_gui.cmd"
        make_TCL(OutputPath + outputTCL,with_quit=False)
        use_GUI_command =" -gui "
        
    else:
        outputTCL =  "isim.cmd"
        make_TCL(OutputPath + outputTCL)

    with open(FileName,'w',newline="") as f:
        if run:
            handle_input_csv = 'if [ "$1" != "" ]; then \n' + '   echo "copy $1  ' +CSV_readFile+ '"  \n'+ "   cp -f $1 " +CSV_readFile+ "  \n" + "   sed -i 's/,/ /g' " +CSV_readFile+ "  \n"+ "fi \n"
            f.write(handle_input_csv)
        
        f.write("cd " +OutputPath+ "  \n")
        if build:
            build_command = "rm -rf " +outputExe+ "  \n" + "fuse -intstyle ise -incremental -lib secureip -o " + outputExe + " -prj " +  inputPath + "  work." + entity +" \n"
            f.write(build_command)

        if run:
            handle_isimBatchFile = get_handle_isim_script(outputTCL)
            run_and_backup = "./"+ outputExe + " -intstyle ise -tclbatch $tclbatchfile  "+use_GUI_command +"\n" + "entity_name=\"" + entity +"\" \n" + "inFile=\"" + entity +".csv\" \n" + "outFile=\"" + entity +"_out.csv\" \n" + "Simcount=`date +%Y%m%d%H%M%S`\n"+ "backupIn=\"backup/\"$entity_name\"_\"$Simcount\".csv\" \n" + "backupOUT=\"backup/\"$entity_name\"_\"$Simcount\"_out.csv\" \n" + 'echo "copy $inFile $backupIn"  \n' + "cp -f $inFile  $backupIn \n"+ 'echo "copy $outFile $backupOUT"  \n' + "cp -f $outFile $backupOUT \n"             
            f.write(handle_isimBatchFile)
            f.write(run_and_backup)
      

        f.write("cd -  \n")
            
        if run:
            handle_output_csv = 'if [ "$2" != "" ]; then \n' + '   echo "copy ' +CSV_writeFile+ '  $2"  \n'+ "   cp -f " +CSV_writeFile+ " $2  \n" + "fi \n"
    
            f.write(handle_output_csv)   


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
    OutputRun_only_with_gui = OutputPath + "run_only_with_gui.sh"
    



    make_run_build_scripts(FileName=OutputBuild_only,build=True,entity=entity,OutputPath=OutputPath)

    make_run_build_scripts(FileName=OutputRun,build=True,run=True, entity=entity,OutputPath=OutputPath)
    
    make_run_build_scripts(FileName=OutputRun_only,run=True, entity=entity,OutputPath=OutputPath)
    
    
    make_run_build_scripts(FileName=OutputRun_only_with_gui,run=True, with_gui=True, entity=entity,OutputPath=OutputPath)
    








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