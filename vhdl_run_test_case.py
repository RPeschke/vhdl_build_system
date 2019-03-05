import sys
import os
import six
import xml.etree.ElementTree as ET
import subprocess
from os.path import relpath
from  vhdl_make_simulation import *
from  vhdl_test_cases_report_gen import *

runPrefix = 'ssh  xilinx "cd /home/ise/xilinx_share2/GitHub/klm_scrod_vas && '
runsuffix = '" >  build/comandlinedumb.txt'

def xml_find_or_defult(xml_note,xkey,xdefault):
    xkey = xml_note.find(xkey)
    if xkey is None:
        return xdefault
    else:
        return str(xkey.text).strip()
        
def size_of_file(FileName):
    with open(FileName) as f:
        fcont = f.read()
        return len(fcont)
        #return  f.tell()

def read_testcase_file(FileName,testResults,making_build_system = True,build_systems = list(),buildFolder = "build/", reparse = True):
    tree = ET.parse(FileName)
    root = tree.getroot()
    
    filePath = os.path.dirname(FileName)
 
    print(root)
    for child in root:
        name = child.get("name")
        entity = str(child.find("entityname").text).strip()
        
        print("Start Running Test-Case: " + name + " for entity: "+entity)
        if making_build_system and entity not in build_systems:
            vhdl_make_simulation(Entity=entity,BuildFolder = "build/",reparse=reparse)
            reparse=False
            build_systems.append(entity)
            build_command = runPrefix +buildFolder +  entity +"/build_only.sh > " + buildFolder + entity +"/compile.txt" + runsuffix
            print("executing build command: " + build_command)
            x= os.system(build_command)

        
        inputfile = filePath +"/" + str(child.find("inputfile").text).strip()
        referencefile = filePath+"/"+str(child.find("referencefile").text).strip()
        
        tempoutfile = buildFolder + entity +"/" + xml_find_or_defult(child,"tempoutfile",name+"_out_temp.csv") 
        isimBatchFile = xml_find_or_defult(child,"tclbatch","") 
        run_command = runPrefix + buildFolder +  entity +"/run_only.sh " +  inputfile + " " +tempoutfile +" " +isimBatchFile +" > "+ buildFolder + entity +"/" +name +"_run.txt" + runsuffix
        run_command = run_command.replace("\\","/")
        print("executing run command: " + run_command)
        x= os.system(run_command)

        diff_tool = xml_find_or_defult(child,"difftool","diff")

        diff_file = buildFolder + entity +"/" +name +"_diff.txt"
        diff_command = runPrefix +diff_tool+" " +  tempoutfile +" "+  referencefile + " > "+ diff_file +" 2>&1 " +runsuffix 
        diff_command = diff_command.replace("\\","/")
        print("executing diff command: "+diff_command)
        x=os.system(diff_command)
        

        ret = {}
        ret["name"] = name
        ret["entity"] =entity
        ret["descitption"] =xml_find_or_defult(child,"descitption","")
        ret["InputFile"] = inputfile
        ret["OutputFile"] = tempoutfile
        ret["referencefile"] = referencefile
        ret["diff_file"]= diff_file
        ret["diff_tool"]=diff_tool
        ret["IsDifferent"] = (size_of_file(diff_file) != 0)
        testResults.append(ret)

    return  reparse


def make_rel_linux_path(FileName):
   
    RunPath = os.getcwd()
   
    ab = os.path.abspath(FileName)
    
    rel = relpath(ab, RunPath).replace("\\","/")
    
    return rel

def main():
    testResults = list()
    reparse = True
    ReportOutName= "build/test.md"
    if len(sys.argv) > 1:
        fileName = sys.argv[1]
        rel = make_rel_linux_path(fileName)
        build_systems = list()
        read_testcase_file(rel,testResults=testResults, build_systems=build_systems)
        base=os.path.basename(rel)
        ReportOutName =  os.path.splitext(base)[0]+".md"
        


    else:
        flist = getListOfFiles(".","*.testcase.xml")
        build_systems = list()
        for f in flist:
            rel = make_rel_linux_path(f)
            reparse = read_testcase_file(rel,testResults=testResults,build_systems=build_systems,reparse=reparse)

    print(testResults)
    vhdl_test_cases_report_gen(ReportOutName,testResults)



if __name__== "__main__":
    main()