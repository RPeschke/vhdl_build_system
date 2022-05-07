
import pandas as pd
from copyreg import pickle
from .vhdl_db import saveDB, LoadDB
from .vhdl_parser import vhdl_parse_folder 


from .generic_helper import save_file, try_make_dir, get_text_between_outtermost

class dependency_db_cl:
    def __init__(self,FileName) -> None:
        self.FileName = FileName
        self.db = LoadDB(FileName,False)
        self.df = pd.read_pickle(self.FileName + ".pkl")
        if not self.db:
            self.reparse_files()

    def reparse_files(self):
        saveDB(self.FileName, LoadDB(self.FileName,True))
        database,df =  vhdl_parse_folder(self.db)
        self.save(database)
        df.to_pickle(self.FileName + ".pkl")
        
        


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
        entity =  self.df[ (self.df["name"] == entityName) & ( self.df["type"] == "entityDef" )][0]
        return entity




    def get_dependencies(self, Entity):
        def first_diff(x,y):
            for i in range(min(len(x),len(y))):
                if x[i] != y[i]:
                    return i
                
            return min(len(x),len(y))
        
        
        df_entity_def = self.df[self.df["type"] == "entityDef"]
        df_packageDef  = self.df[(self.df["type"] == "packageDef")]
        
        df_entities_USED = self.df[(self.df["type"] == "entityUSE")] 
        df_packageUSE = self.df[(self.df["type"] == "packageUSE")] 
        df_component_USED = self.df[(self.df["type"] == "ComponentUSE")] 
        
        
        def get_dependencies_recursive(df_used,df_def, df_fileNames):
            df_new_entities_old = pd.merge(df_used, df_fileNames, on="filename")
            df_new_entities_new = pd.merge(df_def, df_new_entities_old, how="right", on="name")
            if len(df_new_entities_new) == 0:
                return df_new_entities_old[["name"]]
            df_new_entities_new["first_diff"] = df_new_entities_new.apply(lambda x: first_diff(x["filename_x"],x["filename_y"])  , axis=1) 
            df_new_entities_new = df_new_entities_new.sort_values("first_diff",ascending=False).drop_duplicates("name")
            df_new_entities_new["filename"]= df_new_entities_new["filename_x"]
            return pd.concat([df_new_entities_old, pd.merge(df_used,  df_new_entities_new[["filename"]],  on="filename")]) [["name"]]
            
            
        def get_dependencies_recursive_full(df_used,df_def, df_find_entity_main):
            df_find_entity = df_find_entity_main
            new_length1 = len(df_find_entity)
            old_length1 = 0
            while new_length1 > old_length1:
                df_new_entities_new = get_dependencies_recursive(df_used,df_def,  df_find_entity[["filename"]] )
                df_find_entity = pd.merge(df_def, df_new_entities_new,on="name")
                df_find_entity.drop_duplicates("filename",inplace=True)
                old_length1 = new_length1
                df_find_entity = pd.concat([df_find_entity_main, df_find_entity])
                new_length1 = len(df_find_entity)
            
            df_find_entity.drop_duplicates("filename",inplace=True)     
            return df_find_entity
                
        df_find_entity_main = df_entity_def[df_entity_def["name"] == Entity].iloc[:1]
        
        df_find_entity = get_dependencies_recursive_full(df_entities_USED,    df_entity_def, df_find_entity_main)
        df_find_entity = get_dependencies_recursive_full(df_component_USED,   df_entity_def, df_find_entity)
        df_find_entity = get_dependencies_recursive_full(df_packageUSE,       df_packageDef, df_find_entity)
        
      
        return df_find_entity["filename"].tolist()   

            
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



