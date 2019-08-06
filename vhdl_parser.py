import os
import shelve
import fnmatch, re
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from vhdl_build_system.vhdl_get_type_def import *
from vhdl_get_type_def import *


def getListOfFiles(dirName, Pattern = '*.*'):
    # create a list of file and sub directories 
    # names in the given directory 
    regex = fnmatch.translate(Pattern)
    Include_regEX = re.compile(regex)
    listOfFile = os.listdir(dirName)
    allFiles = list()
    # Iterate over all the entries
    for entry in listOfFile:
        # Create full path
        fullPath = os.path.join(dirName, entry)
        # If entry is a directory then get the list of files in this directory 
        if os.path.isdir(fullPath):
            allFiles = allFiles + getListOfFiles(fullPath,Pattern)
        elif Include_regEX.match(fullPath) :
            fullPath = fullPath.replace("\\","/")
            allFiles.append(fullPath)
                
    return allFiles


def vhdl_parser(FileName):
    ret = {}
    ret["FileName"] = FileName
    FileContent=load_file_witout_comments(FileName)
    
    entityDef=findDefinitionsInFile(FileContent,"entity","is")
    ret["entityDef"]=entityDef
    
    Type_Def=findDefinitionsInFile(FileContent,"type","is")
    ret["Type_Def"]=Type_Def

    type_def_detail = vhdl_get_type_def_from_string(FileContent)
    ret["Type_Def_detail"]=type_def_detail

    packageDef=findDefinitionsInFile(FileContent,"package","is")
    ret["packageDef"]=packageDef

    packageUSE=findDefinitionsInFile(FileContent,"work.","all",".")
    ret["packageUSE"]=packageUSE

    #types_used_s=findDefinitionsInFile(FileContent,"signal",";",":",1)
    #types_used_s_no_default=findDefinitionsInFile(FileContent,"signal",";"," ",2)
    #types_used_v=  findDefinitionsInFile(FileContent,"variable",";",":",1)
    #types_used_v_no_default=findDefinitionsInFile(FileContent,"variable",";"," ",2)
    #types_used_c=  findDefinitionsInFile(FileContent,"constant",";",":",1)

    #ret["types_used"]=types_used_s +types_used_v +types_used_s_no_default +types_used_v_no_default + types_used_c


    entityUSE_G=findDefinitionsInFile(FileContent,"entity","generic")
    entityUSE=findDefinitionsInFile(FileContent,"entity","port")
    entityUSE2=findDefinitionsInFile(FileContent,"entity","(")
    ret["entityUSE"]=entityUSE + entityUSE_G +entityUSE2
    
    ComponentUSE=findDefinitionsInFile(FileContent,"component","is")
    ComponentUSE_G=findDefinitionsInFile(FileContent,"component","generic")
    ComponentUSE_P=findDefinitionsInFile(FileContent,"component","port")
    ret["ComponentUSE"]=ComponentUSE +ComponentUSE_G +ComponentUSE_P
    
    ret["Modified"] = os.path.getmtime(FileName)
    return ret


def findDefinitionsInFile(FileContent,prefix,suffix,delimiter=" ",offset = 0):
    ret=[]
    
    entity_cantidates = FileContent.split(prefix)
    for x in entity_cantidates[1:]:
        
        words = x.strip().split(delimiter)
        words = list(filter(None, words)) 
        if len(words)  > 1 + offset and   suffix in words[1 +offset] and words[0 +offset].strip() not in ret:
            ret.append(words[0 +offset].strip())
            
    
    return ret


def load_file_witout_comments(FileName):
    FileContent = ""
    with open(FileName, "r") as f:
        contents =f.readlines()
        for x in contents:
            FileContent+= x.split("--")[0].split("\r\n")[0].split("\n")[0] + " "
    
    FileContent = FileContent.replace("\t", "  ")
    FileContent = FileContent.replace("(", " ( ")
    FileContent = FileContent.replace(")", " ) ")
    FileContent = FileContent.replace(";", " ; ")
    FileContent = FileContent.replace(":", " : ")
    FileContent =FileContent.lower()
    return FileContent



def vhdl_parse_folder(Folder = ".", DataBaseFile = "build/DependencyBD"):
    try:
        os.remove(DataBaseFile+".bak")
        os.remove(DataBaseFile+".dat")
        os.remove(DataBaseFile+".dir")  
    except OSError:  
        print ("removing of DBfile  %s failed" % DataBaseFile)
    else:  
        print ("Successfully removed DB file %s " % DataBaseFile)


    d = shelve.open(DataBaseFile) 
    flist = getListOfFiles(Folder,"*.vhd")
    for f in flist:
        if "build/" not in f:
            print(f)
            ret= vhdl_parser(f)
            d[f] = ret
    
    d.close()   


