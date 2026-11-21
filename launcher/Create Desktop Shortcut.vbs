' Puts a "TLauncher (hardened)" icon on your Desktop and in the Start menu.
' Run this again if you move the folder (shortcuts store the full path).
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")
here = fso.GetParentFolderName(WScript.ScriptFullName)
For Each place In Array(sh.SpecialFolders("Desktop"), sh.SpecialFolders("Programs"))
  Set lnk = sh.CreateShortcut(place & "\TLauncher (hardened).lnk")
  lnk.TargetPath = sh.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\wscript.exe"
  lnk.Arguments = """" & here & "\Start TLauncher.vbs"""
  lnk.WorkingDirectory = here
  lnk.IconLocation = here & "\tlauncher.ico,0"
  lnk.Description = "Hardened TLauncher (portable)"
  lnk.Save
Next
MsgBox "Shortcut created on your Desktop and in the Start menu.", 64, "TLauncher (hardened)"
