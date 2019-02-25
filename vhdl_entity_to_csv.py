#!/usr/bin/python
import sys

import os,sys,inspect
from  vhdl_parser import *
from  vhdl_get_dependencies import *
from  vhdl_get_entity_def import *



def vhdl_entity_to_csv(FileName,outputName):
    entity_list = vhdl_get_entity_def(FileName)

    with open(outputName+"_in.csv","w",newline="") as f:
        for x in entity_list[0]["port"]:
            if x["InOut"] != "out":
                f.write(x["name"]+", ")
            
        f.write("\n")
        for x in entity_list[0]["port"]:
            if x["InOut"] != "out":
                f.write(x["type"]+", ")
        
    with open(outputName + "_out.csv","w",newline="") as f:
        for x in entity_list[0]["port"]:
            f.write(x["name"]+", ")
            
        f.write("\n")
        for x in entity_list[0]["port"]:
            f.write(x["type"]+", ")

def main():
    if len(sys.argv) > 1:
        FileName = sys.argv[1]
    else:
        FileName = "klm_scrod/source/run_ctrl.vhd"


    x=os.path.dirname(os.path.abspath(FileName))
    print(x)
    x=x.replace("\\","/")
    y=os.path.dirname(os.path.abspath(x))
    print(y)
    try_make_dir(y+"/tests",False)
    base=os.path.basename(FileName)
    baseName= os.path.splitext(base)[0]
    try_make_dir(y+"/tests/tb_"+baseName,False)
    
    vhdl_entity_to_csv(FileName,y+"/tests/tb_"+baseName +"/tb_"+baseName)


if __name__== "__main__":
    
    main()