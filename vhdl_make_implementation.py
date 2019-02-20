#!/usr/bin/python
import sys

import os,sys,inspect
from  vhdl_parser import *
from  vhdl_get_dependencies import *
from vhdl_make_simulation import *


def vhdl_make_implementation(Entity, UCF_file):
    build_path =  "build/"
    vhdl_make_simulation(Entity,build_path)
    project_file_path = build_path+  Entity +"/" +Entity+ ".prj"
    with open(project_file_path) as f:
        
        files = list()
        for x in f:
            spl = x.split('"')
            if len(spl) > 1:
                files.append(spl[1])
        
    print(files)





vhdl_make_implementation("tb_simple_readout","")