
import argparse
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_make_test_bench   import *
from  vhdl_build_system.vhdl_parser            import *

def main():
    parser = argparse.ArgumentParser(description='Generate Packages')
    parser.add_argument('--path',        help='Path to where the build system is located',default="build/")
    parser.add_argument('--packageName', help='',default="axiStream")
    parser.add_argument('--arguments',   help='',default="")
    args = parser.parse_args()
    flist = getListOfFiles(".", "*/" + args.packageName + ".py")
    print(flist)
    if len(flist) > 0:
        print(flist[0])

if __name__== "__main__":
    main()