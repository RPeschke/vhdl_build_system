from  .vhdl_load_file_without_comments import load_file_witout_comments
from .generic_helper import get_text_between_outtermost




        

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
                entry["default"] = None
            else:
                entry["type"] = " ".join(sp1[0:])
                entry["InOut"] = "in"
                entry["default"] = None


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
        return None
    
    ListCandidate = ListCandidate[1]
    ListCandidate= get_text_between_outtermost(ListCandidate,'(',')')
    ListCandidate = split_port_entries(ListCandidate)
    return ListCandidate
  

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
        
            #print(full_entity)
            generic = get_list(full_entity,"generic")
            ret["generic"] = generic
            #print(generic)
            ports = get_list(full_entity,"port")
            ret["port"] = ports
            #for x in ports:
            #    print(x)

        if len(ret) > 0:
            entity_list.append(ret)

    return entity_list








        

