#!/usr/bin/python
import sys
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_parser           import *
from  vhdl_build_system.vhdl_get_dependencies import *
from  vhdl_build_system.vhdl_get_entity_def   import *
from  vhdl_build_system.vhdl_entity_to_csv    import *

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