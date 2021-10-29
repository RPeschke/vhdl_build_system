#!/usr/bin/python
import sys

from  vhdl_build_system.vhdl_make_implementation import vhdl_make_implementation, make_build_script



def main():
    if len(sys.argv) > 2:
        Entity = sys.argv[1]
        UCF_FILE = sys.argv[2]
    else:
        Entity= "trigger_chain_tsim_top"
        UCF_FILE = "./firmware-ethernet/constraints/klm_scrod_eth_dac_waveform_2.ucf"

    print('Entity: ', Entity)
    vhdl_make_implementation(Entity, UCF_FILE)
    make_build_script(Entity, UCF_FILE)

if __name__== "__main__":
    main()
