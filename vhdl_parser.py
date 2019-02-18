import os
import shelve
import fnmatch, re


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
            allFiles.append(fullPath)
                
    return allFiles


def vhdl_parser(FileName):
    ret = {}
    ret["FileName"] = FileName
    FileContent=load_file_witout_comments(FileName)
    entityDef=findDefinitionsInFile(FileContent,"entity","is")
    ret["entityDef"]=entityDef

    packageDef=findDefinitionsInFile(FileContent,"package","is")
    ret["packageDef"]=packageDef

    packageUSE=findDefinitionsInFile(FileContent,"work.","all",".")
    ret["packageUSE"]=packageUSE

    entityUSE_G=findDefinitionsInFile(FileContent,"entity","generic")
    ret["entityUSE_G"]=entityUSE_G

    entityUSE=findDefinitionsInFile(FileContent,"entity","port")
    ret["entityUSE"]=entityUSE
    
    
    ret["Modified"] = os.path.getmtime(FileName)
    return ret


def findDefinitionsInFile(FileContent,prefix,suffix,delimiter=" "):
    ret=[]
    
    entity_cantidates = FileContent.split(prefix)
    for x in entity_cantidates:
        
        words = x.strip().split(delimiter)
        words = list(filter(None, words)) 
        if len(words)  > 1 and   suffix in words[1]:
            ret.append(words[0])
            
    
    return ret


def load_file_witout_comments(FileName):
    FileContent = ""
    with open(FileName, "r") as f:
        contents =f.readlines()
        for x in contents:
            FileContent+= x.split("--")[0].split("\n")[0] + " "
    
    FileContent.replace("\t", "  ")
    return FileContent



def vhdl_parse_folder(Folder = ".", DataBaseFile = "build/DependencyBD"):
    d = shelve.open("build/DependencyBD") 
    flist = getListOfFiles(".","*.vhd")
    for f in flist:
        print(f)
        ret= vhdl_parser(f)
        d[f] = ret
    
    d.close()   