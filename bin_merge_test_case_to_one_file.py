#!/usr/bin/python
import argparse
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from vhdl_build_system.vhdl_build_system.vhdl_merge_split_test_cases import *


def main():
    print("sdasd")
    parser = argparse.ArgumentParser(description='Creates Test benches for a given entity')
    parser.add_argument('--InputTestCase', help='Path to the Test Case File',default="session_01/test_derivative/Sin_wave_test.testcase.xml")
    parser.add_argument('--ExcelFile', help='Path to the input Excel File',default="session_01/test_derivative/test_derivative_withGlobals.xlsm")
    #parser.add_argument('--ReferenceCSV', help='path to the reference csv File',default="1000")

    args = parser.parse_args()
    
    if args.ExcelFile:
        merge_test_case_excel(args.InputTestCase,args.ExcelFile)
    else:
        merge_test_case(args.InputTestCase)
    


print("sdasd")

if __name__== "__main__":
    main()