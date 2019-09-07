#!/usr/bin/python
import sys
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 


from vhdl_build_system.vhdl_parser             import *

from  vhdl_build_system.vhdl_get_dependencies  import *
from  vhdl_build_system.vhdl_get_entity_def    import *
from  vhdl_build_system.vhdl_get_type_def      import *
from  vhdl_build_system.vhdl_db                import *

def main():
    if len(sys.argv) > 1:
        FileName = sys.argv[1]
    else:
        FileName = "klm_scint/source/klm_scint_pkg.vhd"

    print('FileName: ' , FileName)
    
    DataBaseFile = "build/" + FileName.replace("\\","/").replace("/","_").replace(" ","_")  
    d = LoadDB(DataBaseFile) 
    types = vhdl_get_type_def(FileName)
    d["types"] = types
       
    saveDB(DataBaseFile,d)



if __name__== "__main__":
    main()
