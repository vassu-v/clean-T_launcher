' Starts hardened TLauncher without a black console window.
' First run opens the console once (to ask about copying your worlds); later runs are silent.
' If something goes wrong, run run-tlauncher.bat instead - it shows the error.
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")
here = fso.GetParentFolderName(WScript.ScriptFullName)
sh.CurrentDirectory = here
If fso.FileExists(here & "\data\.copied-once") Then
  sh.Run "cmd /c """"" & here & "\run-tlauncher.bat"" silent""", 0, False
Else
  sh.Run "cmd /c """"" & here & "\run-tlauncher.bat""""", 1, False
End If
