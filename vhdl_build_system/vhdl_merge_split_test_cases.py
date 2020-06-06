import xml.etree.ElementTree as ET
import os,sys,inspect
import os
from shutil import copyfile
import pandas as pd


def Convert2CSV(XlsFile,Sheet,OutputFile):

    data_xls = pd.read_excel(XlsFile, Sheet, index_col=None)

    data_xls.to_csv(OutputFile, encoding='utf-8',index =False)


def load_file(fileName):
    with open(fileName) as f:
        return f.read() 

def save_file(fileName,Data):
    Data = Data.replace("\n","\r\n")
    with open(fileName,"w", newline = "") as f:
        return f.write(Data) 

def merge_test_case(InputTestCase,SkipHeader1 = False):
    tree = ET.parse(InputTestCase)
    root = tree.getroot()
    dirName = os.path.dirname(InputTestCase)
    

    Stimulus  = load_file(dirName +"/"+ root[0].find('inputfile').text)
    if SkipHeader1:
        Stimulus = Stimulus[Stimulus.find("\n") + 1:]
    root[0].find('Stimulus').text = Stimulus
    Reference = load_file(dirName +"/"+ root[0].find('referencefile').text)
    Reference = Reference.replace(",",";")
    root[0].find('Reference').text = Reference
    tree.write(InputTestCase)
    os.remove(dirName +"/"+ root[0].find('inputfile').text) 
    os.remove(dirName +"/"+ root[0].find('referencefile').text) 


def merge_test_case_excel(InputTestCase,ExcelFile):
    tree = ET.parse(InputTestCase)
    root = tree.getroot()
    dirName = os.path.dirname(InputTestCase)

    Convert2CSV(ExcelFile,"Simulation_Input" , dirName+ "/"  + root[0].find('inputfile').text)
    Convert2CSV(ExcelFile,"Simulation_output", dirName+ "/"  + root[0].find('referencefile').text)
    
    
    #merge_test_case(InputTestCase,True)
    merge_test_case(InputTestCase)

def split_test_case(InputTestCase):
    tree = ET.parse(InputTestCase)
    root = tree.getroot()
    dirName = os.path.dirname(InputTestCase)
    

    Stimulus  = root[0].find('Stimulus').text  
    save_file(dirName +"/"+ root[0].find('inputfile').text, Stimulus)
    
    Reference = root[0].find('Reference').text
    save_file(dirName +"/"+ root[0].find('referencefile').text, Reference)
    
    
    



    





