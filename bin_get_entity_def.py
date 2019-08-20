#!/usr/bin/python
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_parser import *
from  vhdl_build_system.vhdl_get_dependencies import *
from  vhdl_build_system.vhdl_load_file_without_comments import * 

def main():
    if len(sys.argv) > 1:
        FileName = sys.argv[1]
    else:
        FileName = "klm_scint/source/KLMScrodRegCtrl.vhd"

    print('FileName: ' , FileName)

    entity_list = vhdl_get_entity_def(FileName)
    DataBaseFile = "build/" + FileName.replace("\\","/").replace("/","_").replace(" ","_")  
    d = shelve.open(DataBaseFile) 
    
    d["entity"] = entity_list
       
    
    d.close()   


if __name__== "__main__":
    
    main()