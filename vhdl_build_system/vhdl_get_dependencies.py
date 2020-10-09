import os
import shelve
import fnmatch, re


from .vhdl_db import *
from .vhdl_parser import * 
from .vhdl_xgen import *


def remove_doublication_from_list(inList):
    ret  = list(dict.fromkeys(inList))
    return ret

def try_make_dir(name,isRelativePath=True):
    try:
        if isRelativePath:
            abs_name = os.getcwd()+"/" +name
        else:
            abs_name = name

        os.mkdir(abs_name)
    except OSError:  
        print ("Creation of the directory %s failed" % name)
    else:  
        print ("Successfully created the directory %s " % name)


def vhdl_get_dependencies_internal(Entity,DataBaseFile="build/DependencyBD"):
    
    d =LoadDB(DataBaseFile)
    TB_entity = Entity
    eneties_used ={}
  
    eneties_used[TB_entity] = find_entity(d,TB_entity,".")

    old_length = 0
    new_length = 1
    while (new_length > old_length):
        old_length = new_length
        eneties_used = make_depency_list(d,eneties_used ,find_used_entities,find_entity)
        eneties_used = make_depency_list(d,eneties_used ,find_used_package,find_PacketDef)
        eneties_used = make_depency_list(d,eneties_used ,find_used_components,find_component)
        new_length = len(eneties_used)

    fileList=list()
    for k in eneties_used:
        FileName =eneties_used[k].replace("\\","/") 
        if FileName not in fileList:
            fileList.append(FileName)
        else:
            print("doublication "+ FileName)

    saveDB(DataBaseFile,d)      
    return fileList        
    
def vhdl_get_dependencies(Entity,OutputFile=None,DataBaseFile="build/DependencyBD"):
    
    
    fileList = vhdl_get_dependencies_internal(Entity, DataBaseFile)
    
    if not OutputFile:
        OutputFile =  "build/" +Entity+"/"+Entity+".prj"
        outPath = "build/" +Entity
    
    try_make_dir(outPath)
     
    with open(OutputFile,'w') as f:
        for k in fileList:
            lines = 'vhdl work "../../' + k + '"\n'
            f.write(lines)
    
    return fileList





def find_entity(d,Entity, currentFileName="."):
    for k in d.keys():
        if not isSubPath(currentFileName, k):
            continue
        for e in d[k]['entityDef']:
            
            if e.lower() == Entity.lower():
                return d[k]['FileName']



    currentFileName = currentFileName[:currentFileName.rfind("/")]
    if currentFileName:
        return find_entity(d,Entity, currentFileName)
    raise Exception("unable to find Entity " +Entity)


def find_used_entities(d,FileName):
    ret = list()
 
    e2 = d[FileName]['entityUSE']
    
    for r in e2:
        if "work." in r:
            r = r.replace("work.", "")
            ret.append(r)

    return ret


def find_component(d,component, currentFileName="."):

    for k in d.keys():
        if not isSubPath(currentFileName, k):
            continue
        for e in d[k]['entityDef']:
            if e.lower() == component.lower():
                return d[k]['FileName']

    

    currentFileName = currentFileName[:currentFileName.rfind("/")]
    if currentFileName:
        return find_component(d,component, currentFileName)


    print("unable to find component  " +component)
    return None

def find_used_components(d,FileName):
    ret = list()
 
    e2 = d[FileName]['ComponentUSE']
    
    for r in e2:
        r = r.replace("work.", "")
        ret.append(r)

    return ret

def isSubPath(sub, main):
    sub = sub[:sub.rfind("/")]

    return  main.startswith(sub)

def find_PacketDef(d,Entity, currentFileName="."):
    #print(Entity)
    for k in d.keys():
        if not isSubPath(currentFileName, k):
            continue

        for e in d[k]['packageDef']:
            if e.lower() == Entity.lower():
                #print(Entity , d[k]['FileName'])
                return d[k]['FileName']
    
    currentFileName = currentFileName[:currentFileName.rfind("/")]
    if currentFileName:
        return find_PacketDef(d,Entity, currentFileName)

    raise Exception("unable to find package " +Entity)




def find_used_package(d,FileName):
    ret = list()
    e1 = d[FileName]['packageUSE']

    for r in e1:
        ret.append(r)
        

    return ret


def make_depency_list(d, eneties_used, find_used_func,find_def_func):
    old_length = 0
    new_length = 1
    while (new_length > old_length):
        old_length = new_length
        new_EntitesUsed = eneties_used.copy()
        for k in eneties_used:
        
            currentFileName = new_EntitesUsed[k]
            entites_in_file = find_used_func(d,currentFileName)
            
            for e in entites_in_file:
                FileName = find_def_func(d,e,currentFileName)
                
                if FileName and ".xco" not in FileName:
                    new_EntitesUsed[e] = FileName


        new_length = len(new_EntitesUsed)
        eneties_used = new_EntitesUsed.copy()
    
    return eneties_used






