
def get_status(xnode):
    if xnode["IsDifferent"]:
        status = "fail"
    else:
        status="sucess"
    return status

def vhdl_test_cases_report_gen(FileName,results):
    with open(FileName,'w',newline="") as f:
        f.write("Test Cases Report\n=======\n\n")
        f.write("# Summery\n\n")
        f.write("|status | entity | test case name| test  type |\n")
        f.write("|-------|--------|---------------|------------|\n")
        for x in results:
            
            f.write("|" + get_status(x) +"|"+ x["entity"] +"|"+ x["name"] +"|" +x["TestType"] +"|\n")
        
        f.write(" \n # Details \n \n ")
        for x in results:
            f.write(" \n ## " + x["name"] +" \n \n ")
            f.write(" \n ### Overview \n \n")
            f.write("|Name |Value|\n|------|----|\n")
            f.write("|Status | " + get_status(x) +"|\n")
            f.write("|Entity | "+ x["entity"] +"|\n")
            f.write("|Name | "+ x["name"] +"|\n")
            f.write("|test type | "+ x["TestType"] +"|\n")
            f.write("\n ### Desciption \n \n")
            f.write(x["descitption"])
            f.write("\n ### Files \n \n")
            f.write("|Name |Path|\n|------|----|\n")
            f.write("|Input File | " + x["InputFile"] +"|\n")
            f.write("|Output File | "+ x["OutputFile"] +"|\n")
            f.write("|Reference File | "+ x["referencefile"] +"|\n\n")
        