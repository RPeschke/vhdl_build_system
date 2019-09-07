import os
import shelve
import fnmatch, re
import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 


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
    FileContent = FileContent.replace(": =", " := ")
    FileContent =FileContent.lower()
    return FileContent