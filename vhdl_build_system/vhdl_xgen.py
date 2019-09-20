import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_make_test_bench   import *
from  .            import vhdl_parser



def make_xgen(scriptName,PackageName,path="build/"):
    flist = getListOfFiles(".", "*/" + scriptName + ".py")
    print(flist)
    if len(flist) > 0:
        print(flist[0])
        line = "python3  " + flist[0] + " --OutputPath " +path +"/xgen/" +  PackageName + ".vhd --PackageName " + PackageName
        print(line)
        os.system(line)

def get_xgen_file(packageName):
    scriptName = packageName.split("_")[1]
    flist = getListOfFiles(".", "*/" + scriptName + ".py")
    return flist[0]


def vhdl_xgen_make_package(packageName,OutputPath="build/xgen/"):
    fileName = OutputPath+packageName+".vhd"
    xgenfile =  get_xgen_file(packageName)

    print('<xgen FileName="' +fileName+'" PackageName="'+packageName+'"')
    os.system("python " +xgenfile+ " --OutputPath " + fileName + " --PackageName " + packageName)
    print('</xgen>')
    xgen_package_def  = vhdl_parser.vhdl_parser(fileName)
    return xgen_package_def