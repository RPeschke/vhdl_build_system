import os
import pandas as pd

def first_diff_between_strings(x,y):
    for i in range(min(len(x),len(y))):
        if x[i] != y[i]:
            return i
                
    return min(len(x),len(y))
        
def remove_doublication_from_list(inList):
    ret  = list(dict.fromkeys(inList))
    return ret

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