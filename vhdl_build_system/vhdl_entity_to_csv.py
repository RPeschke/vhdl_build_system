#!/usr/bin/python
import sys

import os,sys,inspect
from   .vhdl_parser  import *
from  .vhdl_get_dependencies  import *
from  .vhdl_get_entity_def  import *



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

