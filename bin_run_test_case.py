#!/usr/bin/python
import sys
import six
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 



import six
import xml.etree.ElementTree as ET
import subprocess
from os.path import relpath
import pandas as pd
from tabulate import tabulate
from shutil import copyfile
import argparse

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LogNorm

import pandas as pd
from pylab import *
import matplotlib.colors
from matplotlib.pyplot import figure


from  vhdl_build_system.vhdl_build_system.vhdl_make_simulation import *
from  vhdl_build_system.vhdl_build_system.vhdl_test_cases_report_gen import *
from  vhdl_build_system.vhdl_build_system.vhdl_run_test_case import *


def main():
    parser = argparse.ArgumentParser(description='Runs Test Cases')
    parser.add_argument('--path', help='Path to where the build system is located',default="build/")
    parser.add_argument('--test', help='specifies a specific cases to run. if not set it will run all test cases',default="")
    parser.add_argument('--update', help='Update the reference output file. use --update true to update a test case.',default = "False")

    args = parser.parse_args()
    
    doUpdate = args.update != "False"
    testResults = list()
    reparse = True
    ReportOutName= args.path + "/tests.md"
    tree = ET.parse(args.path+"/vhdl_build_setup.xml")
    root = tree.getroot()
    ssh_config = xml_find_or_defult(root.find("remote"), "ssh_config","")
    remote_path = xml_find_or_defult(root.find("remote"), "path" ,"")
    if ssh_config == "":
        vhdl_build.runPrefix = ''
        vhdl_build.runsuffix = ""

    else:
        vhdl_build.runPrefix = 'ssh  ' + ssh_config + ' "cd ' + remote_path +' && '
        vhdl_build.runsuffix = '" >  build/comandlinedumb.txt'
        
    if len(args.test) > 1:
        fileName = args.test
        rel = make_rel_linux_path(fileName)
        build_systems = list()
        read_testcase_file(rel,testResults=testResults, build_systems=build_systems,update_reference_file=doUpdate)
        base=os.path.basename(rel)
        ReportOutName = args.path + "/"+ os.path.splitext(base)[0]+".md"
        


    else:
        flist = getListOfFiles(".","*.testcase.xml")
        build_systems = list()
        for f in flist:
            rel = make_rel_linux_path(f)
            reparse = read_testcase_file(rel,testResults=testResults,build_systems=build_systems,reparse=reparse,update_reference_file=doUpdate)

    #print(testResults)
    vhdl_test_cases_report_gen(ReportOutName,testResults)



if __name__== "__main__":
    main()