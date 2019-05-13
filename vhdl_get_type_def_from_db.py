import shelve

import os
import fnmatch, re

BuildFolder = 'build/'
DataBaseFile=BuildFolder+"DependencyBD"

def get_type_from_name(name):
    d = shelve.open(DataBaseFile) 
    for k in d.keys():
        t = d[k]["Type_Def_detail"]
        e = d[k]["entityDef"]
        if not e:
            for t1 in t:
                if t1["name"] == name:
                    return t1
                

def main():
    ret = get_type_from_name("fifo_nativ_write_32_m2s")
    print(ret)


if __name__== "__main__":
    main()