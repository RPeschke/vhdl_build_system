
import pandas as pd
from .vhdl_parser import vhdl_parse_folder 


from .generic_helper import save_file, try_make_dir,  first_diff_between_strings

class dependency_db_cl:
    def __init__(self,FileName) -> None:
        
        self.FileName = FileName
        self.filelist =[]
        self.reparse_files()
        self.df = pd.read_pickle(self.FileName + ".pkl")
        self.df_records = pd.read_pickle(self.FileName + "_records.pkl")


    def reparse_files(self):
        df,df_records =  vhdl_parse_folder()
        df.to_pickle(self.FileName + ".pkl")
        df_records.to_pickle(self.FileName + "_records.pkl")


    def entity2FileName(self, entityName):
        entity =  self.df[ (self.df["name"] == entityName.lower()) & ( self.df["type"] == "entityDef" )]["filename"].iloc[0]
        return entity

    def get_dependencies(self, Entity):
        df = self.df
        df = df[df["filename"].apply( lambda  x: ".vhd" in x) == True]
        df_entity_def = df[df["type"] == "entityDef"]
        df_packageDef  = df[(df["type"] == "packageDef")]
        
        df_entities_USED = df[(df["type"] == "entityUSE")] 
        df_packageUSE = df[(df["type"] == "packageUSE")] 
        df_component_USED = df[(df["type"] == "ComponentUSE")] 
        
        
        def get_dependencies_recursive(df_used,df_def, df_fileNames):
            df_new_entities_old = pd.merge(df_used, df_fileNames, on="filename")
            df_new_entities_new = pd.merge(df_def, df_new_entities_old, how="right", on="name")
            if len(df_new_entities_new[df_new_entities_new.filename_x.isna()].name):
                print("unable to find entity:")
                print(df_new_entities_new[df_new_entities_new.filename_x.isna()].name)
                
            df_new_entities_new = df_new_entities_new[~df_new_entities_new.filename_x.isna()]
            
            if len(df_new_entities_new) == 0:
                return df_new_entities_old[["name"]]
            
            
            df_new_entities_new["first_diff"] = df_new_entities_new.apply(lambda x: first_diff_between_strings(x["filename_x"],x["filename_y"])  , axis=1) 
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
        
        self.filelist = df_find_entity["filename"].tolist()   
        return self.filelist

            
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
        self.filelist  = fileList
        return fileList



     

dependency_db = dependency_db_cl(FileName= "build/DependencyBD" )



