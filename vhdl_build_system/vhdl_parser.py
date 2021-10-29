import os



from .vhdl_get_list_of_files import getListOfFiles



from .vhdl_get_type_def import vhdl_get_type_def_from_string

from .vhdl_load_file_without_comments import load_file_witout_comments







def vhdl_parse_xco(FileName):
    ret = {}
    ret["FileName"] = FileName
    
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


    return ret


def vhdl_parser(FileName):
    ret = {}
    ret["FileName"] = FileName
    FileContent=load_file_witout_comments(FileName)
    
    entityDef=findDefinitionsInFile(FileContent,"entity","is")
    ret["entityDef"]=entityDef
    
    Type_Def=findDefinitionsInFile(FileContent,"type","is")
    subType_Def=findDefinitionsInFile(FileContent,"subtype","is")
    ret["Type_Def"]=Type_Def + subType_Def


    type_def_detail = vhdl_get_type_def_from_string(FileContent)
    ret["Type_Def_detail"]=type_def_detail

    packageDef=findDefinitionsInFile(FileContent,"package","is")
    ret["packageDef"]=packageDef

    packageUSE=findDefinitionsInFile(FileContent,"work.","all",".")
    ret["packageUSE"]=packageUSE



    entityUSE_G=findDefinitionsInFile(FileContent,"entity","generic")
    entityUSE=findDefinitionsInFile(FileContent,"entity","port")
    entityUSE2=findDefinitionsInFile(FileContent,"entity","(")
    ret["entityUSE"]=entityUSE + entityUSE_G +entityUSE2
    
    ComponentUSE=findDefinitionsInFile(FileContent,"component","is")
    ComponentUSE_G=findDefinitionsInFile(FileContent,"component","generic")
    ComponentUSE_P=findDefinitionsInFile(FileContent,"component","port")
    ret["ComponentUSE"]=ComponentUSE +ComponentUSE_G +ComponentUSE_P
    
    ret["Modified"] = os.path.getmtime(FileName)
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

    print ( '<vhdl_parse_folder FolderName="'+ Folder +'">')

    print ( '  <getListOfFiles> ')
    flist = getListOfFiles(Folder,"*.vhd")

    print ( '  </getListOfFiles> ')
    keys = database.keys()
    for f in flist:
        if "build/" in f:
            continue
        
        if "verif/" in f:
            continue
            #print(f)
        if f in keys:
            modTime_file = os.path.getmtime(f)
            modFile_db = database[f]["Modified"]
            
            if modTime_file == modFile_db:
                continue
            
        print("process file: ",f)
        ret= vhdl_parser(f)
        database[f] = ret
    
    flist = getListOfFiles(Folder,"*.xco*")
    for f in flist:
        if "build/" not in f:
            ret = vhdl_parse_xco(f)
            #print(f)
            database[f] = ret
    

    
    print ( '</vhdl_parse_folder>')
    return database


