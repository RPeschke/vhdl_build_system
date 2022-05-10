import pandas as pd
from .vhdl_dependency_db  import dependency_db
from .vhdl_get_entity_def import vhdl_get_entity_def
from .generic_helper import expand_dataframe

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
   
    ty = portdef["port_type"]
    if ty == "std_logic":
        return "sl"
    elif "std_logic_vector" in ty:
        return "slv"
    
    return ty

def set_short_hand(portdef):
    portdef["type_shorthand"] = portdef.apply(get_shortend_typename, axis=1) 
    return portdef

def remove_clock_from_ports(ports):
    ports = ports[ports["port_name"] != "clk"]
    ports = ports[ports["port_type"] != "globals_t"]
    ports = ports[ports["port_type"] != "system_globals"]
    return ports

def port_to_plain_text(ports):
    ports["plainName"] = ports.apply(lambda x:  x["port_name"].replace(".","_").replace("(","_").replace(")","") , axis=1)
    return ports


def expand_types(ports):
    def expand_name(x):
        if x["vhdl_type"] == "record":
            return x["port_name"] + "." + x["sub_name"]
        if x["vhdl_type"] == "array":
            return x["port_name"] + "( " + str(x["array_index"]) +" )"
        return x["port_name"]
    
    def determine_size(x):
        def convert_to_int(int_canditate):
            try :
                int_canditate =  int(int_canditate)
                
            except:
                i0 = input("in port: " + x["port_name"]+ "\nunkown Variable: "+ int_canditate  + "\nplease enter its value:")
                int_canditate =  convert_to_int(i0)
                
            return int_canditate
        
        if x["vhdl_type"] == "array":
           first  = convert_to_int(x["first"])
           second  = convert_to_int(x["second"])
           mx = max(first,second)
           mn = min(first,second)
           return mx - mn + 1
           
           
        return 1

    

    ports["isPrimitiveType"] = ports.apply(lambda x: isPrimitiveType(x["port_type"]), axis=1)
    while sum(ports["isPrimitiveType"] == False) > 0:
        expandedports = ports[ports.isPrimitiveType==False].merge(dependency_db.df_records, left_on = "port_type" ,right_on = "top_name" )
        expandedports["array_size"] = expandedports.apply(determine_size, axis=1)
        expandedports = expand_dataframe(expandedports, {"array_index" : range( expandedports.array_size.max()) } )
        expandedports = expandedports[expandedports["array_index"] < expandedports.array_size]
        expandedports["port_name"] = expandedports.apply(expand_name, axis=1)
        expandedports["port_type"] = expandedports["sub_type"]
        expandedports["default"] = ""
        expandedports = expandedports[["entity_name","generic_or_port","port_name","port_type", 'InOut', "default", "isPrimitiveType"]]
        ports = pd.concat([ports[ports.isPrimitiveType==True],expandedports])
        ports["isPrimitiveType"] = ports.apply(lambda x: isPrimitiveType(x["port_type"]), axis=1)

    return ports


def set_default_value(ports):
    #print(ports)
    def get_default_value(x):
        if x["default"]:
            return x["default"]
        elif x["port_type"] == "std_logic":
            return  "'0'"
        elif "std_logic_vector" in x["port_type"] :
            return  "(others => '0')"
        else:
            return x["port_type"]+"_null"
                


    ports["default"] = ports.apply(get_default_value, axis=1)
    
    return ports
        

class vhdl_entity:
    def __init__(self,entityDef):
        if isinstance(entityDef, str):
            entityDef,r = vhdl_get_entity_def(entityDef)
        self.entityDef = entityDef[0]
        self.df_entity = r[r["entity_name"] == r["entity_name"].iloc[0]]

    def name(self):
        return self.df_entity["entity_name"].iloc[0]
    
    def IsUsingGlobals(self):
        df = self.df_entity[self.df_entity["generic_or_port"] == "port"]
        df = df[(df["port_type"] == "globals_t" ) | (df["port_type"] == "system_globals")]
        return len(df) > 0

        
    def get_clock_port(self):
        df = self.df_entity[self.df_entity["generic_or_port"] == "port"]
        df = df[(df["port_name"] == "clk"  )  | (df["port_type"] == "globals_t" ) | (df["port_type"] == "system_globals")]
        return df.iloc[:1]
        
    def ports(self,RemoveClock=False,ExpandTypes=False, Filter = None):
        ports = self.df_entity
        ports = remove_clock_from_ports(ports)  
        if not RemoveClock:
            clk = self.get_clock_port()
            ports = pd.concat( [clk, ports])
            
        
        if Filter:
            ports = ports[Filter(ports)]

        if ExpandTypes:
            ports = expand_types(ports)
            
        
       
        ports = port_to_plain_text(ports)
        ports = set_short_hand(ports)
        ports = set_default_value(ports)

        return ports

