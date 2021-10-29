import os
from shutil import copyfile
import pandas as pd
import argparse

def Convert2CSV123(XlsFile,Sheet,OutputFile,drop):

    data_xls = pd.read_excel(XlsFile, Sheet, index_col=None)
    print(data_xls.columns)
    #if drop:
    #    data_xls = data_xls.drop(['globals_clk', 'globals_rst', 'globals_reg_address', 'globals_reg_value', 'globals_reg_new_value'],axis=1 )
    data_xls.to_csv(OutputFile, encoding='utf-8',index =False, sep=" ") 



def main():
    parser = argparse.ArgumentParser(description='Excel To CSV Converter')
    parser.add_argument('--OutputCSV',    help='Path to the output',default="test.csv")
    parser.add_argument('--InputXLS',   help='Path to the input file',default="TXWaveFormOutputCompact.xlsm")
    parser.add_argument('--SheetXLS',   help='Sheet inside the XLS file',default="Simulation_Input")
    #parser.add_argument('--Drop',   help='drops columns from data frame',default='globals_clk,globals_rst,globals_reg_address,globals_reg_value,globals_reg_new_value')
    parser.add_argument('--ExportFor',   help='simulation or hardware',default='simulation')

    args = parser.parse_args()
    drop = args.ExportFor == "hardware"
    print("\nargs.InputXLS: ",args.InputXLS,"\nargs.SheetXLS",args.SheetXLS,"\nargs.OutputCSV",args.OutputCSV)
    if args.InputXLS.split(".")[-1].lower() == "csv":
        #skip converting just copying
        copyfile( args.InputXLS , args.OutputCSV)
    else:
        Convert2CSV123(args.InputXLS,args.SheetXLS,args.OutputCSV,drop)
    print("done Converting")

if __name__== "__main__":
    main()
