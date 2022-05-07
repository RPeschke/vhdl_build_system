import os

import pandas as pd

from .vhdl_get_list_of_files import getListOfFiles



from .vhdl_get_type_def import vhdl_get_type_def_from_string

from .vhdl_load_file_without_comments import load_file_witout_comments







def vhdl_parse_xco(FileName, ret1):
    ret = {}
    ret["FileName"] = FileName
    Modified= os.path.getmtime(FileName)
    baseName = FileName.split("/")[-1].split(".xco")[0]
    #print(baseName)
    entities_def=[]
    entities_def.append(baseName)
    ret["entityDef"]= entities_def
    ret["Type_Def"] = []
    ret["Type_Def_detail"]=[]
    ret["packageDef"]=[]
    ret["packageUSE"]=[]
    ret["entityUSE"]=[]
    ret["ComponentUSE"]=[]
    ret["Modified"] = []

    ret1["symbols"].extend(  [ [ FileName , "entityDef", baseName, Modified ] ] )
    return ret


def vhdl_parser(FileName, ret1={}):
    
    ret = {}
    ret["FileName"] = FileName
    Modified= os.path.getmtime(FileName)
    ret["Modified"] = Modified
    FileContent=load_file_witout_comments(FileName)
    
    entityDef=findDefinitionsInFile(FileContent,"entity","is")
    ret["entityDef"]=entityDef
    ret1["symbols"].extend(  [ [ FileName , "entityDef", x,Modified ]   for x in entityDef ] )
    
    Type_Def=findDefinitionsInFile(FileContent,"type","is")
    subType_Def=findDefinitionsInFile(FileContent,"subtype","is")
    ret["Type_Def"]=Type_Def + subType_Def
    
    ret1["symbols"].extend(  [ [ FileName , "Type_Def", x,Modified ]   for x in Type_Def + subType_Def ] )


    type_def_detail = vhdl_get_type_def_from_string(FileContent)
    ret["Type_Def_detail"]=type_def_detail
    
    #for x in type_def_detail:
    #    for y in x["record"]:
    #        ret1["records"].extend(  [ [ FileName ,  x["vhdl_type"], x["name"],y["type"] ,y["name"], Modified ]  ]  )
            
    ret1["symbols"].extend(  [ [ FileName , "Type_Def_detail", x["name"],Modified ]   for x in type_def_detail  ] )

    packageDef=findDefinitionsInFile(FileContent,"package","is")
    ret["packageDef"]=packageDef
    ret1["symbols"].extend(  [ [ FileName , "packageDef", x , Modified]   for x in packageDef  ] )

    packageUSE=findDefinitionsInFile(FileContent,"work.","all",".")
    ret["packageUSE"]=packageUSE
    
    ret1["symbols"].extend(  [ [ FileName , "packageUSE", x , Modified]   for x in packageUSE  ] )



    entityUSE_G=findDefinitionsInFile(FileContent,"entity","generic")
    entityUSE=findDefinitionsInFile(FileContent,"entity","port")
    entityUSE2=findDefinitionsInFile(FileContent,"entity","(")
    ret["entityUSE"]=entityUSE + entityUSE_G +entityUSE2
    ret1["symbols"].extend(  [ [ FileName , "entityUSE", x,Modified ]   for x in entityUSE + entityUSE_G +entityUSE2  ] )
    
    ComponentUSE=findDefinitionsInFile(FileContent,"component","is")
    ComponentUSE_G=findDefinitionsInFile(FileContent,"component","generic")
    ComponentUSE_P=findDefinitionsInFile(FileContent,"component","port")
    ret["ComponentUSE"]=ComponentUSE +ComponentUSE_G +ComponentUSE_P
    ret1["symbols"].extend(  [ [ FileName , "ComponentUSE", x ,Modified]   for x in ComponentUSE +ComponentUSE_G +ComponentUSE_P  ] )
    
    return ret


def findDefinitionsInFile(FileContent,prefix,suffix,delimiter=" ",offset = 0):
    ret=[]
    
    entity_cantidates = FileContent.split(prefix)
    for x in entity_cantidates[1:]:
        
        words = x.strip().split(delimiter)
        words = list(filter(None, words)) 
        if len(words)  > 1 + offset and   suffix in words[1 +offset][0:10] and words[0 +offset].strip() not in ret:
            ret.append(words[0 +offset].strip())
            
    
    return ret




def vhdl_parse_folder(database, Folder = "."):
    ret1 ={
        "symbols" : [],
        "records": [],
        "subtypes" : [],
        
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
            #print(f)

            
        print("process file: ",f)
        ret= vhdl_parser(f,ret1)
        database[f] = ret
    
    flist = getListOfFiles(Folder,"*.xco*")
    for f in flist:
        if "build/" not in f:
            ret = vhdl_parse_xco(f,ret1)
            #print(f)
            database[f] = ret
    

    df = pd.DataFrame(ret1["symbols"], columns = ["filename","type","name", "data"])
    df["name"] = df.apply(lambda x: x["name"].replace("work.",""), axis=1)
    print ( '</vhdl_parse_folder>')
    return database,df


