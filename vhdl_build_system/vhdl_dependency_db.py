
from .vhdl_db import saveDB, LoadDB
from .vhdl_parser import vhdl_parse_folder 

from .vhdl_get_dependencies_impl import   find_entity, find_used_entities, find_used_package, find_PacketDef, find_used_components, find_component,make_depency_list
from .generic_helper import save_file, try_make_dir, get_text_between_outtermost

class dependency_db_cl:
    def __init__(self,FileName) -> None:
        self.FileName = FileName
        self.db = LoadDB(FileName,False)
        if not self.db:
            self.reparse_files()

    def reparse_files(self):
        saveDB(self.FileName, LoadDB(self.FileName,True))
        self.save(vhdl_parse_folder(self.db))


    def save(self,db =None):
        if db:
            self.db = db
        
        saveDB(self.FileName, self.db)
        
    def get_package_for_type(self, name):
        n_sp = name.split("(")
        plainName = n_sp[0].strip()
        if len(n_sp) >1:
            print(n_sp[0],"is array type")

        for k in self.db.keys():
            t = self.db[k]["Type_Def_detail"]
            e = self.db[k]["entityDef"]
            if not e:
                for t1 in t:
                    if t1["name"] == plainName:
                        return self.db[k]
                           
    def get_type_from_name(self, name):
        n_sp = name.split("(")
        plainName = n_sp[0].strip()

        for k in self.db.keys():
            t = self.db[k]["Type_Def_detail"]
            e = self.db[k]["entityDef"]
            if not e:
                for t1 in t:
                    if t1["name"] == plainName:
                        if len(n_sp) == 1:
                            return t1
                        else:
                            #unbound array type 
                            base = self.get_type_from_name(plainName)
                            ret = {
                                "name"    : plainName,
                                "BaseType": base["BaseType"],
                                "array_length" : get_text_between_outtermost(name,'(',')'),
                                "vhdl_type"    :  "array"
                            }
                            return ret

    def entity2FileName(self, entityName):
        entity =  find_entity(self.db , entityName)
        return entity




    def get_dependencies(self, Entity):
        
        d = self.db
        TB_entity = Entity
        eneties_used ={}
      
        eneties_used[TB_entity] = find_entity(d,TB_entity,".")

        old_length = 0
        new_length = 1
        while (new_length > old_length):
            old_length = new_length
            eneties_used = make_depency_list(d,eneties_used ,find_used_entities,find_entity)
            eneties_used = make_depency_list(d,eneties_used ,find_used_package,find_PacketDef)
            eneties_used = make_depency_list(d,eneties_used ,find_used_components,find_component)
            new_length = len(eneties_used)

        fileList=list()
        for k in eneties_used:
            FileName =eneties_used[k].replace("\\","/") 
            if FileName not in fileList:
                fileList.append(FileName)
            else:
                print("doublication "+ FileName)

        self.save(d)
        return fileList   

            
    def get_dependencies_and_make_project_file(self,Entity,OutputFile=None):
        
        
        fileList = self.get_dependencies(Entity)
        
        if not OutputFile:
            OutputFile =  "build/" +Entity+"/"+Entity+".prj"
            outPath = "build/" +Entity
        
        try_make_dir(outPath)
         
        lines = ""
        for k in fileList:
            lines += 'vhdl work "../../' + k + '"\n'
        save_file(OutputFile, lines)
        
        return fileList



     

dependency_db = dependency_db_cl(FileName= "build/DependencyBD" )



