from  .vhdl_load_file_without_comments import load_file_witout_comments
from .generic_helper import get_text_between_outtermost


import pandas as pd

        

def split_port_entries(ports):
    ports = ports.split(";")
    ports = list(filter(None, ports))
    ret = list()
    for x in ports:
        x= x.strip()
        if not x: 
            continue
        entry = {}
        sp = x.split(":")
        if len(sp) == 2:
            entry["name"] = sp[0].strip()
            sp1 = sp[1].strip().split(" ")
            sp1 = list(filter(None, sp1)) 
            if sp1[0] in "in out input":
                entry["type"] = " ".join(sp1[1:])
                entry["InOut"] = sp1[0]
                entry["default"] = ""
            else:
                entry["type"] = " ".join(sp1[0:])
                entry["InOut"] = "in"
                entry["default"] = ""


        elif len(sp) == 3:
            entry["name"] = sp[0].strip()
            sp1 = sp[1].strip().split(" ")
            sp1 = list(filter(None, sp1)) 
            if sp1[0] in "in out input":
                entry["type"] = " ".join(sp1[1:])
                entry["InOut"] = sp1[0]
                entry["default"] = x.split(":=")[1].strip()
            else:             
            
                entry["type"] = " ".join(sp1[0:])
                entry["InOut"] = "in"
                entry["default"] = x.split(":=")[1].strip()
            


        else:
            raise Exception("unexpected length")\

        ret.append(entry)

        

    return ret


        
def get_list(Entity_def, listName):
    ListCandidate = Entity_def.split(listName)
    if len(ListCandidate) < 2:
        return []
    
    ListCandidate = ListCandidate[1]
    ListCandidate= get_text_between_outtermost(ListCandidate,'(',')')
    ListCandidate = split_port_entries(ListCandidate)
    return ListCandidate
  

def entity_def_to_dataframe(entity_list):
    ret = []
    for x in entity_list:
        for y in x["generic"]:
            ret.append([x["name"].strip(),"generic", y['name'].strip() , y['type'].strip()   , y['InOut'].strip()   , y['default'].strip()  ] )
        for y in x["port"]:
            ret.append([x["name"].strip(),"port", y['name'].strip() , y['type'].strip()   , y['InOut'].strip()   , y['default'].strip()       ] )   
            
    ret = pd.DataFrame(ret, columns=["entity_name","generic_or_port","port_name","port_type","InOut","default"])
             
    return ret

def vhdl_get_entity_def(FileName):

    fc = load_file_witout_comments(FileName)
    candidates =  fc.split("entity")
    entity_list = list()
    for x in candidates:
        ret = {}
        words = x.strip().split(" ")
        words = list(filter(None, words)) 
        if len(words)  > 1  and  "is" in words[1]:
            ret["name"] = words[0]
            full_entity = x.split(" end ")[0]
        

            generic = get_list(full_entity," generic ")
            ret["generic"] = generic

            ports = get_list(full_entity," port ")
            ret["port"] = ports


        if len(ret) > 0:
            entity_list.append(ret)
    r = entity_def_to_dataframe(entity_list)
    return entity_list, r








        

