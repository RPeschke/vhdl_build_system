#!/usr/bin/python
import sys
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
#sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_parser import *
from  vhdl_build_system.vhdl_get_dependencies import *
from  vhdl_build_system.vhdl_make_simulation import *
from  vhdl_build_system.vhdl_make_implementation import *
from shutil import copyfile


def main():
    if len(sys.argv) > 2:
        Entity = sys.argv[1]
        UCF_FILE = sys.argv[2]
    else:
        Entity= "txwaveformreadoutTop4"
        UCF_FILE = "./firmware-ethernet/constraints/klm_scrod_eth_dac_waveform_2.ucf"

    print('Entity: ', Entity)
    vhdl_make_implementation(Entity, UCF_FILE)
    make_build_script(Entity, UCF_FILE)

if __name__== "__main__":
    main()
