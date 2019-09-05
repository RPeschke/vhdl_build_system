import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_make_test_bench   import *
from  vhdl_build_system.vhdl_parser            import *

from  vhdl_make_test_bench   import *
from  vhdl_parser            import *

def make_xgen(scriptName,PackageName,path="build/"):
    flist = getListOfFiles(".", "*/" + scriptName + ".py")
    print(flist)
    if len(flist) > 0:
        print(flist[0])
        line = "python3  " + flist[0] + " --OutputPath " +path +"/xgen/" +  PackageName + ".vhd --PackageName " + PackageName
        print(line)
        os.system(line)

def vhdl_xgen_make_package(packageName,OutputPath="build/"):
    fileName = OutputPath+packageName+".vhd"


    return fileName