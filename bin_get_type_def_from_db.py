import sys
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_build_system.vhdl_get_type_def_from_db import *

def main():
    ret = get_package_for_type("fifo_nativ_write_32_m2s")
    print(ret["packageDef"][0])


if __name__== "__main__":
    main()