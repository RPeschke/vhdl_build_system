import os
import shelve
import fnmatch, re



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


def vhdl_get_dependencies(Entity,OutputFile=None,DataBaseFile="build/DependencyBD"):
    if not OutputFile:
        OutputFile =  "build/" +Entity+"/"+Entity+".prj"
        outPath = "build/" +Entity
    
    try_make_dir(outPath)
    
    d = shelve.open(DataBaseFile)
    TB_entity = Entity
    eneties_used ={}
    eneties_used[TB_entity] = find_entity(d,TB_entity)
    eneties_used = make_depency_list(d,eneties_used ,find_used_entities,find_entity)
    eneties_used = make_depency_list(d,eneties_used ,find_used_package,find_PacketDef)

    lines =""
    

    with open(OutputFile,'w') as f:
        for k in eneties_used:
            lines = 'vhdl work "../../' + eneties_used[k].replace("\\","/") + '"\n'
            f.write(lines)





def find_entity(d,Entity):
    for k in d.keys():
        for e in d[k]['entityDef']:
            if e.lower() == Entity.lower():
                return d[k]['FileName']

    raise Exception("unable to find Entity " +Entity)

def find_used_entities(d,FileName):
    ret = list()
 
    e2 = d[FileName]['entityUSE']
    
    for r in e2:
        if "work." in r:
            r = r.replace("work.", "")
            ret.append(r)
    return ret



def find_PacketDef(d,Entity):
    for k in d.keys():
        for e in d[k]['packageDef']:
            if e.lower() == Entity.lower():
                return d[k]['FileName']

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
            entites_in_file = find_used_func(d,new_EntitesUsed[k])
            
            for e in entites_in_file:
                new_EntitesUsed[e] = find_def_func(d,e)

        new_length = len(new_EntitesUsed)
        eneties_used = new_EntitesUsed.copy()
    
    return eneties_used






