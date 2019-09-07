#!/usr/bin/python
import sys
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
#sys.path.insert(0,parentdir) 


from  vhdl_build_system.vhdl_parser import *
from  vhdl_build_system.vhdl_get_dependencies import *
from  vhdl_build_system.vhdl_make_simulation import *


def main():
    if len(sys.argv) > 1:
        Entity = sys.argv[1]
    else:
        Entity= "tb_fifo"

    print('Entity: ' , Entity)
    vhdl_make_simulation(Entity)

if __name__== "__main__":
    main()