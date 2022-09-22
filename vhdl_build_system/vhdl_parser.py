from asyncio import constants
import os

import pandas as pd

from .vhdl_get_list_of_files import getListOfFiles



from .vhdl_get_type_def import vhdl_get_type_def_from_string

from .vhdl_load_file_without_comments import load_file_witout_comments

from .generic_helper import get_text_between_outtermost





def vhdl_parse_xco(FileName, ret1):
    Modified= os.path.getmtime(FileName)
    baseName = FileName.split("/")[-1].split(".xco")[0]
    entities_def=[]
    entities_def.append(baseName)

    ret1["symbols"].extend(  [ [ FileName , "entityDef", baseName, Modified ] ] )
    

def extract_baseType(typestr):
    sp =typestr.split("(")
    basetype = sp[0].strip()
    if len(sp) == 1:
        return basetype,"","",""
    sp_downto = get_text_between_outtermost(typestr,'(',')').split(" downto ")
    if len(sp_downto) > 1:
        return basetype,"downto",sp_downto[0].strip(),sp_downto[1].strip()
    
    sp_to = get_text_between_outtermost(typestr,'(',')').split(" to ")     
    
    if len(sp_to) > 1:
        return basetype,"to",sp_to[0].strip(),sp_to[1].strip()

    sp_unbound = get_text_between_outtermost(typestr,'(',')')
    if len(sp_unbound) > 1:
        return basetype,sp_unbound[0].strip(),"",""
    
    return "","","",""
    
    
def vhdl_parser_types_array(FileName, x, ret1):
    sub_basetype,sub_direction,sub_first,sub_second =  extract_baseType(x["BaseType"])

    basetype = x["BaseType"]+"  (  " + x["array_length"] +"  )  "
    if len(sub_direction) > 0:
        ret1["records"].extend(  [ [ FileName , "temp", x["name"]+"$temp" ,x["BaseType"] ,"" ,sub_basetype,sub_direction,sub_first,sub_second  ]  ]  )     
        basetype = x["name"]+"$temp" +"  (  " + x["array_length"] +"  )  "
        
    
    main_basetype,main_direction,main_first,main_second =  extract_baseType(basetype)
    ret1["records"].extend(  [ [ FileName ,  x["vhdl_type"], x["name"],basetype,"" ,main_basetype,main_direction,main_first,main_second  ]  ]  )     

def vhdl_parser_types(FileName, ret1):
    FileContent=load_file_witout_comments(FileName)
    type_def_detail = vhdl_get_type_def_from_string(FileContent)
    for x in type_def_detail:
        if x["vhdl_type"] == "record":
            for y in x["record"]:
                basetype,direction,first,second =  extract_baseType(y["type"])
                ret1["records"].extend(  [ [ FileName ,  x["vhdl_type"], x["name"],y["type"] ,y["name"], basetype,direction,first,second ]  ]  )
        elif x["vhdl_type"] == "enum":
            for y in x["record"]:
                basetype,direction,first,second =  extract_baseType(y["type"])
                ret1["records"].extend(  [ [ FileName ,  x["vhdl_type"], x["name"],y["type"] ,y["name"],basetype,direction,first,second ]  ]  )                
        elif x["vhdl_type"] == "array":
            vhdl_parser_types_array(FileName, x, ret1)

        elif x["vhdl_type"] == "subtype":
            basetype,direction,first,second =  extract_baseType(x["BaseType"])
            ret1["records"].extend(  [ [ FileName ,  x["vhdl_type"], x["name"],x["BaseType"],"",basetype,direction,first,second ]  ]  )                 
        else:
            raise Exception("Unknown type")

def vhdl_parser_constants(FileName, ret1):
    FileContent=load_file_witout_comments(FileName)   
    consts = FileContent.split("constant")[1:]     
    for x in consts:
        x = x.split(";")[0].strip()
        sp = x.split(":")
        
        try:
            ret1["constants"].extend(  [ [ FileName ,  sp[0].strip() , sp[1].strip(), sp[2][1:].strip() ]  ]  )
        except:
            print("Error in reading constants in file: " + FileName)
    
            
