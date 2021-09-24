
import os

import xml.etree.ElementTree as ET

from os.path import relpath

import pandas as pd

from shutil import copyfile

import matplotlib.pyplot as plt
import numpy as np


import pandas as pd
from pylab import *

from matplotlib.pyplot import figure


from  .vhdl_make_simulation import *
from  .vhdl_merge_split_test_cases import *


def plot_dataset_pcolor(df,FileName):
    Values = df.values
    datasets_names   = df.columns.values
    figure(num=None, figsize=(8, 20), dpi=80, facecolor='w', edgecolor='k')
    d= Values.max(axis=0)
    
    d = np.where(d==0, 1, d) 
    x_normed = Values / d
    plt.rcParams['xtick.bottom'] = plt.rcParams['xtick.labelbottom'] = False
    plt.rcParams['xtick.top'] = plt.rcParams['xtick.labeltop'] = True
    c = plt.pcolor(x_normed)
    xticks(np.arange(0.5, len(datasets_names), step=1), datasets_names, rotation='vertical')
    plt.gca().invert_yaxis()
    plt.tight_layout()


    plt.savefig(FileName)


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



def make_description(xNode,buildFolder):
    ret =xml_find_or_defult(xNode,"descitption","")
    try:
        
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
        df = pd.read_csv(tempoutfile,delimiter=' *; *',skipinitialspace=True, engine='python')
        df1=df.rename(columns=lambda x: x.strip())


        dfOut = get_ROI(df1,headers,Lines)

    
        

        referencefile = buildFolder+entity+"/" + xml_find_or_defult(xNode,"referencefile",name+"_out_ref.csv") 
        df = pd.read_csv(referencefile,delimiter=' *; *',skipinitialspace=True, engine='python')
        df1=df.rename(columns=lambda x: x.strip())
        
        df_ref = get_ROI(df1,headers,Lines)

        ret += "\n ### Comparison Between Output File and Reference File\n\n"
#        dfOut.insert(len(list(dfOut)),'Out <==> Ref',' <==> ')
        dfOut=dfOut.join(df_ref,rsuffix='_ref')
     
        plot_dataset_pcolor(dfOut,buildFolder + entity +"/"+ name+".png")
        ret+= "![OutputSignals]("+entity +"/"+ name+".png"+")\n\n"
  
    except :
        ret += "\n error while running the test\n "

    return ret

    
def Display_and_run_command(command,RunText="Running the Following Command",OutPutFile="redirect.txt",Folder="."):
    if len(command)>0 and  command:
        print(RunText + command+" > "+ OutPutFile)
        os.system("cd " +Folder +" && "+ command+" > "+ OutPutFile)


def xml_find_or_defult(xml_note,xkey,xdefault):
    if xml_note is None:
        return xdefault

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

def remove_white_spaces(FileName):
    with open(FileName) as f:
        content = f.read()
    
    content = content.replace(" ps ", "")
    content = content.replace(" ", "")
    content = content.split("\n")
    content = content[0:990]
    content = "\n".join(content)
    with open(FileName, "w") as f:
        f.write(content)


def get_status(xnode):
    if xnode["IsDifferent"]:
        status = "fail"
    else:
        status="sucess"
    return status

class test_case_runner:
    def __init__(self,buildFolder = "build/", reparse = True,update_reference_file=False, verbose = False ) -> None:
        self.buildFolder = buildFolder
        self.reparse = reparse
        self.update_reference_file = update_reference_file
        self.testResults = []
        self.build_systems = list()
        self.verbose = verbose


    def run(self, FileName):
        FileName= make_rel_linux_path(FileName)
        tree = ET.parse(FileName)
        root = tree.getroot()
        split_test_case(FileName)
        filePath = os.path.dirname(FileName)
     
        print(root)
        for child in root:
            name = child.get("name")
            entity = str(child.find("entityname").text).strip()
            entity_folder = self.buildFolder+entity+"/"
            print("Start Running Test-Case: " + name + " for entity: "+entity)
            if entity not in self.build_systems:
                vhdl_make_simulation(Entity=entity,BuildFolder = self.buildFolder,reparse=self.reparse)
                reparse=False
                self.build_systems.append(entity)
                build_output_redirect = "" if self.verbose  else " > "+ entity_folder +"compile.txt"  +" 2>&1 " 
                build_command = entity_folder +"/build_only.sh" + build_output_redirect
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
            run_output_redirect = "" if self.verbose  else " > "+ entity_folder +name +"_run.txt"  +" 2>&1 " 
            run_command = entity_folder +"/run_only.sh " +  inputfile + " " +tempoutfile +" " +isimBatchFile + run_output_redirect
            run_command = run_command.replace("\\","/")
            print("executing run command: " + run_command)
            x= os.system(run_command)
            Display_and_run_command(postRunScript,"postRunScript: ", name +"_postRunScript.txt",entity_folder)

            remove_white_spaces(tempoutfile)
            remove_white_spaces(referencefile)

            diff_tool = xml_find_or_defult(child,"difftool","diff")

            diff_file = entity_folder +name +"_diff.txt"
            diff_output_redirect = "" if self.verbose  else  " > "+ diff_file +" 2>&1 " 
            diff_command = diff_tool+" " +  tempoutfile +" "+  referencefile + diff_output_redirect
            diff_command = diff_command.replace("\\","/")
            print("executing diff command: "+diff_command)
            x=os.system(diff_command)
            
            if self.update_reference_file:
                copyfile(tempoutfile, referencefile)

            ret = {}
            ret["name"] = name
            ret["entity"] =entity
            ret["descitption"] =make_description(child,self.buildFolder)
            ret["InputFile"] = inputfile
            ret["OutputFile"] = tempoutfile
            ret["referencefile"] = referencefile
            ret["diff_file"]= diff_file
            ret["diff_tool"]=diff_tool
            ret["IsDifferent"] = (size_of_file(diff_file) != 0)
            ret["TestType"] =  xml_find_or_defult(child,"tc_type","TestCase")
            self.testResults.append(ret)

        merge_test_case(FileName)
        return  reparse



    def generate_report(self, FileName):
        with open(FileName,'w',newline="") as f:
            f.write("Test Cases Report\n=======\n\n")
            f.write("# Summery\n\n")
            f.write("|status | entity | test case name| test  type |\n")
            f.write("|-------|--------|---------------|------------|\n")
            for x in self.testResults:
                
                f.write("|" + get_status(x) +"|"+ x["entity"] +"|"+ x["name"] +"|" +x["TestType"] +"|\n")
            
            f.write(" \n # Details \n \n ")
            for x in self.testResults:
                f.write(" \n ## " + x["name"] +" \n \n ")
                f.write(" \n ### Overview \n \n")
                f.write("|Name |Value|\n|------|----|\n")
                f.write("|Status | " + get_status(x) +"|\n")
                f.write("|Entity | "+ x["entity"] +"|\n")
                f.write("|Name | "+ x["name"] +"|\n")
                f.write("|test type | "+ x["TestType"] +"|\n")
                f.write("\n ### Desciption \n \n")
                f.write(x["descitption"])
                f.write("\n ### Files \n \n")
                f.write("|Name |Path|\n|------|----|\n")
                f.write("|Input File | " + x["InputFile"] +"|\n")
                f.write("|Output File | "+ x["OutputFile"] +"|\n")
                f.write("|Reference File | "+ x["referencefile"] +"|\n\n")
            


def make_rel_linux_path(FileName):
   
    RunPath = os.getcwd()
   
    ab = os.path.abspath(FileName)
    
    rel = relpath(ab, RunPath).replace("\\","/")
    
    return rel

