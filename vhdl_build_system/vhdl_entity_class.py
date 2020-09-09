
from .vhdl_get_type_def_from_db  import *

knownName= list()

def expand_types_records(portDef,TypeDef):
    ret = list()
    for x in TypeDef['record']:
        e = {}
        e['name'] = portDef['name'] + "." + x['name']
        e['type'] = x['type'] 
        e['InOut'] =  'in'
        e['default'] =  None
        ret.append(e)


    return ret

def input_get_constant(numStr):
    try:
        i0 = int(numStr)
    except:
        for x in knownName:
            if x["name"] == numStr.strip():
                i0 = x["value"]
                return i0


        i0 = input("unkown Variable: "+ numStr+"\nplease enter its value:")
        i0 =input_get_constant(i0)
        newName = {}
        newName["name"] = numStr.strip()
        newName["value"] = i0
        knownName.append(newName)

    return i0


def expand_types_arrays(portDef,TypeDef):
    ret = list()
    array_length = TypeDef["array_length"]
    if "range" in array_length:
        print("Unbound array")

    sp = array_length.split("downto")
    if len(sp) == 1:
         sp = array_length.split("to")
    i0 = input_get_constant(sp[0])
    i1 = input_get_constant(sp[1])
    
    max_index = max(i0,i1)

    min_index = min(i0,i1)


    
    for x in range(min_index,max_index):
        e = {}
        e['name'] = portDef['name'] + "(" + str(x) +")"
        
        e['type'] = TypeDef['BaseType']
        e['InOut'] =  'in'
        e['default'] =  None
        ret.append(e)
    return ret


def isPrimitiveType(typeName):
    if typeName == "std_logic":
        return True
    elif "std_logic_vector" in typeName:
        return True
    elif typeName == "integer":
        return True
    elif  " slv " in  " " + typeName:
        return True

    return False





def get_shortend_typename(portdef):
   
    ty = portdef["type"]
    if ty == "std_logic":
        return "sl"
    elif "std_logic_vector" in ty:
        return "slv"
    
    return ty

def set_short_hand(portdef):
    for x in portdef:
        x["type_shorthand"]=get_shortend_typename(x)

    return portdef

def remove_clock_from_ports(ports):
    ports = [x for x in ports if x["name"] != "clk"]
    ports = [x for x in ports if x["type"] != "globals_t"]
    ports = [x for x in ports if x["type"] != "system_globals"]
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
                ret.append(p)
                continue
            elif type_def["vhdl_type"] == "record":
                array = expand_types_records(p,type_def)
                for a in array:
                    ret.append(a)
            elif type_def["vhdl_type"] == "array":
                array = expand_types_arrays(p,type_def)
                for a in array:
                    ret.append(a)

            elif type_def["vhdl_type"] == "subtype":
                p["BaseType"] = type_def["BaseType"]
                p["type"] = type_def["BaseType"]
                ret.append(p)
                
    return ret


def set_default_value(ports):
    #print(ports)
    for x in ports:
        if x["default"]:
            nullValue = x["default"]
        elif x["type"] == "std_logic":
            nullValue = "'0'"
        elif "std_logic_vector" in x["type"] :
            nullValue = "(others => '0')"
        else:
            nullValue = x["type"]+"_null"
            
        x["default"]=nullValue

    return ports
        

class vhdl_entity:
    def __init__(self,entityDef):
        self.entityDef = entityDef

    def name(self):
        return self.entityDef["name"]
    
    def IsUsingGlobals(self):
        ports = self.ports()
        ports = [x for x in ports if x["type"] == "globals_t" or x["type"] == "system_globals"]
        return len(ports) > 0

        
    def get_clock_port(self):
        ports = self.entityDef["port"]
        ports = [x for x in ports if x["name"] == "clk" or x["type"] == "globals_t" or x["type"] == "system_globals"]
        return ports[0]

    def ports(self,RemoveClock=False,ExpandTypes=False, Filter = None):
        ports = self.entityDef["port"]
        ports = remove_clock_from_ports(ports)  
        if not RemoveClock:
            clk = self.get_clock_port()
            ports = [clk] + ports
            
        
        if Filter:
            ports = [x for x in ports if Filter(x)]

        if ExpandTypes:
            new_length = 100000
            old_length = len(ports)
            while new_length >  old_length:
                old_length = len(ports)
                ports = expand_types(ports)
                new_length = len(ports)
                if new_length < old_length:
                    raise Exception("ports got removed")
        

        
       
        ports = port_to_plain_text(ports)
        ports = set_short_hand(ports)
        ports = set_default_value(ports)

        return ports

