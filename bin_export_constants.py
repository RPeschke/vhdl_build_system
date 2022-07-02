
import pandas as pd
#from  dataframe_helpers.group_apply import group_apply

import dataframe_helpers as dfh



df = pd.read_pickle("build/DependencyBD.pkl")
df_constants =  pd.read_pickle("build/DependencyBD_constants.pkl")
df_records =  pd.read_pickle("build/DependencyBD_records.pkl")
df["FileName"] = df["filename"]
df = df.drop(["filename"], axis=1)
df1 = df_constants.merge( df[df.type== "packageDef"][["FileName"]], on ="FileName" )
x= df1[df1.top_name == "integer"].iloc[0]
df2 =  df1[df1.top_name == "integer"]
df2["class_name"] = df2.apply(lambda x: "f_" + x["FileName"].replace("/","_").replace(".","_").replace("-","_"), axis=1)

df2["constv"] = df2.apply(lambda x: x["constant_name"] +" = "+ x["default"], axis=1)

class_name = "f_" + x["FileName"].replace("/","_").replace(".","_").replace("-","_")
constv  = x["constant_name"] +" = "+ x["default"]


def f1(x):
    ret = "class "+ x.iloc[0]["class_name"] +":\n" 
    for i in range(len(x["constv"])):
        ret +=  "  "+ x.iloc[i]["constv"] + "\n"
        
    return ret


df123 = dfh.group_apply(df2, "class_name" , ["class_def"] , f1)


df2 = df2.groupby("class_name").apply(f1 )
output_axis = ["class_def"]
dummyVariableName = 'internal_dummy_name'
df3 = df2.reset_index(name=dummyVariableName)
df3[output_axis ] = pd.DataFrame(df3[dummyVariableName].to_list(), columns=output_axis )
print(df_constants)



class  vhdl_build_system_vhdl_csv_io_text_io_import_csv:
    num_col = 60
    class test1:
        num_2 = 123
    
print(vhdl_build_system_vhdl_csv_io_text_io_import_csv.num_col)
print(vhdl_build_system_vhdl_csv_io_text_io_import_csv.test1.num_2)