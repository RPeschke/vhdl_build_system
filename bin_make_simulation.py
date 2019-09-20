#!/usr/bin/python
import sys
import os,sys,inspect

#sys.path.insert(0,parentdir) 


from  vhdl_build_system.vhdl_parser import *
from  vhdl_build_system.vhdl_get_dependencies import *
from  vhdl_build_system.vhdl_make_simulation import *


def main():
    if len(sys.argv) > 1:
        Entity = sys.argv[1]
    else:
        Entity= "serialdataroutprocess_cl_tb_csv"

    print('Entity: ' , Entity)
    try_make_dir("./backup/xgen")
    vhdl_make_simulation(Entity)

if __name__== "__main__":
    main()