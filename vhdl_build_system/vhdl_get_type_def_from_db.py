
import os
import fnmatch, re
from  .vhdl_db                import *

BuildFolder = 'build/'
DataBaseFile=BuildFolder+"DependencyBD"

def get_type_from_name(name):
    
    d = LoadDB(DataBaseFile) 
    for k in d.keys():
        t = d[k]["Type_Def_detail"]
        e = d[k]["entityDef"]
        if not e:
            for t1 in t:
                if t1["name"] == name:
                    return t1
                

