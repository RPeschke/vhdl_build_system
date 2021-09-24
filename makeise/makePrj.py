#!/usr/bin/python
import sys
import os
import six
try:
    import configparser
except:
    from six.moves import configparser
   
ConfigParser=configparser
fusePath = 'fuse'



class runScript:
    def __init__(self):
        self.runSimulationScript = "cd build\n"
        self.Name = "unset"

    def AddName(self,Name):
        self.Name = Name
        

    def AddScript(self,Name,BuildScriptName,RunScript):
        self.runSimulationScript +=  BuildScriptName + '\n'
        self.runSimulationScript +=  RunScript + '\n'
        self.runSimulationScript +=  'echo "<'+Name + '>" >> ' + self.Name + '.txt \n'
        self.runSimulationScript +=  'cat dummy_diff.txt >> ' + self.Name + '.txt \n'
        self.runSimulationScript +=  'echo "</'+Name + '>" >> ' + self.Name + '.txt \n'
    
    def write2File(self,FileName):
        self.runSimulationScript = 'echo "start ' +  self.Name +'"\nrm -f build/'+ self.Name +".txt\n" + self.runSimulationScript
        self.runSimulationScript += '\necho "====Finished Running====="\n'
        self.runSimulationScript += "\ncat " + self.Name +".txt\n"
        self.runSimulationScript += "\n cd - \n"
        with open(FileName,"w") as f :
            f.write(self.runSimulationScript)

gRunScript = runScript()

def HandleSimulation(config,section,path):
    Name = config.get(section,"Name")
    Name = Name.replace('"', '')
    ExecutableName = path + "/" + Name + "_beh.exe"
    
    TopLevelModule = config.get(section,"TopLevelModule")
    tclbatchName = path + "/" +Name+"_beh.cmd"
    ProjectName = path + "/" + Name+ "_beh.prj"

    makeScript = fusePath + ' -intstyle ise -incremental -lib secureip -o ' + ExecutableName +" -prj " +ProjectName + " " + TopLevelModule
    
    makeScript_name = path+"/sim_"+Name+"_build.sh"
   
    with open(makeScript_name,"w") as f : 
        f.write(makeScript)
    


    RunScript = ExecutableName + " -intstyle ise  -tclbatch " +tclbatchName + " -wdb " + path + "/" + Name + "_beh.wdb"
    
    ReferenceInputDataFile= config.get(section,'ReferenceInputDataFile')
    inFile = config.get(section,'InputDataFile')
    OutputDataFile= config.get(section,'OutputDataFile')
    ReferenceDataFile= config.get(section,'ReferenceOutputDataFile')
    
    runScript_name = path+"/sim_"+Name+"_run.sh"
    gRunScript.AddScript(Name, makeScript_name, runScript_name)
    with open(runScript_name,"w") as f :
        if OutputDataFile and ReferenceDataFile:
            f.write('rm -f ' + OutputDataFile  +'\n')
            f.write('rm -f dummy_diff.txt \n')

        if inFile and ReferenceInputDataFile:
            f.write('\ncp ' + ReferenceInputDataFile +' ' + inFile +'\n')
        f.write(RunScript+'\n')
        if inFile and ReferenceInputDataFile:
            f.write('\nrm -f '+ inFile +'\nfi\n')
        if OutputDataFile and ReferenceDataFile:
            f.write('\necho "<======diff========>"\ndiff  ' +OutputDataFile + ' ' +ReferenceDataFile +'\necho "<=======end diff=====>"\n')
            f.write('\ndiff  ' +OutputDataFile + ' ' +ReferenceDataFile +'> dummy_diff.txt\n')
    onerror=config.get(section,'Onerror')
    Runtime =config.get(section,'Runtime')
    tclbatchScript = "onerror "+onerror +"\nwave add /\nrun "+Runtime + ";\nquit -f;"
    with open(tclbatchName,"w") as f : 
        f.write(tclbatchScript)
    
    with open(ProjectName,"w") as f :
        for op in config.options(section):
            opValue = config.get(section,op)
            if opValue == None:
                f.write('vhdl work "' + op+ '"\n')

def handleImplement(config,section,path):
    'xst -intstyle ise -filter "/home/ise/xilinx_share2/GitHub/AxiStream/build/iseconfig/filter.filter" -ifn "/home/ise/xilinx_share2/GitHub/AxiStream/build/tb_streamTest.xst" -ofn "/home/ise/xilinx_share2/GitHub/AxiStream/build/tb_streamTest.syr"'
    pass

def main(args = None):
    if args == None:
        args = sys.argv[1:]
    
    

    if len(args) < 1:
        sys.exit()    

    FileName = args[0]
    Path =  os.path.abspath(args[1])
    print(FileName)
    
    gRunScript.AddName("run")
    config = ConfigParser.RawConfigParser(allow_no_value=True)
    config.optionxform=str
    config.read(FileName)
    sections = config.sections()
    
    for s in sections:
        if "Simulation" in s: 
            print(s)
            HandleSimulation(config,s,Path)
        elif "Implement" in s: 
            pass


    gRunScript.write2File("run.sh")

if (__name__ == "__main__"):
    main()