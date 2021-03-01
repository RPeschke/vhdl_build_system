Sub Run_Simulation()
 Worksheets("Book1").Range("op_status").Value = "save"
 ActiveWorkbook.Save
 'Worksheets("Book1").Range("op_status").Value = "WriteCSVFile"
 'WriteCSVFile
 Worksheets("Book1").Range("op_status").Value = "ssh_run_simulation"
 Range("UDP_SCRIPT_STATUS").Value = "Sending Data"
 ssh_run_simulation
 Worksheets("Book1").Range("op_status").Value = "wait_for_output"
 wait_for_output
 If is_simOut_exist = False Then
    Worksheets("Book1").Range("op_status").Value = "load_csv_line_by_line_new"
    load_csv_line_by_line_new
    
    Worksheets("Book1").Range("op_status").Value = "RefreshAll"
    ActiveWorkbook.RefreshAll
 
 End If
 
 Worksheets("Book1").Range("op_status").Value = "read_commandlineOutput"
 read_commandlineOutput
 
 Worksheets("Book1").Range("op_status").Value = "done"
 
 Range("switch_hw_sim").Value = 0
 
End Sub

Sub ssh_run_simulation()
     simulation_script = Worksheets("Setup").Range("full_script_BASH")
     
     Show_Commandline = Worksheets("Setup").Range("Show_Commandline")
  
    
  
    Shell Environ$("comspec") & " /c " & simulation_script, Show_Commandline
    

End Sub

Sub make_simulation()
     full_make_script_bash = Worksheets("Setup").Range("full_make_script_bash")
     
     Show_Commandline = Worksheets("Setup").Range("Show_Commandline")
  
    
  
    Shell Environ$("comspec") & " /c " & full_make_script_bash, Show_Commandline
    

End Sub

Sub WriteCSVFile()

Dim i As Integer
Dim WS_Count As Integer
Set Wb = ThisWorkbook

WS_Count = ActiveWorkbook.Worksheets.Count
PathName = get_simulation_input_path_win

Dim ws As Worksheet
Set ws = ThisWorkbook.Worksheets("Simulation_Input")

   ws.Copy
   Application.DisplayAlerts = False
   ActiveWorkbook.SaveAs FileName:=PathName, _
        FileFormat:=xlCSV, CreateBackup:=False, _
        AccessMode:=xlExclusive, _
        ConflictResolution:=Excel.XlSaveConflictResolution.xlLocalSessionChanges
        
