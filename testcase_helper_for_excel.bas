Attribute VB_Name = "Module1"
Sub Run_Simulation()
 
 
 WriteCSVFile
 ssh_run_simulation
 wait_for_output
 
 ActiveWorkbook.RefreshAll
End Sub

Sub ssh_run_simulation()
     simulation_script = Worksheets("Setup").Range("command")
     project_dir = Worksheets("Setup").Range("l_path")
     project_dir_windows = Worksheets("Setup").Range("w_path")
     csv_Name = Worksheets("Setup").Range("sim_in")
     
     'csv_Name = Cells(1, "C").Text
     simulation_out = Worksheets("Setup").Range("sim_out")
     simulation_out_win = Replace(simulation_out, "/", "\")
    full_path_win = project_dir_windows & "\" & simulation_out_win
     Shell Environ$("comspec") & " /c del " & full_path_win, vbHide
     
     full_command = simulation_script & " " & csv_Name & " " & simulation_out
     ssh_connection = Worksheets("Setup").Range("ssh_Connection_name")
     script_text_output = Worksheets("Setup").Range("script_text_output")
     change_dir = "cd " & project_dir
     
     ssh_prefix = " ssh " & ssh_connection & " """
     ssh_suffix = """ > " & project_dir_windows & "\" & script_text_output
     
    ssh_com = ssh_prefix & change_dir & "  && " & full_command & ssh_suffix
    Shell Environ$("comspec") & " /c " & ssh_com, vbHide

End Sub

Sub WriteCSVFile()

Dim i As Integer
Dim WS_Count As Integer
Set Wb = ThisWorkbook

WS_Count = ActiveWorkbook.Worksheets.Count
project_dir_windows = Worksheets("Setup").Range("w_path")
Dim ws As Worksheet
csv_Name = Worksheets("Setup").Range("sim_in")
Set ws = ThisWorkbook.Worksheets("Simulation_Input")
     PathName = "" & project_dir_windows & "\" & csv_Name
    ws.Copy
   Application.DisplayAlerts = False
    ActiveWorkbook.SaveAs Filename:=PathName, _
        FileFormat:=xlCSV, CreateBackup:=False, _
        AccessMode:=xlExclusive, _
        ConflictResolution:=Excel.XlSaveConflictResolution.xlLocalSessionChanges
        
Application.DisplayAlerts = True
ActiveWorkbook.Close SaveChanges:=False
Wb.Activate
End Sub

Function get_simulation_out_path_win() As String
  project_dir_windows = Worksheets("Setup").Range("w_path")
  simulation_out = Worksheets("Setup").Range("sim_out")
  simulation_out = Replace(simulation_out, "/", "\")
  full_path = project_dir_windows & "\" & simulation_out

  get_simulation_out_path_win = full_path
End Function

Function get_simulation_input_path_win() As String

  project_dir_windows = Worksheets("Setup").Range("w_path")
  simulation_in = Worksheets("Setup").Range("sim_in")
  simulation_in = Replace(simulation_in, "/", "\")
  full_path = project_dir_windows & "\" & simulation_in

  get_simulation_input_path_win = full_path

End Function
Sub wait_for_output()


    full_path = get_simulation_out_path_win

FilePath = ""
i = 0
Application.Wait (Now + TimeValue("0:00:01"))
Do While FilePath = ""
    Range("Timer").Value = i
    Application.Wait (Now + TimeValue("0:00:01"))
    FilePath = Dir(full_path)
    i = i + 1
    If i > 30 Then
        Range("Timer").Value = "error"
         Exit Do
    End If
Loop
'Application.Wait (Now + TimeValue("0:00:05"))

End Sub



Function findLocation() As String

locationfound = False

Do While locationfound = False
vFile = Application.GetSaveAsFilename( _
    FileFilter:="Test Case Files (*.testcase.xml), *.testcase.xml", _
    InitialFileName:="tb_fifo_cc_step_by_step_tc1.testcase.xml" _
    )
    If vFile <> False Then
        findLocation = vFile
        locationfound = True
    End If
    
    If vFile = False Then
      findLocation = ""
      Exit Function
    End If
    
    If Dir(vFile) > vbNullString Then
        If MsgBox("Overwrite File?", vbExclamation + vbYesNo, "Overwrite?") = vbYes Then
            locationfound = True
        Else
            locationfound = False
        End If
    End If

Loop
   
findLocation = vFile
End Function


Sub make_test_case()



'vFile = findLocation
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
FileCopy simulation_out_path_win, Path & "\" & TC_Ref_File
FileCopy simulation_in_path_win, Path & "\" & TC_In_File

Open vFile For Output As #1

Print #1, "<?xml version=""1.0""?>"
Print #1, "<testcases>"
Print #1, "<testcase name=""" & TC_Name & """>"
Print #1, "<descitption>"
Print #1, Range("Description").Value
Print #1, "</descitption>"


Print #1, "<inputfile>" & TC_In_File & "</inputfile>"
Print #1, "<referencefile>" & TC_Ref_File & "</referencefile>"
  
Print #1, "<entityname>" & Range("EntityName").Value & "</entityname>"
Print #1, "<difftool>diff</difftool>"
Print #1, "</testcase>"
Print #1, "</testcases>"
Close #1

End Sub
Sub botton_export_tc()
make_test_case
End Sub

