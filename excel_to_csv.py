import os
from shutil import copyfile
import pandas as pd
import argparse

def Convert2CSV123(XlsFile,Sheet,OutputFile):

    data_xls = pd.read_excel(XlsFile, Sheet, index_col=None)

    data_xls.to_csv(OutputFile, encoding='utf-8',index =False)



def main():
    parser = argparse.ArgumentParser(description='Excel To CSV Converter')
    parser.add_argument('--OutputCSV',    help='Path to the output',default="test.csv")
    parser.add_argument('--InputXLS',   help='Path to the input file',default="TXWaveFormOutputCompact.xlsm")
    parser.add_argument('--SheetXLS',   help='Sheet inside the XLS file',default="Simulation_Input")
    args = parser.parse_args()
    print("\nargs.InputXLS: ",args.InputXLS,"\nargs.SheetXLS",args.SheetXLS,"\nargs.OutputCSV",args.OutputCSV)
    if args.InputXLS.split(".")[-1].lower() == "csv":
        #skip converting just copying
        copyfile( args.InputXLS , args.OutputCSV)
    else:
        Convert2CSV123(args.InputXLS,args.SheetXLS,args.OutputCSV)
    print("done Converting")

if __name__== "__main__":
    main()
