import os
import pandas as pd



def __read_first_line__(fileName):
    with open(fileName) as f:
        return f.readline()

class vhdl_run_csv:
    def __init__(self, entity_name , input_header=None):
        self.entity_name = entity_name
        self.InputCSV = "build/"+entity_name+"/" +entity_name+".csv" 
        self.OutputCSV = "build/"+entity_name+"/" +entity_name+"_out.csv" 
        input_header = __read_first_line__(self.InputCSV).strip() if input_header is None else input_header
        self.input_header = input_header
        self.input_header_sp = [x.strip() for x in  input_header.split(' ')]
        
        
        self.f =  open(self.InputCSV, "w")
        self.f.write(self.input_header+"\n")
        self.f.write(self.input_header+"\n")
        self.fun = {}
        self.df_out = None 
        
    def add_fun(self, column , fun):
        self.fun[column] = fun
        
    def append_empty_rows(self, rows):
        ret =""

        for ind in range(rows):
            for x in self.input_header_sp:
                if  x in self.fun.keys():
                    ret+= " " +str(self.fun[x](ind)) + " "
                    continue 
                    
                ret+= " 0 "
            ret += "\n"   
            
        self.f.write(ret)

        
    def append(self, df,prefix=None):
        ret =""
        df = df.rename(columns = lambda x: x.lower().strip() ) 
        if prefix is not None:
            df = df.rename(columns = lambda x: prefix+"_"+x) 
            
        
        for ind in range(len(df)):
            for x in self.input_header_sp:
                if  x in self.fun.keys():
                    ret+= " " +str(self.fun[x](ind)) + " "
                    continue 
                    
                if x not in df.columns:
                    ret+= " 0 "
                    continue 
                ret+= " " +str(int(df[x].iloc[ind])) +" "
            ret += "\n"   
            
        self.f.write(ret)
        
    def close(self):
        self.f.close()


    def append_splited(self, df , split_column, empty_rows,prefix=None):
        df = df.rename(columns = lambda x: x.lower().strip() ) 
        if prefix is not None:
            rename_function = lambda x: prefix+"_"+x
            df = df.rename(columns = rename_function) 
            split_column = rename_function(split_column)
            
        for i in df[split_column].unique():
            self.append(df[df[split_column] == i])
            self.append_empty_rows(empty_rows)
       
    def run(self):
        self.close()
        self.df_out = None
        return os.system("./run_simulation.sh   " + self.entity_name )

        
        
        
    def load_output(self):
        df_out =  pd.read_csv(self.OutputCSV ,comment='#',skip_blank_lines=True ,delimiter=";" )
        df_out = df_out.rename(columns=lambda x: x.strip())
        df_out = df_out.drop("Time" ,axis =1)
        self.df_out = df_out
        return df_out
    
    def get_record(self, prefix, valid  = None, global_signals=[]):

        self.load_output()
        
        df =  self.df_out    
        hit_1d_out_l = [x for x in df.columns if prefix in x]
        
        hit_1d_out_l.extend(global_signals)
        ret = df[hit_1d_out_l]
        ret = ret.rename(columns = lambda x: x.replace(prefix + "_","").strip() if x not in global_signals else x ) 
        if valid is not None:
            ret = ret[ret[valid]>0]
            
        return ret
