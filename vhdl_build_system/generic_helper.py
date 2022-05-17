import os
import pandas as pd
import copy

def first_diff_between_strings(x,y):
    for i in range(min(len(x),len(y))):
        if x[i] != y[i]:
            return i
                
    return min(len(x),len(y))
        


def try_make_dir(name,isRelativePath=True):
    try:
        if isRelativePath:
            abs_name = os.getcwd()+"/" +name
        else:
            abs_name = name

        os.mkdir(abs_name)
    except OSError:  
        print ("Creation of the directory %s failed" % name)
    else:  
        print ("Successfully created the directory %s " % name)




def get_text_between_outtermost(raw_text,startToken,EndToken):
    ret = ""
    
    sp = raw_text.find(startToken)
    if sp == -1:
        return ""
    TokenLevel = 1
    cut_start = sp+len(startToken)
    current_index = cut_start
    
    while TokenLevel > 0:
        startIndex = raw_text.find(startToken,current_index)
        endIndex = raw_text.find(EndToken,current_index)

        if endIndex == -1:
            raise Exception("end Token not find",raw_text)
        elif startIndex > -1 and startIndex < endIndex:
            TokenLevel+=1
            current_index = startIndex +len(startToken)

            continue
        
        elif startIndex == -1 or endIndex < startIndex:
            TokenLevel -= 1
            current_index = endIndex +len(EndToken)
            if TokenLevel == 0:
                return raw_text[cut_start:endIndex]        


def load_file(fileName):
    with open(fileName) as f:
        return f.read() 

def save_file(fileName,Data,newline="\n"):
    Data = Data.replace("\n",newline)
    with open(fileName,"w", newline = "") as f:
        return f.write(Data)                 
    
    
def expand_dataframe(df, axis):
    dummy_name = "sdadasdasdasdaweqweqewqe"
    df[dummy_name] =1
    for key in axis:
        df1 = pd.DataFrame({key: axis[key]})
        df1[dummy_name] =1
        df = df.merge(df1, on = dummy_name)
    df = df.drop(dummy_name , axis=1)
    return df       



def get_converter():
    f_values ={}
    def connect_prefex_and_name(prefix, name):
        return prefix + "." +name if prefix != "" else name
    
    def process_dict_values(ret, dic, prefix =""):
        for k in dic.keys():
            process_values(ret, dic[k],connect_prefex_and_name(prefix , k) )
            
    def process_list_values(ret, x, prefix =""):
        ret_1 =  copy.deepcopy(ret)
        pr = connect_prefex_and_name(prefix , "list")
        pr_type = connect_prefex_and_name(prefix , "type")
        for i,elem in enumerate(x):
            if i == 0:
                ret[-1][pr_type ] = type(elem).__name__
                
                process_values(ret, elem, pr )
            else:
                ret_copy = copy.deepcopy(ret_1)
                ret_copy = ret_copy[-2:]
                ret_copy[-1][pr_type] = type(elem).__name__
                process_values(ret_copy, elem, pr )
                ret.extend(ret_copy)
                
    def process_int_values(ret, x, prefix =""):
        ret[-1][prefix] = x 

    def process_str_values(ret, x, prefix =""):
        ret[-1][prefix] = x             
            
    f_values["dict"]  = process_dict_values
    f_values["int"]  = process_int_values
    f_values["str"]  = process_str_values
    f_values["list"]  = process_list_values
    return f_values


f_values = get_converter()
def process_values(ret, x, prefix =""):
    
    try:
        return f_values[type(x).__name__ ] (ret, x,prefix)
    except:
        return process_values(ret, x.__dict__,prefix)
    
    
def to_dataframe(data):
    def try_get(dic, key):
        try:
            return dic[key]
        except:
            return None        
    ret = [{}]   
    process_values(ret, data)
    columns = []
    for x in ret:
        for key in x.keys():
            if key not in columns:
                columns.append(key)
                
    print(columns)        

    data = []
    for x in ret:
        data1 = []
        for c in columns:
            data1.append(try_get(x, c ))
        data.append(data1)
            
    df = pd.DataFrame(data, columns=columns)    
    return df
