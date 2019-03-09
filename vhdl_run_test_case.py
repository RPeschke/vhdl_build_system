import sys
import os
import six
import xml.etree.ElementTree as ET
import subprocess
from os.path import relpath
from  vhdl_make_simulation import *
from  vhdl_test_cases_report_gen import *
import pandas as pd
from tabulate import tabulate
from shutil import copyfile

def get_ROI(df1,Headers,Lines):
    headers = Headers.text.split(",")
    headers = [x.strip(' ') for x in headers]
    headers = list(filter(None, headers))
    Lines1 = Lines.text.split("-")
    if len(Lines1)==2:
        Line_start = int(Lines1[0])
        Line_end = int(Lines1[1])
        dfOut = df1[headers].iloc[Line_start:Line_end]
    else:
        Lines1 = Lines.text.split(",")
        if len(Lines1) > 1:
            Lines1 = [x.strip(' ') for x in Lines1]
            Lines1 = list(filter(None, Lines1))
            Lines1 = [int(i) for i in Lines1]

            dfOut = df1[headers].iloc[Lines1]
    
    return dfOut


runPrefix = 'ssh  xilinx "cd /home/ise/xilinx_share2/GitHub/klm_scrod_vas && '
runsuffix = '" >  build/comandlinedumb.txt'

def make_description(xNode,buildFolder):
    ret =xml_find_or_defult(xNode,"descitption","")
    ROI=xNode.find("RegionOfInterest")
    if ROI is None:
        return ret

    headers = ROI.find('Headers')
    if headers is None:
        return ret


    Lines = ROI.find('Lines')
    if Lines is None:
        return ret
    

    name = xNode.get("name")
    entity = str(xNode.find("entityname").text).strip()
    tempoutfile = buildFolder+entity+"/" + xml_find_or_defult(xNode,"tempoutfile",name+"_out_temp.csv") 
    df = pd.read_csv(tempoutfile,delimiter=' *; *',skipinitialspace=True)
    df1=df.rename(columns=lambda x: x.strip())


    dfOut = get_ROI(df1,headers,Lines)

   
    

    referencefile = buildFolder+entity+"/" + xml_find_or_defult(xNode,"referencefile",name+"_out_ref.csv") 
    df = pd.read_csv(referencefile,delimiter=' *; *',skipinitialspace=True)
    df1=df.rename(columns=lambda x: x.strip())
    
    df_ref = get_ROI(df1,headers,Lines)

    ret += "\n ### Comparison Between Output File and Reference File\n\n"
    dfOut.insert(len(list(dfOut)),'Out <==> Ref',' <==> ')
    dfOut=dfOut.join(df_ref,rsuffix='_ref')

    ret+= tabulate(dfOut, headers="keys", tablefmt="github") +"\n\n"
    return ret

    
def Display_and_run_command(command,RunText="Running the Following Command",OutPutFile="redirect.txt",Folder="."):
    if len(command)>0 and  command:
        print(RunText + command+" > "+ OutPutFile)
        os.system("cd " +Folder +" && "+ command+" > "+ OutPutFile)


def xml_find_or_defult(xml_note,xkey,xdefault):
    xkey = xml_note.find(xkey)
    if xkey is None:
        return xdefault
    else:
        ret = str(xkey.text).strip()
        if ret == 'None':
            return xdefault
        else:
            return ret
        
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
        entity_folder = buildFolder+entity+"/"
        print("Start Running Test-Case: " + name + " for entity: "+entity)
        if making_build_system and entity not in build_systems:
            vhdl_make_simulation(Entity=entity,BuildFolder = buildFolder,reparse=reparse)
            reparse=False
            build_systems.append(entity)
            build_command = runPrefix + entity_folder +"/build_only.sh > " + entity_folder +"compile.txt" + runsuffix
            print("executing build command: " + build_command)
            x= os.system(build_command)

        preRunScript = xml_find_or_defult(child,"preRunScript","")
        postRunScript = xml_find_or_defult(child,"postRunScript","")
        Display_and_run_command(preRunScript,"PreRunScript: ",name +"_preRunScript.txt",entity_folder)

        inputfile = filePath +"/" + str(child.find("inputfile").text).strip()
        referencefile = filePath+"/"+str(child.find("referencefile").text).strip()
        copyfile(referencefile, entity_folder + str(child.find("referencefile").text).strip())
        tempoutfile = entity_folder + xml_find_or_defult(child,"tempoutfile",name+"_out_temp.csv") 
        isimBatchFile = xml_find_or_defult(child,"tclbatch","") 
        run_command = runPrefix + entity_folder +"/run_only.sh " +  inputfile + " " +tempoutfile +" " +isimBatchFile +" > "+ entity_folder +name +"_run.txt" + runsuffix
        run_command = run_command.replace("\\","/")
        print("executing run command: " + run_command)
        x= os.system(run_command)
        Display_and_run_command(postRunScript,"postRunScript: ", name +"_postRunScript.txt",entity_folder)

        diff_tool = xml_find_or_defult(child,"difftool","diff")

        diff_file = entity_folder +name +"_diff.txt"
        diff_command = runPrefix +diff_tool+" " +  tempoutfile +" "+  referencefile + " > "+ diff_file +" 2>&1 " +runsuffix 
        diff_command = diff_command.replace("\\","/")
        print("executing diff command: "+diff_command)
        x=os.system(diff_command)
        

        ret = {}
        ret["name"] = name
        ret["entity"] =entity
        ret["descitption"] =make_description(child,buildFolder)
        ret["InputFile"] = inputfile
        ret["OutputFile"] = tempoutfile
        ret["referencefile"] = referencefile
        ret["diff_file"]= diff_file
        ret["diff_tool"]=diff_tool
        ret["IsDifferent"] = (size_of_file(diff_file) != 0)
        ret["TestType"] =  xml_find_or_defult(child,"tc_type","TestCase")
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

    #print(testResults)
    vhdl_test_cases_report_gen(ReportOutName,testResults)



if __name__== "__main__":
    main()