import os


from .generic_helper import try_make_dir,save_file,load_file

from .vhdl_dependency_db  import dependency_db





def make_TCL(name,with_quit=True,runtime=2000):
    content = 'onerror {resume' + '} \n'+ \
    'wave add / \n ' + \
    'run ' + str(runtime) + ' ns; \n ' 
    if with_quit:
        content += 'quit -f;  \n '
    save_file(name, content)

def get_handle_isim_script(isim_file="isim.cmd",with_gui=False):
    handle_isimBatchFile = "" +\
    'if [ "$3" != "" ]; then\n' +\
    '  tclbatchfile=$1\n' +\
    'else\n' +\
    '  clock_speed=$(cat $clock_speed_file)\n' +\
    '  line_count=$(wc -l < $inFile)\n' +\
    '  runtime="$(($clock_speed * ($line_count+10)))"\n'+\
    '  tclbatchfile=' + isim_file + '\n'+\
    '  echo "onerror {' + 'resume}" > $tclbatchfile\n'    +\
    '  echo "wave add /" >> $tclbatchfile\n'+\
    '  echo "run $runtime ns;" >> $tclbatchfile\n'
    if not with_gui:
        handle_isimBatchFile += '  echo "quit -f;" >> $tclbatchfile\n'

    handle_isimBatchFile += 'fi\n\n'
    return handle_isimBatchFile


def make_run_build_scripts(FileName,build=False,run=False,with_gui=False,entity='',OutputPath=''):
    CSV_readFile=OutputPath+entity+".csv" 
    CSV_writeFile=OutputPath+entity+"_out.csv" 
    outputExe =  entity + ".exe"
    inputPath =  entity+ ".prj"
    
    use_GUI_command=" "
    if with_gui:
        outputTCL = "isim_gui.cmd"
        #make_TCL(OutputPath + outputTCL,with_quit=False)
        use_GUI_command =" -gui "
        
    else:
        outputTCL =  "isim.cmd"
        #make_TCL(OutputPath + outputTCL)

    with open(FileName,'w',newline="") as f:
        f.write("#/bin/bash\n")
        if run:
            handle_input_csv =''
            handle_input_csv += 'clock_speed_file="clock_speed.txt"\n'
            handle_input_csv += 'inFile_full_path="' + CSV_readFile + '"\n'
            handle_input_csv += 'outFile_full_path="' + CSV_writeFile + '"\n'
            handle_input_csv += "entity_name=\"" + entity +"\" \n" 
            handle_input_csv += "inFile=\"" + entity +".csv\" \n" 
            handle_input_csv += "outFile=\"" + entity +"_out.csv\" \n"     
            handle_input_csv += 'if [ "$1" != "" ]; then \n'
            handle_input_csv += '   echo "copy $1  $inFile_full_path"\n'
            handle_input_csv += "   cp -f $1  $inFile_full_path \n"
            handle_input_csv += "   sed -i 's/,/ /g' $inFile_full_path  \n"
            handle_input_csv += "fi \n"
            f.write(handle_input_csv)
        
        if run:
            remove_output_csv = ""
            remove_output_csv += 'if [ "$2" != "" ]; then \n'
            remove_output_csv += '   echo "remove old output file $2"  \n'
            remove_output_csv += "   rm -f $2  \n" 
            remove_output_csv += "fi \n"
    
            f.write(remove_output_csv)  

        f.write("cd " +OutputPath+ "  \n")
        if build:
            build_command=""
            build_command += "killall "+ outputExe+"\n"
            build_command += "rm -rf " +outputExe+ "\n" 
            build_command += "fuse -intstyle ise -incremental -lib secureip -o " + outputExe + " -prj " +  inputPath + "  work." + entity +" \n"
            f.write(build_command)

        if run:
            handle_isimBatchFile = get_handle_isim_script(outputTCL,with_gui)
            run_and_backup = ""
            run_and_backup += "killall "+ outputExe+"\n"
            run_and_backup += "./"+ outputExe + " -intstyle ise -tclbatch $tclbatchfile  "+use_GUI_command +"\n" 

            run_and_backup += "Simcount=`date +%Y%m%d%H%M%S`\n"
            run_and_backup += "backupIn=\"backup/\"$entity_name\"_\"$Simcount\".csv\" \n" 
            run_and_backup += "backupOUT=\"backup/\"$entity_name\"_\"$Simcount\"_out.csv\" \n" 
            run_and_backup += 'echo "copy $inFile $backupIn"  \n' 
            run_and_backup += "cp -f $inFile  $backupIn \n"
            run_and_backup += 'echo "copy $outFile $backupOUT"  \n' 
            run_and_backup += "cp -f $outFile $backupOUT \n"             
            f.write(handle_isimBatchFile)
            f.write(run_and_backup)
      

        f.write("cd -  \n")
            
        if run:
            handle_output_csv = ""
            handle_output_csv += 'if [ "$2" != "" ]; then \n'
            handle_output_csv += '   echo "copy $outFile_full_path  $2"  \n'
            handle_output_csv += "   cp -f $outFile_full_path $2  \n" 
            handle_output_csv += "fi \n"
    
            f.write(handle_output_csv)   

    os.system("chmod +x "+FileName) 

def make_vivado_build_run_script(entity, BuildFolder = "build/"):
    pass

def vhdl_make_simulation_intern(entity,BuildFolder = "build/"):  
    OutputPath = BuildFolder + entity + "/"
    
    CSV_readFile=OutputPath+entity+".csv" 
    CSV_writeFile=OutputPath+entity+"_out.csv" 
    
    save_file(CSV_readFile,"")
    save_file(CSV_writeFile,"")
    save_file(OutputPath+"clock_speed.txt","10")


    try_make_dir(OutputPath+"/backup")

    OutputRun = OutputPath + "run.sh"
    OutputBuild_only = OutputPath + "build_only.sh"
    OutputRun_only = OutputPath + "run_only.sh"
    OutputRun_only_with_gui = OutputPath + "run_only_with_gui.sh"
    



    make_run_build_scripts(FileName=OutputBuild_only,build=True,entity=entity,OutputPath=OutputPath)

    make_run_build_scripts(FileName=OutputRun,build=True,run=True, entity=entity,OutputPath=OutputPath)
    
    make_run_build_scripts(FileName=OutputRun_only,run=True, entity=entity,OutputPath=OutputPath)
    
    
    make_run_build_scripts(FileName=OutputRun_only_with_gui,run=True, with_gui=True, entity=entity,OutputPath=OutputPath)
    





def extract_header_from_top_file(Entity, FileName,BuildFolder):
    print("=======Extracting Header From File========")
    print(FileName)

    Content =load_file(FileName)
    
    
    h1 = Content.split("</header>")
    if len(h1)>1:
        Content=h1[0].split("<header>")[1]+"\n"
    else:
        Content=""

    save_file(BuildFolder+Entity+ "/"+ Entity +"_header.txt", Content)
    print("=======Done Extracting Header From File====")


def vhdl_make_simulation(Entity,BuildFolder = "build/",reparse=True):
    if reparse:
        dependency_db.reparse_files()
    
    fileList = dependency_db.get_dependencies_and_make_project_file(Entity)
    extract_header_from_top_file(Entity, fileList[0],BuildFolder)


    vhdl_make_simulation_intern(Entity,BuildFolder)


