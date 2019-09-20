from  .vhdl_parser import *
from  .vhdl_get_type_def_from_db  import *
from  .vhdl_get_dependencies import *


def entity2FileName(entityName,BuildFolder = "build/",reparse=True):
        
    DataBaseFile=BuildFolder+"DependencyBD"
    if reparse:
        vhdl_parse_folder(Folder= ".",DataBaseFile=DataBaseFile)
    
    d = LoadDB(DataBaseFile) 
    entity =  find_entity(d, entityName)
    return entity