def vhdl_parser(FileName, ret1={}):
    
    
    
    Modified= os.path.getmtime(FileName)
    
    FileContent=load_file_witout_comments(FileName)
    
    entityDef=findDefinitionsInFile(FileContent,"entity","is")
    
    ret1["symbols"].extend(  [ [ FileName , "entityDef", x,Modified ]   for x in entityDef ] )
    
    Type_Def=findDefinitionsInFile(FileContent,"type","is")
    subType_Def=findDefinitionsInFile(FileContent,"subtype","is")
    
    
    ret1["symbols"].extend(  [ [ FileName , "Type_Def", x,Modified ]   for x in Type_Def + subType_Def ] )


    type_def_detail = vhdl_get_type_def_from_string(FileContent)
    
    vhdl_parser_types(FileName, ret1)
    vhdl_parser_constants(FileName, ret1)
    #for x in type_def_detail:
    #    for y in x["record"]:
    #        ret1["records"].extend(  [ [ FileName ,  x["vhdl_type"], x["name"],y["type"] ,y["name"], Modified ]  ]  )
            
    ret1["symbols"].extend(  [ [ FileName , "Type_Def_detail", x["name"],Modified ]   for x in type_def_detail  ] )

    packageDef=findDefinitionsInFile(FileContent,"package","is")
    
    ret1["symbols"].extend(  [ [ FileName , "packageDef", x , Modified]   for x in packageDef  ] )

    packageUSE=findDefinitionsInFile(FileContent,"work.","all",".")
    
    
    ret1["symbols"].extend(  [ [ FileName , "packageUSE", x , Modified]   for x in packageUSE  ] )



    entityUSE_G=findDefinitionsInFile(FileContent,"entity","generic")
    entityUSE=findDefinitionsInFile(FileContent,"entity","port")
    entityUSE2=findDefinitionsInFile(FileContent,"entity","(")
    
    ret1["symbols"].extend(  [ [ FileName , "entityUSE", x,Modified ]   for x in entityUSE + entityUSE_G +entityUSE2  ] )
    
    ComponentUSE=findDefinitionsInFile(FileContent,"component","is")
    ComponentUSE_G=findDefinitionsInFile(FileContent,"component","generic")
    ComponentUSE_P=findDefinitionsInFile(FileContent,"component","port")
    
    ret1["symbols"].extend(  [ [ FileName , "ComponentUSE", x ,Modified]   for x in ComponentUSE +ComponentUSE_G +ComponentUSE_P  ] )
    
    


def findDefinitionsInFile(FileContent,prefix,suffix,delimiter=" ",offset = 0):
    ret=[]
    
    entity_cantidates = FileContent.split(prefix)
    for x in entity_cantidates[1:]:
        
        words = x.strip().split(delimiter)
        words = list(filter(None, words)) 
        if len(words)  > 1 + offset and   suffix in words[1 +offset][0:10] and words[0 +offset].strip() not in ret:
            ret.append(words[0 +offset].strip())
            
    
    return ret




def vhdl_parse_folder( Folder = ".", verbose = False):
    ret1 ={
        "symbols" : [],
        "records": [],
        "constants": []
    }
    print ( '<vhdl_parse_folder FolderName="'+ Folder +'">')

    print ( '  <getListOfFiles> ')
    flist = getListOfFiles(Folder,"*.vhd")

    print ( '  </getListOfFiles> ')

    for f in flist:
        if "build/" in f:
            continue
        
        if "verif/" in f:
            continue


        if verbose:    
            print("process file: ",f)
        
        vhdl_parser(f,ret1)

    flist = getListOfFiles(Folder,"*.xco*")
    for f in flist:
        if "build/" not in f:
            vhdl_parse_xco(f,ret1)

    

    df = pd.DataFrame(ret1["symbols"], columns = ["filename","type","name", "data"])
    df["name"] = df.apply(lambda x: x["name"].replace("work.",""), axis=1)
     
    df_records = pd.DataFrame(ret1["records"], columns = ["FileName" ,  "vhdl_type", "top_name","sub_type" ,"sub_name" ,"basetype" ,"direction" ,"first" ,"second" ])
    df_constants = pd.DataFrame(ret1["constants"], columns = ["FileName" ,   "constant_name", "top_name" ,"default" ])
    
    print ( '</vhdl_parse_folder>')
    return df,df_records,df_constants


