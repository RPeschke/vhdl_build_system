#!/usr/bin/python
import sys
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

import argparse


from vhdl_build_system.vhdl_build_system.vhdl_get_list_of_files import getListOfFiles
from  vhdl_build_system.vhdl_build_system.vhdl_run_test_case import test_case_runner


def main():
    parser = argparse.ArgumentParser(description='Runs Test Cases')
    parser.add_argument('--path', help='Path to where the build system is located',default="build/")
    parser.add_argument('--test', help='specifies a specific cases to run. if not set it will run all test cases',default="tests/TRACK_FINDER_INTERSECTOR/track_finder_intersector_tb_csv.testcase.xml")
    parser.add_argument('--update', help='Update the reference output file. use --update true to update a test case.',default = "False")
    parser.add_argument('--verbose', help='Update the reference output file. use --update true to update a test case.',default = "False")

    args = parser.parse_args()
    
    doUpdate = args.update != "False"
    verbose  = args.verbose != "False"
    

    tb_run = test_case_runner(update_reference_file=doUpdate, verbose = verbose)
    if len(args.test) > 1:
        fileName = args.test
        tb_run.run(fileName)
        tb_run.generate_report(args.path + "/"+ tb_run.testResults[-1]["name"]+".md")
        


    else:
        flist = getListOfFiles(".","*.testcase.xml")
        
        for f in flist:
            tb_run.run(f)
        
        tb_run.generate_report(args.path + "/tests.md")
            

if __name__== "__main__":
    main()