Application.DisplayAlerts = True
ActiveWorkbook.Close SaveChanges:=False
Wb.Activate
End Sub
Function get_run_on_hardware_out_path_win() As String
  project_dir_windows = Worksheets("Setup").Range("w_path")
  rel_path = Worksheets("Setup").Range("rel_path")
  run_on_hw_out = Worksheets("Setup").Range("RUN_ON_HW_OUT")

  full_path = project_dir_windows & "\" & rel_path & "\" & run_on_hw_out
  full_path = Replace(full_path, "/", "\")
  full_path = Replace(full_path, "\\", "\")
  get_run_on_hardware_out_path_win = full_path

End Function


Function get_simulation_out_path_win() As String
  project_dir_windows = Worksheets("Setup").Range("w_path")
  rel_path = Worksheets("Setup").Range("rel_path")
  simulation_out = Worksheets("Setup").Range("sim_out")

  full_path = project_dir_windows & "\" & rel_path & "\" & simulation_out
  full_path = Replace(full_path, "/", "\")
  full_path = Replace(full_path, "\\", "\")
  get_simulation_out_path_win = full_path
End Function

Function get_simulation_input_path_win() As String

  project_dir_windows = Worksheets("Setup").Range("w_path")
  rel_path = Worksheets("Setup").Range("rel_path")
  simulation_in = Worksheets("Setup").Range("sim_in")
  
  full_path = project_dir_windows & "\" & rel_path & "\" & simulation_in
  full_path = Replace(full_path, "/", "\")
  full_path = Replace(full_path, "\\", "\")
  get_simulation_input_path_win = full_path & ".csv"

End Function
Function is_simOut_exist() As Boolean

 full_path = get_simulation_out_path_win
 FilePath = Dir(full_path)
 is_simOut_exist = (FilePath = "")
End Function

Sub wait_for_output()

i = 0
Application.Wait (Now + TimeValue("0:00:01"))
Do While is_simOut_exist = True Or i < 3
    Range("Timer").Value = i
    Application.Wait (Now + TimeValue("0:00:01"))

    i = i + 1
    If i > 30 Then
        Range("Timer").Value = "error"
         Exit Do
    End If
Loop


End Sub





Sub make_test_case()



vFile = Range("TestCaseName").Value
If vFile = "" Then
    Exit Sub
End If
Path = Application.ActiveWorkbook.Path
vFile = Path & "\" & vFile & ".testcase.xml"

    If Dir(vFile) > vbNullString Then
        If MsgBox("Overwrite File?", vbExclamation + vbYesNo, "Overwrite?") = vbNo Then
            Exit Sub
        End If
    End If
TC_Name = Range("TestCaseName").Value


simulation_out_path_win = get_simulation_out_path_win
simulation_in_path_win = get_simulation_input_path_win

TC_Ref_File = TC_Name & "_reference_out.csv"
TC_In_File = TC_Name & "_in.csv"


Open vFile For Output As #1

Print #1, "<?xml version=""1.0""?>"
Print #1, "<testcases>"
Print #1, "<testcase name=""" & TC_Name & """>"
Print #1, "<descitption>"
Print #1, Range("Description").Value
Print #1, "</descitption>"


Print #1, "<inputfile>" & TC_In_File & "</inputfile>"
Print #1, "<referencefile>" & TC_Ref_File & "</referencefile>"

Print #1, "<Stimulus/>"
Print #1, "<Reference/>"

  
Print #1, "<entityname>" & Range("EntityName").Value & "</entityname>"
Print #1, "<tc_type>" & Range("tc_type").Value & "</tc_type>"
Print #1, "<difftool>diff</difftool>"
Print #1, "<RegionOfInterest> "
Print #1, "<Headers> " & Range("Headers").Value & "</Headers>"
Print #1, "<Lines> " & Range("Lines2").Value & "</Lines>"
Print #1, "</RegionOfInterest> "
Print #1, "</testcase>"
Print #1, "</testcases>"
Close #1

FullName = Application.ActiveWorkbook.FullName
w_path = Worksheets("Setup").Range("w_path").Value
shell_Command = "python " & w_path & "\vhdl_build_system\bin_merge_test_case_to_one_file.py --InputTestCase " & vFile & "  --ExcelFile " & FullName
'shell_Command = "echo ""python " & w_path & "\bin_merge_test_case_to_one_file.py --InputTestCase "" > test.txt"
Shell Environ$("comspec") & " /c " & shell_Command, 0

End Sub
Sub botton_export_tc()
make_test_case
End Sub




Function find_run_simulation() As String
 Dim i As Integer
 simulation_script = Worksheets("Setup").Range("command")
 Worksheets("Setup").Range("w_path").Value = "not Found"
 Worksheets("Setup").Range("rel_path").Value = "not Found"
 rel_path = ""
 
 testname = Application.ActiveWorkbook.Path
 
    For i = 1 To 20
        run_simulationName = testname & "\" & simulation_script
        If Dir(run_simulationName) <> "" Then
            
          
            Exit For
         End If
         
         SlashIndex = InStrRev(testname, "\")
         If SlashIndex = 0 Then
            Exit For
         End If
         
         rel_path = Right(testname, Len(testname) - InStrRev(testname, "\")) & "/" & rel_path
         testname = Left(testname, InStrRev(testname, "\") - 1)
         
    Next i
 
     If Dir(run_simulationName) <> "" Then
         Worksheets("Setup").Range("w_path").Value = testname
         Worksheets("Setup").Range("rel_path").Value = rel_path
    End If
 find_run_simulation = testname
End Function
Sub Update_Config()
    find_run_simulation
End Sub


Function is_HW_out_exist() As Boolean

 full_path = get_run_on_hardware_out_path_win
 FilePath = Dir(full_path)
 is_HW_out_exist = (FilePath <> "")
End Function

Sub wait_for_hw_output()

i = 0
Application.Wait (Now + TimeValue("0:00:01"))
Do While is_HW_out_exist = False Or i < 3
    Range("Timer").Value = i
    Application.Wait (Now + TimeValue("0:00:01"))

    i = i + 1
    If i > 30 Then
        Range("Timer").Value = "error"
         Exit Do
    End If
Loop


End Sub
Sub Run_on_hardware()


  Worksheets("Book1").Range("op_status").Value = "save"
  ActiveWorkbook.Save
  'Worksheets("Book1").Range("op_status").Value = "WriteCSVFile"
  'WriteCSVFile
  Worksheets("Book1").Range("op_status").Value = "ssh_run_on_hardware"
  ssh_run_on_hardware
  Worksheets("Book1").Range("op_status").Value = "wait_for_output"
  wait_for_hw_output
  HW_out = is_HW_out_exist
  If is_HW_out_exist = True Then
     Worksheets("Book1").Range("op_status").Value = "load_csv_line_by_line_new"
     load_csv_hw_line_by_line
     Worksheets("Book1").Range("op_status").Value = "RefreshAll"
     ActiveWorkbook.RefreshAll
 End If
 Worksheets("Book1").Range("op_status").Value = "read_commandlineOutput"
 read_commandlineOutput
 Worksheets("Book1").Range("op_status").Value = "Done"
  Range("switch_hw_sim").Value = 1
End Sub

Sub ssh_run_on_hardware()
     Full_Run_On_HW_Script_bash = Worksheets("Setup").Range("Full_Run_On_HW_Script_bash")
     
     Show_Commandline = Worksheets("Setup").Range("Show_Commandline")
  
    
  
    Shell Environ$("comspec") & " /c " & Full_Run_On_HW_Script_bash, Show_Commandline
End Sub

Function get_nr_of_lines(FileName) As Long

  Set fs = CreateObject("Scripting.FileSystemObject")
  Set f = fs.OpenTextFile(FileName)
  row_number = 0

  Do While f.AtEndOfStream <> True
    row_number = row_number + 1
    LineFromFile = f.ReadLine
  Loop
  f.Close
  get_nr_of_lines = row_number
End Function

Sub load_csv_hw_line_by_line()

  Sheets("HW_output").Range("A1:ZZ10207").ClearContents
  hw_out_abs = get_run_on_hardware_out_path_win
  
  
  
  
  max_index = get_nr_of_lines(hw_out_abs)
  Dim arr() As Double
  startTimeStamp = 0
  
  
              
  Set fs = CreateObject("Scripting.FileSystemObject")
  Set f = fs.OpenTextFile(hw_out_abs)
  
  LineFromFile = f.ReadLine
  LineItems = Split(LineFromFile, ";")
  i_max = UBound(LineItems)
  For i = 0 To i_max
  
    Range("hw_out_table").Offset(0, i).Value = LineItems(i)
   Range("hw_out_table").Offset(1, i).Value = 0
  Next
  
  
  

  

  row_number = 0

    Do While f.AtEndOfStream <> True
        LineFromFile = f.ReadLine
        LineItems = Split(LineFromFile, ";")
        i_max = UBound(LineItems)
       
         ReDim Preserve arr(0 To max_index, 0 To i_max)
  
        For i = 0 To i_max
         
          If i = 6 Then
            If row_number = 0 Then
                startTimeStamp = CDbl(LineItems(i))
            End If
            arr(row_number, i) = CDbl(LineItems(i)) - startTimeStamp
          Else
            arr(row_number, i) = CDbl(LineItems(i))
          End If
        Next i
            
        row_number = row_number + 1
    Loop
    
    f.Close
    If row_number > 1 Then
        Range("hw_out_table").Offset(2, 0).Resize(row_number, i_max + 1).Value = arr
    End If
        
    Sheets("Book1").Activate


End Sub


Sub load_csv_line_by_line_new()
  


  sim_out_abs = get_simulation_out_path_win
  
  max_index = get_nr_of_lines(sim_out_abs)
  Dim arr() As Double

  
  
  Set fs = CreateObject("Scripting.FileSystemObject")
  Set f = fs.OpenTextFile(sim_out_abs)

  

  row_number = 0

    Do While f.AtEndOfStream <> True
        LineFromFile = f.ReadLine
        LineItems = Split(LineFromFile, ";")
        i_max = UBound(LineItems)
       

        If row_number = 0 Then
           For i = 0 To i_max
             LineItems(i) = Trim(LineItems(i))
           Next
           
            Range("sim_out_table").Offset(row_number, 0).Resize(1, i_max + 1).Value = LineItems
        Else

            ReDim Preserve arr(1 To max_index, 0 To i_max)
            
            For i = 0 To i_max
                If i = 0 Then
                    arr(row_number, i) = Replace(LineItems(i), "ps", "")
                Else
                    arr(row_number, i) = LineItems(i)
                End If
                
            Next i
            

        End If
        row_number = row_number + 1
    Loop
    
    f.Close
    If row_number > 1 Then
        Range("sim_out_table").Offset(1, 0).Resize(row_number, i_max + 1).Value = arr
    End If
        
    Sheets("Book1").Activate
  
End Sub



Sub load_test_case()






sim_out_header_items = get_sim_out_header

sim_in = get_simulation_input_path_win

  Set fs = CreateObject("Scripting.FileSystemObject")
  Set f = fs.OpenTextFile(sim_in)




row_number = 0

sim_in_header = f.ReadLine
sim_in_header = Replace(sim_in_header, " ", "")
sim_in_header_items = Split(sim_in_header, ",")



For i = 0 To UBound(sim_out_header_items)
        Sheets("Book1").Range("D2").Offset(row_number + 1, i).Value = Trim(sim_out_header_items(i))
        Sheets("Book1").Range("D2").Offset(row_number + 1, i).Orientation = 90
        If IsInArray(Sheets("Book1").Range("D2").Offset(row_number + 1, i).Value, sim_in_header_items) Then
            Sheets("Book1").Range("D2").Offset(0, i).Value = "in"
        Else
        
            Sheets("Book1").Range("D2").Offset(0, i).Value = "out"
            Sheets("Book1").Columns("d:d").Offset(0, i).Style = "Good"
        End If
        
        
Next i
row_number = row_number + 1


Do While f.AtEndOfStream <> True
    LineFromFile = f.ReadLine
    LineItems = Split(LineFromFile, ",")
    i_max = UBound(LineItems)
    j = 0
    For i = 0 To UBound(sim_out_header_items)
        If (Sheets("Book1").Range("D2").Offset(0, i).Value = "in") And sim_out_header_items(i) <> "" Then
            Sheets("Book1").Range("D2").Offset(row_number + 1, i).Value = Trim(LineItems(j))
            j = j + 1
        

        End If
        
    Next i
    
    
    row_number = row_number + 1

Loop

f.Close


For i = 0 To UBound(sim_out_header_items)
    r1 = Sheets("Book1").Range("A1:ZZ10234").Cells(2, i + 4).Value
    If (r1 = "out") Then
    '    =IF(R20C1=0, Simulation_output!R[-2]C[-3],HW_output!R[-3]C[3])
        Sheets("Book1").Range("D3:D" & row_number + 2).Offset(0, i).FormulaR1C1 = "=if(switch_hw_sim=0, Simulation_output!R[-2]C[-3],HW_output!R[-2]C[3])"
    End If
Next i


j = 0
For i = 0 To UBound(sim_out_header_items)
    r1 = Sheets("Book1").Range("A1:ZZ10234").Cells(2, i + 4).Value
    Header = Sheets("Book1").Range("A1:ZZ10234").Cells(3, i + 4).Value
    If (r1 = "in" And Header <> "") Then
        diff = i - j + 3
    
        Sheets("Simulation_Input").Range("A1:A" & row_number + 2).Offset(0, j).FormulaR1C1 = "=Book1!R[2]C[" & diff & "]"
        j = j + 1
    End If
Next i

For i = 0 To UBound(sim_in_header_items)
    Sheets("Simulation_Input").Range("A1").Offset(1, i).Value = Trim(sim_in_header_items(i))

Next i
End Sub
Function get_sim_out_header() As Variant
 
    sim_out = get_simulation_out_path_win
    Set fs = CreateObject("Scripting.FileSystemObject")
    Set f = fs.OpenTextFile(sim_out)

    sim_out_header = f.ReadLine
    sim_out_header = Replace(sim_out_header, " ", "")
    sim_out_header_items = Split(sim_out_header, ";")


    f.Close


    get_sim_out_header = sim_out_header_items

End Function
Function IsInArray(stringToBeFound As String, arr As Variant) As Boolean

ret = False
For i = 0 To UBound(arr)
 If arr(i) = stringToBeFound Then
     ret = True
     Exit For
 End If
    
Next i
IsInArray = ret
End Function

Sub import_test()
    test_case_load_cleanup
    clear_all
    Update_Config
    chooses_test_case
    Range("switch_hw_sim").Value = 0
    
    load_csv_line_by_line_new
    load_test_case
    make_ControlSheet
    test_case_load_cleanup
End Sub

Sub test_case_load_cleanup()

sim_in = get_simulation_input_path_win
simout = get_simulation_out_path_win

    shell_Command = "del " & simout
    Shell Environ$("comspec") & " /c " & shell_Command, 0
    
    shell_Command = "del " & sim_in
    Shell Environ$("comspec") & " /c " & shell_Command, 0
    
    shell_Command = "del " & Worksheets("Setup").Range("G2").Value
    Shell Environ$("comspec") & " /c " & shell_Command, 0
End Sub

Sub make_ControlSheet()
sim_input = Trim(Sheets("Simulation_Input").Range("A1").Value)
sim_output = Trim(Sheets("Simulation_output").Range("A1").Value)
i = 0
j = 0
Do While sim_input <> ""
    sim_input = Trim(Sheets("Simulation_Input").Range("A1").Offset(0, i).Value)
    Do While sim_output <> ""
        sim_output = Trim(Sheets("Simulation_output").Range("A1").Offset(0, j).Value)
        j = j + 1
        If sim_input = sim_output Then
           diff = (j - 1) - i
           Sheets("ControlSheet").Range("A1").Offset(0, i).FormulaR1C1 = "=Simulation_Input!R[0]C[0]"
           Sheets("ControlSheet").Range("A1").Offset(1, i).FormulaR1C1 = "=Simulation_output!R[-1]C[" & diff & "]"
           Sheets("ControlSheet").Range("A3:A1000").Offset(0, i).FormulaR1C1 = "=Simulation_Input!R[0]C[0]" & "- Simulation_output!R[0]C[" & diff & "]"
           Exit Do
        End If

    Loop
    i = i + 1
    
Loop


End Sub
Sub chooses_test_case()
    Dim lngCount As Long
 
    ' Open the file dialog
    With Application.FileDialog(msoFileDialogOpen)
        .AllowMultiSelect = False
        .Show
        .Filters.Add "Test case Files", "*.xml", 1
 
        ' Display paths of each file selected
        For lngCount = 1 To .SelectedItems.Count
            FileName = .SelectedItems(lngCount)
        Next lngCount
 
    End With
    
    w_path = Worksheets("Setup").Range("w_path").Value
    shell_Command = "python " & w_path & "\vhdl_build_system\bin_split_test_case.py --InputTestCase " & FileName
'shell_Command = "echo ""python " & w_path & "\bin_merge_test_case_to_one_file.py --InputTestCase "" > test.txt"
    Shell Environ$("comspec") & " /c " & shell_Command, 0
    Application.Wait (Now + TimeValue("0:00:02"))
 Dim XDoc As Object, root As Object
    Set oXMLFile = CreateObject("Microsoft.XMLDOM")
    
     
    pathtoxmlFile = Left(FileName, InStrRev(FileName, "\") - 1)
    oXMLFile.Load (FileName)
    
    

    Set descitption = oXMLFile.SelectNodes("/testcases/testcase/descitption")
    Range("Description").Value = descitption(0).ChildNodes(0).Text
    
    
    Set tc_type = oXMLFile.SelectNodes("/testcases/testcase/tc_type")
    Range("tc_type").Value = tc_type(0).ChildNodes(0).Text
    
    
    Set EntityName = oXMLFile.SelectNodes("/testcases/testcase/entityname")
    Range("EntityName").Value = EntityName(0).ChildNodes(0).Text
    
    
    Set xinputfile = oXMLFile.SelectNodes("/testcases/testcase/inputfile")
    inputfile = xinputfile(0).ChildNodes(0).Text
    
    Set xreferencefile = oXMLFile.SelectNodes("/testcases/testcase/referencefile")
    referencefile = xreferencefile(0).ChildNodes(0).Text
    simout = get_simulation_out_path_win
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.MoveFile pathtoxmlFile & "\" & referencefile, simout
    sim_in = get_simulation_input_path_win
        
    fs.MoveFile pathtoxmlFile & "\" & inputfile, sim_in
    
    Worksheets("Setup").Range("G2").Value = sim_in
    Worksheets("Setup").Range("G3").Value = pathtoxmlFile & "\" & inputfile
    Worksheets("Setup").Range("G4").Value = simout
    
    Worksheets("Setup").Range("G5").Value = pathtoxmlFile & "\" & referencefile



End Sub

Sub clear_all()
 Sheets("Simulation_Input").Range("A1:ZZ10207").ClearContents
 Sheets("Simulation_output").Range("A1:ZZ10207").ClearContents
 Sheets("Book1").Range("D2:ZZ10207").ClearContents
  Range("EntityName").Value = ""
  
 Range("tc_type").Value = ""
 Range("Description").Value = ""
 Range("TestCaseName").Value = ""
 Sheets("Book1").Columns("d:zz").Offset(0, i).Style = "normal"
 Sheets("Book1").Range("D1:zz1").Style = "20% - Accent1"
 
 Sheets("CommandlineOutput").Range("A1:D10207").ClearContents
 
 Sheets("ControlSheet").Range("A1:ZZ10207").ClearContents
End Sub


Sub read_commandlineOutput()
 w_path = Range("w_path").Value
 FileOutPut = Range("FileOutPut").Value
  Set fs = CreateObject("Scripting.FileSystemObject")
  Set f = fs.OpenTextFile(w_path & "\" & FileOutPut)
  i = 0
  Parsing_i = 0
  Error_i = 0
  Note_i = 0
  Sheets("CommandlineOutput").Range("A1:D10207").ClearContents
  Sheets("CommandlineOutput").Range("A1").Value = "Output"
  Sheets("CommandlineOutput").Range("B1").Value = "Parsing Files"
  Sheets("CommandlineOutput").Range("C1").Value = "Errors"
  Sheets("CommandlineOutput").Range("D1").Value = "Notes"
  
  UDP_end_of_command_token_found = False
  
      Do While f.AtEndOfStream <> True
        LineFromFile = f.ReadLine
        Sheets("CommandlineOutput").Range("A2").Offset(i, 0).Value = LineFromFile
        i = i + 1
        
        If InStr(LineFromFile, "Parsing") Then
            Sheets("CommandlineOutput").Range("B2").Offset(Parsing_i, 0).Value = LineFromFile
            Parsing_i = Parsing_i + 1
        End If
        
        If InStr(LineFromFile, "ERROR") Then
            Sheets("CommandlineOutput").Range("C2").Offset(Error_i, 0).Value = LineFromFile
            Error_i = Error_i + 1
        End If
        If InStr(LineFromFile, "Note") Then
            Sheets("CommandlineOutput").Range("D2").Offset(Note_i, 0).Value = LineFromFile
            Note_i = Note_i + 1
        End If
        
        If InStr(LineFromFile, "----end udp_run script----") Then
            UDP_end_of_command_token_found = True
            
        End If
        
      Loop
      
      
      If Range("switch_hw_sim").Value = 1 Then
        If UDP_end_of_command_token_found Then
          Range("UDP_SCRIPT_STATUS").Value = "Success"
        Else
          Range("UDP_SCRIPT_STATUS").Value = "Error"
        End If
      End If
        
End Sub

