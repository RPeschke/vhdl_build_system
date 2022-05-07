#!/usr/bin/python
import sys
import os,sys,inspect

#sys.path.insert(0,parentdir) 




from  vhdl_build_system.vhdl_make_simulation import vhdl_make_simulation


def main():
    if len(sys.argv) > 1:
        Entity = sys.argv[1]
    else:
        Entity= "entiy_with_iop_tb_tb_csv"

    print('Entity: ' , Entity)
    vhdl_make_simulation(Entity)

if __name__== "__main__":
    main()