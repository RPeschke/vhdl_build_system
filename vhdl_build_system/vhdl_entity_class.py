def isPrimitiveType(typeName):
    if typeName == "std_logic":
        return True
    elif "std_logic_vector" in typeName:
        return True
    elif typeName == "integer":
        return True

    return False

def get_shortend_typename(portdef):
   
    ty = portdef["type"]
    if ty == "std_logic":
        return "sl"
    elif "std_logic_vector" in ty:
        return "slv"
    
    return ty


def remove_clock_from_ports(ports):
    ports = [x for x in ports if x["name"] != "clk"]
    return ports

def port_to_plain_text(ports):

    for x in ports:
        portName = x["name"] 
        x["plainName"] = portName.replace(".","_").replace("(","_").replace(")","")
    return ports

def expand_types(ports):
    ret = list()
    for p in ports:
        if isPrimitiveType(p["type"]):
            ret.append(p)
        else:
            type_def = get_type_from_name(p["type"])
            
            if type_def == None:
                continue
            elif type_def["vhdl_type"] == "record":
                array = expand_types_records(p,type_def)
                for a in array:
                    ret.append(a)
            elif type_def["vhdl_type"] == "array":
                array = expand_types_arrays(p,type_def)
                for a in array:
                    ret.append(a)
        
        p["type_shorthand"]=get_shortend_typename(p)
                
    return ret

class vhdl_entity:
    def __init__(self,entityDef):
        for x in entityDef["port"]:
            if x["default"]:
                nullValue = x["default"]
            elif x["type"] == "std_logic":
                nullValue = "'0'"
            elif "std_logic_vector" in x["type"] :
                nullValue = "(others => '0')"
            else:
                nullValue = x["type"]+"_null"
            
            x["default"]=nullValue

        self.entityDef = entityDef

    def name(self):
        return self.entityDef["name"]

    def ports(self,RemoveClock=False,ExpandTypes=False, Filter = None):
        ports = self.entityDef["port"]
        if RemoveClock:
            ports = remove_clock_from_ports(ports)  
        
        if Filter:
            ports = [x for x in ports if Filter(x)]

        if ExpandTypes:
            ports = expand_types(ports)  
        

        
       
        ports = port_to_plain_text(ports)

        return ports

