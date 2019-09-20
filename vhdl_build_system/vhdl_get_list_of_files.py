import os
import pickle
import shelve
import fnmatch, re
import os,sys,inspect



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
        fullPathUnix = fullPath.replace("\\","/")
        # If entry is a directory then get the list of files in this directory 
        if os.path.isdir(fullPath):
            allFiles = allFiles + getListOfFiles(fullPath,Pattern)
        elif Include_regEX.match(fullPathUnix) :
            allFiles.append(fullPathUnix)
                
    return allFiles