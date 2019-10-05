
import os
import fnmatch, re
from  .vhdl_db                import *
from .vhdl_get_entity_def    import *

BuildFolder = 'build/'
DataBaseFile=BuildFolder+"DependencyBD"


def get_package_for_type(name):
    d = LoadDB(DataBaseFile) 
    n_sp = name.split("(")
    plainName = n_sp[0].strip()
    if len(n_sp) >1:
        print(n_sp[0],"is array type")

    for k in d.keys():
        t = d[k]["Type_Def_detail"]
        e = d[k]["entityDef"]
        if not e:
            for t1 in t:
                if t1["name"] == plainName:
                    return d[k]
                    


def get_type_from_name(name):
    
    d = LoadDB(DataBaseFile) 
    n_sp = name.split("(")
    plainName = n_sp[0].strip()
    #if len(n_sp) >1:
    #    print(n_sp[0],"is array type")

    for k in d.keys():
        t = d[k]["Type_Def_detail"]
        e = d[k]["entityDef"]
        if not e:
            for t1 in t:
                if t1["name"] == plainName:
                    if len(n_sp) == 1:
                        return t1
                    else:
                        #unbound array type 
                        base = get_type_from_name(plainName)
                        ret = {
                            "name"    : plainName,
                            "BaseType": base["BaseType"],
                            "array_length" : get_text_between_outtermost(name,'(',')'),
                            "vhdl_type"    :  "array"
                        }
                        return ret

                
