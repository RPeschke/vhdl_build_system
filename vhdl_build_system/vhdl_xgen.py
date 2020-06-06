import os,sys,inspect


from  .vhdl_make_test_bench   import *
from  .                       import vhdl_parser
from .vhdl_db                 import *
from .vhdl_get_list_of_files  import *


def make_xgen(scriptName,PackageName,path="build/"):
    flist = getListOfFiles(".", "*/" + scriptName + ".py")
    print(flist)
    if len(flist) > 0:
        print(flist[0])
        line = "python3  " + flist[0] + " --OutputPath " +path +"/xgen/" +  PackageName + ".vhd --PackageName " + PackageName
        print(line)
        os.system(line)

def get_xgen_file(packageName):
    print(packageName)
    scriptName = packageName.split("_")[1]
    flist = getListOfFiles(".", "*/" + scriptName + ".py")
    if len(flist) == 0:
        raise Exception("Unable to locate xgen file for: '" + scriptName+"'")
    
    return flist[0]


def vhdl_xgen_make_package(packageName,OutputPath="build/xgen/"):
    fileName = OutputPath+packageName+".vhd"
    xgenfile =  get_xgen_file(packageName)

    print('<xgen FileName="' +fileName+'" PackageName="'+packageName+'"')
    os.system("python " +xgenfile+ " --OutputPath " + fileName + " --PackageName " + packageName)
    print('</xgen>')
    xgen_package_def  = vhdl_parser.vhdl_parser(fileName)
    xgenDB=LoadDB("build/xgen.db")
    xgenDB[fileName]=xgen_package_def
    saveDB("build/xgen.db",xgenDB)
    
    return xgen_package_def