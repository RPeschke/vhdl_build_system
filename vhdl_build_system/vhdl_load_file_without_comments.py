def load_file_witout_comments(FileName):
    FileContent = ""
    with open(FileName, "r", encoding="utf-8") as f:
        contents =f.readlines()
        for x in contents:
            FileContent+= x.split("--")[0].split("\r\n")[0].split("\n")[0] + " "
    
    FileContent = FileContent.replace("\t", "  ")
    FileContent = FileContent.replace("(", " ( ")
    FileContent = FileContent.replace(")", " ) ")
    FileContent = FileContent.replace(";", " ; ")
    FileContent = FileContent.replace(":", " : ")
    FileContent = FileContent.replace(": =", " := ")
    FileContent =FileContent.lower()
    FileContent =' '.join(FileContent.split())
    FileContent = FileContent.replace(" slv ", " std_logic_vector ")
    FileContent = FileContent.replace(" sl ", " std_logic ")
    return FileContent