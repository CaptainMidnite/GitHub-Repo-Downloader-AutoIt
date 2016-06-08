#cs ------------------------------------------------------------------------------------------------------------------------------------------------------

 AutoIt Version: 3.3.15.0 (Beta)
 Author:         CaptainMidnite

 Script Function:	GUI GitHub_Repo_Builder - v2.0

 Release:			Public Release!

 Description:		GUI Version to Download a Members Complete Repository Set
					Includes the Ability to Just Download and Create Batch File for Later Processing of Repositories
					Or You Download, Create Batch File, and Download all Repositories

#ce -------------------------------------------------------------------------------------------------------------------------------------------------------

; Script Start - Add your code below here
; Globals
;----------------------------------------------------------------------------------------------------------------------------------------------------------
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
;----------------------------------------------------------------------------------------------------------------------------------------------------------

; GUI
;----------------------------------------------------------------------------------------------------------------------------------------------------------
#Region ### START Koda GUI section ###
$Form2 = GUICreate("GitHub Repo Builder", 537, 236, 182, 121)
$Label1 = GUICtrlCreateLabel("1: Please enter the site page for the repo you wish to download", 8, 8, 301, 17)
$Label2 = GUICtrlCreateLabel("Web Address:", 8, 32, 71, 17)
$SrcAdd_bx = GUICtrlCreateInput("https://github.com/google", 80, 30, 451, 21)
$Label3 = GUICtrlCreateLabel("2: Enter a name for your project below", 8, 56, 183, 17)
$Label4 = GUICtrlCreateLabel("Project Name:", 8, 80, 71, 17)
$Proj_bx = GUICtrlCreateInput("Google_GitHub_Source", 80, 78, 451, 21)
$Label5 = GUICtrlCreateLabel("3: Enter or select a destination directory for the project below", 8, 104, 289, 17)
$Label6 = GUICtrlCreateLabel("Destination:", 8, 128, 60, 17)
$DestDir_bx = GUICtrlCreateInput(@ScriptDir, 80, 128, 371, 21)
$Build_btn = GUICtrlCreateButton("Build", 8, 200, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Cancel_btn = GUICtrlCreateButton("Cancel", 120, 200, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Browse_btn = GUICtrlCreateButton("Browse", 456, 126, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Label7 = GUICtrlCreateLabel("4: Execute After Retriving Source", 8, 154, 162, 17)
$Build_rd = GUICtrlCreateRadio("Build Only", 8, 176, 73, 17)
GUICtrlSetState(-1, $GUI_CHECKED)
$BuildEX_rd = GUICtrlCreateRadio("Build and Execute", 104, 176, 113, 17)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $GUI_EVENT_MINIMIZE
			GUISetState(@SW_MINIMIZE)
		Case $GUI_EVENT_RESTORE
			GUISetState(@SW_RESTORE)
		Case $Browse_btn
			$fsFolder = FileSelectFolder("Select Destination Folder", "")
			$dstFolder = $fsFolder & "\" & ReplaceRsrvd(GUICtrlRead($Proj_bx))
			GUICtrlSetData($DestDir_bx, $dstFolder)
			GUICtrlSetData($Proj_bx, ReplaceRsrvd(GUICtrlRead($Proj_bx)))
		Case $Build_btn
			$rdbStatus = GUICtrlRead($Build_rd)
			$rdeStatus = GUICtrlRead($BuildEX_rd)
			;MsgBox($MB_OK, "Radio Button Stats", "Build_rd: " & $rdbStatus & @CRLF & "BuildEX_rd: " & $rdeStatus)
			If $rdbStatus = 1 Then
				$ghAddress = GUICtrlRead($SrcAdd_bx)
				$dstDir = GUICtrlRead($DestDir_bx)
				$prjName = ReplaceRsrvd(GUICtrlRead($Proj_bx))
				$dstFolder = $dstDir & "\" & $prjName
				GUISetState(@SW_HIDE)
				GitSrcRepos($ghAddress, $dstDir)
				WriteBatch($prjName, $dstDir)
				Exit
			ElseIf $rdeStatus = 1 Then
				$ghAddress = GUICtrlRead($SrcAdd_bx)
				$dstDir = GUICtrlRead($DestDir_bx)
				$prjName = ReplaceRsrvd(GUICtrlRead($Proj_bx))
				$dstFolder = $dstDir & "\" & $prjName
				GUISetState(@SW_HIDE)
				GitSrcRepos($ghAddress, $dstDir)
				$bdBat = WriteBatch($prjName, $dstDir)
				RunWait($bdBat, $dstDir)
				Exit
			EndIf
		Case $Cancel_btn
			Exit
	EndSwitch
WEnd
;----------------------------------------------------------------------------------------------------------------------------------------------------------

; Functions
;----------------------------------------------------------------------------------------------------------------------------------------------------------
Func GitSrcRepos($srcString, $destDir)
;$srcString = InputBox("Source Address", "Please Input the Source Repo Address Below", "https://github.com/google")
$htmTemp = $destDir & "\temp.html"
$srcLst = $destDir & "\SourceList.txt"
If FileExists($srcLst) = 1 Then
	FileDelete($srcLst)
EndIf
HttpSetUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25")
InetGet($srcString & "?tab=repositories", $htmTemp)
HttpSetUserAgent("")
$aArray = ""
_FileReadToArray($htmTemp, $aArray)
;_ArrayDisplay($aArray, "$aArray")
ProgressOn("Processing File", "Loading File Please Wait...", "Loading Resource ~ 0%")
Sleep(1500)
For $i = $aArray[0] To 1 Step - 1
	$step = $aArray[0] - $i
	$prgss = ($step / $aArray[0]) * 100
	$prgss = StringFormat("%.2f", $prgss)
	$aLine = $aArray[$i]
	If StringInStr($aLine, "list-item repo-list-item") = 0 Or StringInStr($aLine, "list-item repo-list-item") = 1 Then
		_ArrayDelete($aArray, $i)
	EndIf
	;ProgressSet($prgss, "Parsing Line: " & $i & " ~ " & StringFormat("%d", $prgss) & "%")
	ProgressSet($prgss, "Lines Remaining: " & $i & " ~ " & $prgss & "%", "Parsing Downloaded File")
Next
$aUbound = UBound($aArray) - 1
;ConsoleWrite("New UBound: " & $aUbound & @CRLF)
;_ArrayDisplay($aArray)
Local $hFileOpen = FileOpen($srcLst, $FO_APPEND)
ProgressSet(100, "Please Wait...", "Writing Text to SourceList.txt")
For $i = 1 To $aUbound Step + 1
	$sLine = $aArray[$i]
	$sLine = StringReplace($sLine, '      <a class="list-item repo-list-item" href="', 'http://github.com')
	$sLine = StringReplace($sLine, '">', "")
	FileWriteLine($hFileOpen, $sLine)
Next
Sleep(1000)
ProgressOff()
FileClose($hFileOpen)
FileDelete($htmTemp)
EndFunc

Func WriteBatch($ProjectName, $DestDir)
$batFile = $DestDir & "\GitHub_Make_" & $ProjectName & ".bat"
Local $hFileOpen = FileOpen($batFile, $FO_APPEND)
FileWriteLine($hFileOpen, "@echo off")
FileWriteLine($hFileOpen, "echo Starting GitHub Make...")
FileWriteLine($hFileOpen, "echo Clearing Previous Variables...")
FileWriteLine($hFileOpen, "set " & Chr(34) & "num=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "pName=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "dstDir=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "srcLst=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "srcCount=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "var=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "str=" & Chr(34))
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "echo Setting Variables...")
FileWriteLine($hFileOpen, "set num=0")
FileWriteLine($hFileOpen, "Set pName=" & $ProjectName)
FileWriteLine($hFileOpen, "Set dstDir=" & $ProjectName)
FileWriteLine($hFileOpen, "Set srcLst=SourceList.txt")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "::Check and make sure that the srcLst path exists")
FileWriteLine($hFileOpen, "echo Starting PreChecks...")
FileWriteLine($hFileOpen, "echo Checking Source List Exists...")
FileWriteLine($hFileOpen, "Call:sleep 500")
FileWriteLine($hFileOpen, "IF NOT EXIST " & Chr(34) & "%srcLst%" & Chr(34) & " (")
FileWriteLine($hFileOpen, "   echo ERROR Cannot Locate SourceList: %srcLst%...")
FileWriteLine($hFileOpen, "   echo Please check the Name of the SourceList and make sure its in this directory!")
FileWriteLine($hFileOpen, "   echo Exiting Script Now!")
FileWriteLine($hFileOpen, "   Exit /B")
FileWriteLine($hFileOpen, ") ELSE (")
FileWriteLine($hFileOpen, "   echo Found SourceList " & Chr(39) & "%srcLst%" & Chr(39) & "! Continuing...")
FileWriteLine($hFileOpen, "   Call:sleep 500")
FileWriteLine($hFileOpen, ")")
FileWriteLine($hFileOpen, "::Check and see if dstDir needs to be created...")
FileWriteLine($hFileOpen, "echo Checking for Destination Directory...")
FileWriteLine($hFileOpen, "Call:sleep 500")
FileWriteLine($hFileOpen, "IF NOT EXIST " & Chr(34) & "%dstDir%" & Chr(34) & " (")
FileWriteLine($hFileOpen, "   echo Destination Directory Does Not Exist...")
FileWriteLine($hFileOpen, "   echo Creating GitHub Directory for %pName%...")
FileWriteLine($hFileOpen, "   mkdir %dstDir%")
FileWriteLine($hFileOpen, "   Call:sleep 500")
FileWriteLine($hFileOpen, "   echo Copying Source List to Destination Directory...")
FileWriteLine($hFileOpen, "   copy %srcLst% %dstDir%")
FileWriteLine($hFileOpen, "   Call:sleep 500")
FileWriteLine($hFileOpen, ") ELSE (")
FileWriteLine($hFileOpen, "   echo Destination Directory Already Exists...")
FileWriteLine($hFileOpen, "   echo Copying Source List to Destination Directory...")
FileWriteLine($hFileOpen, "   copy %srcLst% %dstDir%")
FileWriteLine($hFileOpen, "   Call:sleep 500")
FileWriteLine($hFileOpen, ")")
FileWriteLine($hFileOpen, "echo Moving into GitHub Directory...")
FileWriteLine($hFileOpen, "cd %dstDir%")
FileWriteLine($hFileOpen, "echo Parsing Source Repo List...")
FileWriteLine($hFileOpen, "Call:sleep 1000")
FileWriteLine($hFileOpen, "for /f %%C in (" & Chr(39) & "Find /V /C " & Chr(34) & "" & Chr(34) & " ^< %srcLst%" & Chr(39) & ") do set srcCount=%%C")
FileWriteLine($hFileOpen, "echo Total Repos to Cloan %srcCount%")
FileWriteLine($hFileOpen, "Call:sleep 500")
FileWriteLine($hFileOpen, "echo Completed Initalization Steps Successfully!")
FileWriteLine($hFileOpen, "echo Prepare to Start Processing Repos...")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "echo Starting Cloaning Repositories Please wait...")
FileWriteLine($hFileOpen, "Call:sleep 1000")
FileWriteLine($hFileOpen, "for /F " & Chr(34) & "tokens=*" & Chr(34) & " %%A in (%srcLst%) do Call:GitDown %%A")
FileWriteLine($hFileOpen, "echo Done Cloaning Repos!")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "echo Creating Directory List for update script")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "dir /b >FileList.txt")
FileWriteLine($hFileOpen, "echo Removing TXT Entries from file " & Chr(39) & "FileList.txt" & Chr(39))
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "type FileList.txt | findstr /v .txt >FileList2.txt")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "del FileList.txt")
FileWriteLine($hFileOpen, "::type FileList2.txt >FileList.txt")
FileWriteLine($hFileOpen, "echo Removing Null from file " & Chr(39) & "FileList.txt" & Chr(39))
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "type FileList2.txt | findstr /v Null >FileList.txt")
FileWriteLine($hFileOpen, "del FileList2.txt")
FileWriteLine($hFileOpen, "echo Checking for Existing GitUpdate Batch File...")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "If EXIST " & Chr(34) & "GitUpdate_%pname%.bat" & Chr(34) & " (")
FileWriteLine($hFileOpen, "	echo Found existing file GitUpdate_%pname%.bat!")
FileWriteLine($hFileOpen, "	echo Removing File!")
FileWriteLine($hFileOpen, "	Call:sleep 1500")
FileWriteLine($hFileOpen, "	DEL " & Chr(34) & "GitUpdate_%pname%.bat" & Chr(34))
FileWriteLine($hFileOpen, "	echo File Removed Successfully!")
FileWriteLine($hFileOpen, "	Call:sleep 1500")
FileWriteLine($hFileOpen, ") ELSE (")
FileWriteLine($hFileOpen, "	echo No Existing Update File Found...")
FileWriteLine($hFileOpen, "	Call:sleep 1500")
FileWriteLine($hFileOpen, ")")
FileWriteLine($hFileOpen, "echo Getting Repos Parent Directory...")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "FOR /F " & Chr(34) & "tokens=* USEBACKQ" & Chr(34) & " %%F IN (`chdir`) DO (")
FileWriteLine($hFileOpen, "SET var=%%F")
FileWriteLine($hFileOpen, ")")
FileWriteLine($hFileOpen, ":: Original For Loop for Writing Git Update Commands for Each Repo")
FileWriteLine($hFileOpen, "::for /F " & Chr(34) & "tokens=*" & Chr(34) & " %%A in (FileList.txt) do echo Writing Repo Entry " & Chr(39) & "%%A" & Chr(39) & " & echo cd " & Chr(34) & "%var%\%%A" & Chr(34) & ">>GitUpdate_%pname%.bat & echo.Updating Repo " & Chr(39) & "%%A" & Chr(39) & ">>GitUpdate_%pname%.bat & echo.git pull>>GitUpdate_%pname%.bat")
FileWriteLine($hFileOpen, "")
FileWriteLine($hFileOpen, "::Replacement For Loop using Function to Write Git Update Commands for Each Repo")
FileWriteLine($hFileOpen, "echo @echo Off>>GitUpdate_%pname%.bat")
FileWriteLine($hFileOpen, "for /F " & Chr(34) & "tokens=*" & Chr(34) & " %%A in (FileList.txt) do Call:wGitUpdate %%A")
FileWriteLine($hFileOpen, "echo Closing File " & Chr(39) & "GitUpdate_%pname%.bat" & Chr(39) & " ")
FileWriteLine($hFileOpen, "echo cd " & Chr(34) & "%var%" & Chr(34) & ">>GitUpdate_%pname%.bat")
FileWriteLine($hFileOpen, "echo Completed Creating " & Chr(39) & "GitUpdate_%pname%.bat" & Chr(39))
FileWriteLine($hFileOpen, "echo Cleaning Up Old Files...")
FileWriteLine($hFileOpen, "echo Removing " & Chr(39) & "FileList.txt" & Chr(39))
FileWriteLine($hFileOpen, "del FileList.txt")
FileWriteLine($hFileOpen, "echo Removing " & Chr(39) & "Null" & Chr(39))
FileWriteLine($hFileOpen, "del Null")
FileWriteLine($hFileOpen, "echo Removing " & Chr(39) & "%srcLst%" & Chr(39))
FileWriteLine($hFileOpen, "del %srcLst%")
FileWriteLine($hFileOpen, "echo Returning to Original Directory...")
FileWriteLine($hFileOpen, "cd ..")
FileWriteLine($hFileOpen, "del Null")
FileWriteLine($hFileOpen, "echo Completed File Cleanup...")
FileWriteLine($hFileOpen, "Call:sleep 1000")
FileWriteLine($hFileOpen, "echo GitHub Make Completed Successfully!")
FileWriteLine($hFileOpen, "")
FileWriteLine($hFileOpen, "echo.&goto:eof")
FileWriteLine($hFileOpen, "")
FileWriteLine($hFileOpen, ":: Function to Download Source Repo and Echo Number")
FileWriteLine($hFileOpen, ":GitDown")
FileWriteLine($hFileOpen, "set /a num=%num%+1")
FileWriteLine($hFileOpen, "set str=%~1")
FileWriteLine($hFileOpen, "set strName=%~1")
FileWriteLine($hFileOpen, "set strName=%strName:http://github.com/=%")
FileWriteLine($hFileOpen, "set strName=%strName:https://github.com/=%")
FileWriteLine($hFileOpen, "set str=%str:~-4%")
FileWriteLine($hFileOpen, "echo. Cloaning Repo # %num% of %srcCount%: %strName%")
FileWriteLine($hFileOpen, "IF " & Chr(34) & "%str%" & Chr(34) & " == " & Chr(34) & ".git" & Chr(34) & " (")
FileWriteLine($hFileOpen, "	git clone %~1")
FileWriteLine($hFileOpen, ") ELSE (")
FileWriteLine($hFileOpen, "	git clone %~1.git")
FileWriteLine($hFileOpen, ")")
FileWriteLine($hFileOpen, "echo. Done Cloaining Repo # %num% of %srcCount%")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "goto:eof")
FileWriteLine($hFileOpen, "")
FileWriteLine($hFileOpen, ":: Function to Write Repo Update Entry")
FileWriteLine($hFileOpen, ":wGitUpdate")
FileWriteLine($hFileOpen, "echo Writing Repo Entry " & Chr(39) & "%~1" & Chr(39))
FileWriteLine($hFileOpen, "echo.cd " & Chr(34) & "%var%\%~1" & Chr(34) & ">>GitUpdate_%pname%.bat & echo.echo Updating Repo " & Chr(39) & "%~1" & Chr(39) & ">>GitUpdate_%pname%.bat & echo.git pull>>GitUpdate_%pname%.bat")
FileWriteLine($hFileOpen, "goto:eof")
FileWriteLine($hFileOpen, "")
FileWriteLine($hFileOpen, ":: Function to Sleep for specified miliseconds")
FileWriteLine($hFileOpen, ":sleep")
FileWriteLine($hFileOpen, "Set tempFile=%temp%\Null")
FileWriteLine($hFileOpen, "Ping 1.1.1.1 -n 1 -w %~1 >>%tempfile%")
FileWriteLine($hFileOpen, "del %tempfile%")
FileWriteLine($hFileOpen, "goto:eof")
FileClose($hFileOpen)
Return $batFile
EndFunc

Func ReplaceRsrvd($inString)
	$rtnString = StringReplace($inString, "<", "")
	$rtnString = StringReplace($rtnString, ">", "")
	$rtnString = StringReplace($rtnString, ":", "")
	$rtnString = StringReplace($rtnString, Chr(34), "")
	$rtnString = StringReplace($rtnString, "/", "")
	$rtnString = StringReplace($rtnString, "\", "")
	$rtnString = StringReplace($rtnString, "|", "")
	$rtnString = StringReplace($rtnString, "?", "")
	$rtnString = StringReplace($rtnString, "*", "")
	$rtnString = StringReplace($rtnString, " ", "_")
	Return $rtnString
EndFunc

;----------------------------------------------------------------------------------------------------------------------------------------------------------