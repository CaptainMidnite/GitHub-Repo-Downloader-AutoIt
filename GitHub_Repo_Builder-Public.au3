#cs --------------------------------------------------------------------------------------------------------------------------------------------------------------

 AutoIt Version: 3.3.15.0 (Beta)
 Author:         CaptainMidnite

 Script Function:	GUI GitHub_Repo_Builder - v3.5

 Release:			Public Release!

 Description:	V3.0	GUI Version to Download a Members Complete Repository Set
						Includes the Ability to Just Download and Create Batch File for Later Download or Create Batch File, and Download all Repositories

						Included a new section in the GUI under the options menu for "Multiple Source Mode", use this if you need to grab all Repositories
						from multiple members at once. This process works similar to the Single Source Mode but you have to provide a approriately formatted
						ini file that contains the head address to the repo and the names of the projects that you want to have for them.

						Basic INI Example:
						[General]
						head address=project name
						https://github.com/angular=angular
						https://github.com/antirez=antirez
						...
						=======================================================================================================================================

						Additonaly you can also pass the settings in the ini file just create an additonal section in the ini called "settings" the settings
						keys that it will accept are as follows:
						prjName		=	Over All Project Name this is used to fill in the Project Name Field
						dstDir		=	Destination directory that all of the batch files and source lists as well as the downloaded files will be stored in
						buildOpt	=	This controls the mode radio buttons under step 4. Setting this to 1 will set the radio for Build Only setting this to
										2 will set the radio for Build and Execute. Any other valure or blank will set clear all radio buttons.

						Advanced INI Example:
						[Settings]
						prjName=MS_GitHub_All
						dstDir=D:\AutoIt\GitHub_Repo_Builder\MS_GitHub_All
						buildOpt=1

						[General]
						head address=project name
						https://github.com/angular=angular
						https://github.com/antirez=antirez
						...
						=======================================================================================================================================

						Also full example INI Files can be found in the folder 'Example_inis'

				V3.1	Added better error messages in the ini checking process to better inform the issue with the ini file.

				V3.2	Added error checking on source web address to be able to copy both user repos and users forked repos.
						Added shared global constants for form measurements and position and will now follow the position the user placed the form when switching
						between single source form and multiple source form.

				V3.3	Added startup check to make sure user has git installed.
						Added settings.ini file to store default settings and store last run settings.

				V3.5	Changed html string match for git repo location.
#ce --------------------------------------------------------------------------------------------------------------------------------------------------------------

; Script Start - Add your code below here
; Globals
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <InetConstants.au3>
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

; Start GUI.
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
ConsoleWrite(@CRLF & "Start Script Execution"& @CRLF)
;Set default form measurements and position...
Global $sHeight = @DesktopHeight
Global $sWidth = @DesktopWidth
Global $prgX = (@DesktopWidth / 2) - 153
Global $prgY = (@DesktopHeight / 2) - 64.5
Global $wWidth = 543
Global $wHeight = 255
Global $xLeft = ($sWidth / 2) - ($wWidth / 2)
Global $yTop = ($sHeight / 2) - ($wHeight / 2)
Global $sVers = 3.3
Global $settingsINI = @ScriptDir & "\preset.ini"
;Check and create ini file to store settings and presets in...
If FileExists($settingsINI) = 0 Then
	CreatSetini($settingsINI)
EndIf
;Check if git commands are installed allready...
If IniRead($settingsINI, "Settings", "GitChk", 0) = 0 Then
	CheckGit()
EndIf
;Check which mode to launch in based off the settings ini file...
If IniRead($settingsINI, "Settings", "Mode", 1) = 2 Then
	MSMode()
Else
	SSMode()
EndIf
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

; Functions
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Func GitSrcRepos($srcString, $DestDir, $ProjectName, $iNum = "", $tCount = "")
;Remove trailing slash if user entered
If StringRight($DestDir, 1) = "\" Then
	$DestDir = StringTrimRight($DestDir, 1)
EndIf
;Set temporary html file to download data to
$htmTemp = $DestDir & "\temp.html"
;Remove any reserved characters from the project name that may conflict with filesnames in windows
$rProjectName = ReplaceRsrvd($ProjectName)
;Set the Source List file name that will be outputed in the end
$srcLst = $DestDir & "\" & $rProjectName & "-SourceList.txt"
;If the Source List already exists then delete it so that we dont append to it and repeate repos
If FileExists($srcLst) = 1 Then
	FileDelete($srcLst)
EndIf
;Setting User Agent as a Mobile Device so GitHub will return all members repos to One file
HttpSetUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25")
;Download the repository with the $srcString and save it to the temporary html file
$iDownload = InetGet($srcString & "?tab=repositories", $htmTemp)
;Reset the current user agent to standard AutoIt user agent string
HttpSetUserAgent("")
If $iDownload > 0 Then
	$aArray = ""
	;Read the contents of the temporary html file to $aArray
	_FileReadToArray($htmTemp, $aArray)
	;Uncomment line below if you want to view the $aArray before processing
	;_ArrayDisplay($aArray, "$aArray")
	;Create a progress bar to display the progress of processing the temp file and creating the Source List
	If $iNum = "" Or $tCount = "" Then
		;If $iNum or $tCount are left blank then load standard title on progress bar
		ProgressOn("Processing File", "Loading File Please Wait", "Loading Resource ~ 0%")
	Else
		;If $iNum and $tCount are provided then load title with item number of total files
		ProgressOn("Processing File: " & $iNum & " of " & $tCount, "Loading File Please Wait", "Loading Resource ~ 0%")
	EndIf
	;Delete the temporary html file
	;MsgBox($MB_OK, "Pause", "Press OK to Continue")
	FileDelete($htmTemp)
	;Delay to let the user read the progress window information
	Sleep(1500)
	;Step through $aArray from end to begining and process each line
	For $i = $aArray[0] To 1 Step - 1
		;Set step in low to high order for progress bar
		$step = $aArray[0] - $i
		;Using $step determine current progress
		$prgss = ($step / $aArray[0]) * 100
		;Format $prgss to only 2 decimal places
		$prgss = StringFormat("%.2f", $prgss)
		;load the current line to $aLine
		$aLine = $aArray[$i]
		;Check if line doesnt contain or begins with "list-item repo-list-item"
		If StringInStr($aLine, 'class="d-block"') = 0 Or StringInStr($aLine, 'class="d-block"') = 1 Then
			;If it doesnt contain or begins with then delete the line
			_ArrayDelete($aArray, $i)
		EndIf
		;Set the current progress and progress window text to let the user know where the process is at
		ProgressSet($prgss, "Lines Remaining: " & $i & " ~ " & $prgss & "%", "Parsing Downloaded File")
	Next
	;Get the new length of the array
	$aUbound = UBound($aArray) - 1
	;Uncomment line below if you want to view the $aArray before processing
	;_ArrayDisplay($aArray)
	;Create and Open the Source List file for writing
	Local $hFileOpen = FileOpen($srcLst, $FO_APPEND)
	;Set progress to 100% and update text to reflect that we are writing to the file
	ProgressSet(100, "Please Wait", "Writing Text to SourceList.txt")
	;Loop through $aArray from begining to end with its new legth and process each line
	For $i = 1 To $aUbound Step + 1
		;load the current line to $sLine
		$sLine = $aArray[$i]
		;Replace the begining html marks of the line with github.com address
		$sLine = StringReplace($sLine, '  <a href="', 'http://github.com')
		;remove trailing html marks from $sline
		$sLine = StringReplace($sLine, '" class="d-block">', "")
		;Write the modified line to the Source List file
		FileWriteLine($hFileOpen, $sLine)
	Next
	;Delay for 1 second to let user read the screen
	Sleep(1000)
	;Turn off the progress bar window
	ProgressOff()
	;Close the Source List file for writing
	FileClose($hFileOpen)
	Return True
Else
	Return False
EndIf
EndFunc

Func WriteBatch($ProjectName, $DestDir)
;Remove trailing slash if user entered
If StringRight($DestDir, 1) = "\" Then
	$DestDir = StringTrimRight($DestDir, 1)
EndIf
;Remove any reserved characters from the project name that may conflict with filesnames in windows
$rProjectName = ReplaceRsrvd($ProjectName)
;Set the full path for the batch file to be written to
$batFile = $DestDir & "\GitHub_Make_" & $rProjectName & ".bat"
;Create and open the batch file for writing
Local $hFileOpen = FileOpen($batFile, $FO_APPEND)
;All FileWriteLine( lines here after are writing the batch file which will process the source list and
;download each repo then create a update repo batch file to use to update the contents later
FileWriteLine($hFileOpen, "@echo off")
FileWriteLine($hFileOpen, "echo Starting GitHub Make")
FileWriteLine($hFileOpen, "echo Clearing Previous Variables")
FileWriteLine($hFileOpen, "set " & Chr(34) & "num=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "pName=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "dstDir=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "srcLst=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "srcCount=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "var=" & Chr(34))
FileWriteLine($hFileOpen, "Set " & Chr(34) & "str=" & Chr(34))
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "echo Setting Variables")
FileWriteLine($hFileOpen, "set num=0")
FileWriteLine($hFileOpen, "Set pName=" & $rProjectName)
FileWriteLine($hFileOpen, "Set dstDir=" & $rProjectName)
FileWriteLine($hFileOpen, "Set srcLst=" & $rProjectName & "-SourceList.txt")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "::Check and make sure that the srcLst path exists")
FileWriteLine($hFileOpen, "echo Starting PreChecks")
FileWriteLine($hFileOpen, "echo Checking Source List Exists")
FileWriteLine($hFileOpen, "Call:sleep 500")
FileWriteLine($hFileOpen, "IF NOT EXIST " & Chr(34) & "%srcLst%" & Chr(34) & " (")
FileWriteLine($hFileOpen, "   echo ERROR Cannot Locate SourceList: %srcLst%")
FileWriteLine($hFileOpen, "   echo Please check the Name of the SourceList and make sure its in this directory!")
FileWriteLine($hFileOpen, "   echo Exiting Script Now!")
FileWriteLine($hFileOpen, "   Exit /B")
FileWriteLine($hFileOpen, ") ELSE (")
FileWriteLine($hFileOpen, "   echo Found SourceList " & Chr(39) & "%srcLst%" & Chr(39) & "! Continuing")
FileWriteLine($hFileOpen, "   Call:sleep 500")
FileWriteLine($hFileOpen, ")")
FileWriteLine($hFileOpen, "::Check and see if dstDir needs to be created")
FileWriteLine($hFileOpen, "echo Checking for Destination Directory")
FileWriteLine($hFileOpen, "Call:sleep 500")
FileWriteLine($hFileOpen, "IF NOT EXIST " & Chr(34) & "%dstDir%" & Chr(34) & " (")
FileWriteLine($hFileOpen, "   echo Destination Directory Does Not Exist")
FileWriteLine($hFileOpen, "   echo Creating GitHub Directory for %pName%")
FileWriteLine($hFileOpen, "   mkdir %dstDir%")
FileWriteLine($hFileOpen, "   Call:sleep 500")
FileWriteLine($hFileOpen, "   echo Copying Source List to Destination Directory")
FileWriteLine($hFileOpen, "   copy %srcLst% %dstDir%")
FileWriteLine($hFileOpen, "   Call:sleep 500")
FileWriteLine($hFileOpen, ") ELSE (")
FileWriteLine($hFileOpen, "   echo Destination Directory Already Exists")
FileWriteLine($hFileOpen, "   echo Copying Source List to Destination Directory")
FileWriteLine($hFileOpen, "   copy %srcLst% %dstDir%")
FileWriteLine($hFileOpen, "   Call:sleep 500")
FileWriteLine($hFileOpen, ")")
FileWriteLine($hFileOpen, "echo Moving into GitHub Directory")
FileWriteLine($hFileOpen, "cd %dstDir%")
FileWriteLine($hFileOpen, "echo Parsing Source Repo List")
FileWriteLine($hFileOpen, "Call:sleep 1000")
FileWriteLine($hFileOpen, "for /f %%C in (" & Chr(39) & "Find /V /C " & Chr(34) & "" & Chr(34) & " ^< %srcLst%" & Chr(39) & ") do set srcCount=%%C")
FileWriteLine($hFileOpen, "echo Total Repos to Cloan %srcCount%")
FileWriteLine($hFileOpen, "Call:sleep 500")
FileWriteLine($hFileOpen, "echo Completed Initalization Steps Successfully!")
FileWriteLine($hFileOpen, "echo Prepare to Start Processing Repos")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "echo Starting Cloaning Repositories Please wait")
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
FileWriteLine($hFileOpen, "echo Checking for Existing GitUpdate Batch File")
FileWriteLine($hFileOpen, "Call:sleep 1500")
FileWriteLine($hFileOpen, "If EXIST " & Chr(34) & "GitUpdate_%pname%.bat" & Chr(34) & " (")
FileWriteLine($hFileOpen, "	echo Found existing file GitUpdate_%pname%.bat!")
FileWriteLine($hFileOpen, "	echo Removing File!")
FileWriteLine($hFileOpen, "	Call:sleep 1500")
FileWriteLine($hFileOpen, "	DEL " & Chr(34) & "GitUpdate_%pname%.bat" & Chr(34))
FileWriteLine($hFileOpen, "	echo File Removed Successfully!")
FileWriteLine($hFileOpen, "	Call:sleep 1500")
FileWriteLine($hFileOpen, ") ELSE (")
FileWriteLine($hFileOpen, "	echo No Existing Update File Found")
FileWriteLine($hFileOpen, "	Call:sleep 1500")
FileWriteLine($hFileOpen, ")")
FileWriteLine($hFileOpen, "echo Getting Repos Parent Directory")
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
FileWriteLine($hFileOpen, "echo Cleaning Up Old Files")
FileWriteLine($hFileOpen, "echo Removing " & Chr(39) & "FileList.txt" & Chr(39))
FileWriteLine($hFileOpen, "del FileList.txt")
FileWriteLine($hFileOpen, "echo Removing " & Chr(39) & "Null" & Chr(39))
FileWriteLine($hFileOpen, "del Null")
FileWriteLine($hFileOpen, "echo Removing " & Chr(39) & "%srcLst%" & Chr(39))
FileWriteLine($hFileOpen, "del %srcLst%")
FileWriteLine($hFileOpen, "echo Returning to Original Directory")
FileWriteLine($hFileOpen, "cd ..")
FileWriteLine($hFileOpen, "del Null")
FileWriteLine($hFileOpen, "echo Completed File Cleanup")
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
;Close the batch file for writing
FileClose($hFileOpen)
;Return the full path to the batch file (Primarily used in the GUI) to the called function
Return $batFile
EndFunc

Func GitMultipleSrc($srcIni, $DestDir)
	;Create an empty array to return to the call function
	Local $oArray = ["0"]
	;Read the SourceList ini file to $mArray
	$mArray = IniReadSection($srcIni, "General")
	$ckmArray = UBound($mArray, 2)
	ConsoleWrite("$ckmArray = " & $ckmArray & @CRLF)
	If $ckmArray < 2 Then
		MsgBox($MB_OK, "Fatal Error", "There is an error in the config file, please consult the instructions and correct to continue!" & @CRLF & @CRLF & "Exiting Now...")
		Exit
	EndIf
	;Remove trailing slash if user entered
	If StringRight($DestDir, 1) = "\" Then
		$DestDir = StringTrimRight($DestDir, 1)
	EndIf
	;Check if Destination Directory Exists, if not create it
	If FileExists($DestDir) = 0 Then
		DirCreate($DestDir)
	EndIf
	;Uncomment line below if you want to view the $aArray before processing
	;_ArrayDisplay($mArray)
	;Loop through each line of $mArray and run both GitSrcRepos & WriteBatch functions using the key and value from the array
	For $i = 1 To $mArray[0][0] Step + 1
		$ghAddress = $mArray[$i][0]
		If StringInStr($ghAddress, "?tab=repositories") > 1 Then
			$brkPos = StringInStr($ghAddress, '?tab') - 1
			$ghAddress = StringLeft($ghAddress, $brkPos)
		EndIf
		$gtSource = GitSrcRepos($ghAddress, $DestDir, $mArray[$i][1], $i, $mArray[0][0])
		If $gtSource = True Then
			$dstBatch = WriteBatch($mArray[$i][1], $DestDir)
			_ArrayAdd($oArray, $dstBatch)
		Else
			ConsoleWrite("Error: '" & $mArray[$i][1] & "' <---Not Available" & @CRLF)
		EndIf
	Next
	$oUBound = UBound($oArray) - 1
	;_ArrayInsert($oArray, 0, $oUBound)
	$oArray[0] = $oUBound
	;_ArrayDisplay($oArray)
	Return $oArray
EndFunc

Func ReplaceRsrvd($inString)
	;Remove the reserved character ">" from $inString
	$rtnString = StringReplace($inString, "<", "")
	;Remove the reserved characters's from $rtnString
	$rtnString = StringReplace($rtnString, ">", "")
	$rtnString = StringReplace($rtnString, ":", "")
	$rtnString = StringReplace($rtnString, Chr(34), "")
	$rtnString = StringReplace($rtnString, "/", "")
	$rtnString = StringReplace($rtnString, "\", "")
	$rtnString = StringReplace($rtnString, "|", "")
	$rtnString = StringReplace($rtnString, "?", "")
	$rtnString = StringReplace($rtnString, "*", "")
	$rtnString = StringReplace($rtnString, " ", "_")
	;Return $rtnString to the called function
	Return $rtnString
EndFunc

Func SetWinPos($frmName)
	$wPos = WinGetPos($frmName)
	$xLeft = $wPos[0]
	$yTop = $wPos[1]
EndFunc

Func CreatSetini($strINIPath)
	;Create & Write default settings into ini file...
	IniWrite($strINIPath, "General", "Name", @ScriptName)
	IniWrite($strINIPath, "General", "Version", $sVers)
	IniWrite($strINIPath, "Settings", "GitChk", 0)
	IniWrite($strINIPath, "Settings", "Mode", 1)
	IniWrite($strINIPath, "SSMode", "defAddress", "https://github.com/google")
	IniWrite($strINIPath, "SSMode", "defPrj", "Google_GitHub_Source")
	IniWrite($strINIPath, "SSMode", "defDest", "ScriptDir")
	IniWrite($strINIPath, "SSMode", "defExec", 0)
	IniWrite($strINIPath, "MSMode", "defINI", "")
	IniWrite($strINIPath, "MSMode", "defPrj", "Project Name")
	IniWrite($strINIPath, "MSMode", "defDest", "ScriptDir")
	IniWrite($strINIPath, "MSMode", "defExec", 0)
EndFunc

Func CheckGit()
	;This function checks to see if Git for windows is currently installed and available via command line.
	;If its not installed then it will prompt the user to download and install git and set the environment variables necessary
	; to have git available via the command line in all directories.
	Local $iPID = Run(@ComSpec & ' /C git --version', @ScriptDir, @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)
	ConsoleWrite($sOutput & @CRLF)
	ConsoleWrite(EnvGet("PATH") & @CRLF)
	If StringInStr($sOutput, "'git' is not recognized") > 0 Then
		$usrAlert = MsgBox($MB_YESNO, "Git Not Found", "It looks like git is not currently installed on your computer. Would you like to download and install git now?")
		If $usrAlert = 6 Then
			$sUrl = "https://github-cloud.s3.amazonaws.com/releases/23216272/ae9d002c-8a5b-11e6-911f-6e274211fcff.exe?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAISTNZFOVBIJMK3TQ%2F20161011%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20161011T161913Z&X-Amz-Expires=300&X-Amz-Signature=40c242d366181faafaa19ee7327c775e66d0cabc29202c6a1390042101a0cdd4&X-Amz-SignedHeaders=host&actor_id=19823223&response-content-disposition=attachment%3B%20filename%3DGit-2.10.1-64-bit.exe&response-content-type=application%2Foctet-stream"
			Local $dlSize = InetGetSize($sURL)
			Local $hDownload = InetGet($sURL, @TempDir & "\GitInstaller.exe", 2, 0)
			ProgressOn("File Download", "Downloading Git For Windows", "0%", $prgX, $prgY, $DLG_NOTONTOP + $DLG_MOVEABLE)
			Do
				Sleep(125)
				$hData = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
				$hProgress = StringFOrmat("%.2f",($hData / $dlsize) * 100)
				ProgressSet($hProgress, $hProgress & "%")
			Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
			ProgressSet($hProgress, $hProgress & "%", "Download Completed!")
			Sleep(1500)
			ProgressOff()
			MsgBox($MB_OK, "Installer Confirmation", "Follow through the installation of Git for Windows and this program will pickup back up once completed.")
			Local $instPID = Run(@TempDir & "\GitInstaller.exe", @TempDir, @SW_SHOW, $STDOUT_CHILD)
			ProcessWaitClose($instPID)
			Sleep(1000)
			$sysPath = EnvGet("PATH")
			If StringInStr($sysPath, @LocalAppDataDir & "\Programs\Git\cmd") = 0 Then
				EnvSet("PATH", $sysPath & ";" & @LocalAppDataDir & "\Programs\Git\cmd")
			EndIf
			ProcessClose("explorer.exe")
			Sleep(3500)
			Run("explorer.exe")
		EndIf
	ElseIf StringInStr($sOutput, "git version ") > 0 Then
		IniWrite($settingsINI, "Settings", "GitChk", 1)
	EndIf
EndFunc

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

; GUI Functions
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Func SSMode()
#Region ### START Koda GUI section ### Form=D:\AutoIt\GitHub_Repo_Builder\GitHub_Repo_Builder-SSMode.kxf
$Form2 = GUICreate("GitHub Repo Builder - Single Source Mode", $wWidth, $wHeight, $xLeft, $yTop)
$Opt_men = GUICtrlCreateMenu("Options")
$CapMul_men = GUICtrlCreateMenuItem("Multiple Source Mode", $Opt_men)
$SDefault_men = GUICtrlCreateMenuItem("Save Current Settings as Default", $Opt_men)
$Label1 = GUICtrlCreateLabel("1: Please enter the site page for the repo you wish to download", 8, 8, 301, 17)
$Label2 = GUICtrlCreateLabel("Web Address:", 8, 32, 71, 17)
$SrcAdd_bx = GUICtrlCreateInput(IniRead($settingsINI, "SSMode", "defAddress", ""), 80, 30, 451, 21)
$Label3 = GUICtrlCreateLabel("2: Enter a name for your project below", 8, 56, 183, 17)
$Label4 = GUICtrlCreateLabel("Project Name:", 8, 80, 71, 17)
$Proj_bx = GUICtrlCreateInput(IniRead($settingsINI, "SSMode", "defPrj", ""), 80, 78, 451, 21)
$Label5 = GUICtrlCreateLabel("3: Enter or select a destination directory for the project below", 8, 104, 289, 17)
$Label6 = GUICtrlCreateLabel("Destination:", 8, 128, 60, 17)
If IniRead($settingsINI, "SSMode", "defDest", "ScriptDir") = "ScriptDir" Then
	$DestDir_bx = GUICtrlCreateInput(@ScriptDir, 80, 128, 371, 21)
Else
	$DestDir_bx = GUICtrlCreateInput(IniRead($settingsINI, "SSMode", "defDest", "ScriptDir"), 80, 128, 371, 21)
EndIf
$Build_btn = GUICtrlCreateButton("Build", 8, 200, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Cancel_btn = GUICtrlCreateButton("Cancel", 120, 200, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Browse_btn = GUICtrlCreateButton("Browse", 456, 126, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Label7 = GUICtrlCreateLabel("4: Execute After Retriving Source", 8, 154, 162, 17)
$Build_rd = GUICtrlCreateRadio("Build Only", 8, 176, 73, 17)
If IniRead($settingsINI, "MSMode", "defExec", 0) = 0 Then
	GUICtrlSetState($Build_rd, $GUI_CHECKED)
EndIf
$BuildEX_rd = GUICtrlCreateRadio("Build and Execute", 104, 176, 113, 17)
If IniRead($settingsINI, "MSMode", "defExec", 0) = 1 Then
	GUICtrlSetState($BuildEX_rd, $GUI_CHECKED)
EndIf
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
			$fsFolder = FileSelectFolder("Select Destination Folder", @ScriptDir)
			$dstFolder = $fsFolder & "\" & ReplaceRsrvd(GUICtrlRead($Proj_bx))
			GUICtrlSetData($DestDir_bx, $dstFolder)
			GUICtrlSetData($Proj_bx, ReplaceRsrvd(GUICtrlRead($Proj_bx)))
		Case $Build_btn
			$rdbStatus = GUICtrlRead($Build_rd)
			$rdeStatus = GUICtrlRead($BuildEX_rd)
			If $rdbStatus = 1 Then
				$ghAddress = GUICtrlRead($SrcAdd_bx)
				If StringInStr($ghAddress, "?tab=repositories") > 1 Then
					$brkPos = StringInStr($ghAddress, '?tab') - 1
					$ghAddress = StringLeft($ghAddress, $brkPos)
					GUICtrlSetData($SrcAdd_bx, $ghAddress, "https://github.com/google")
					MsgBox($MB_OK, "Error In Web Address", "We corrected an error in the web address you provided for the source repo. The new Address is now '" & $ghAddress & "'.", 60, $Form2)
				EndIf
				$dstDir = GUICtrlRead($DestDir_bx)
				$prjName = ReplaceRsrvd(GUICtrlRead($Proj_bx))
				$dstFolder = $dstDir & "\" & $prjName
				GUISetState(@SW_HIDE)
				GitSrcRepos($ghAddress, $dstDir, $prjName)
				WriteBatch($prjName, $dstDir)
				Exit
			ElseIf $rdeStatus = 1 Then
				$ghAddress = GUICtrlRead($SrcAdd_bx)
				$dstDir = GUICtrlRead($DestDir_bx)
				$prjName = ReplaceRsrvd(GUICtrlRead($Proj_bx))
				$dstFolder = $dstDir & "\" & $prjName
				GUISetState(@SW_HIDE)
				GitSrcRepos($ghAddress, $dstDir, $prjName)
				$bdBat = WriteBatch($prjName, $dstDir)
				RunWait($bdBat, $dstDir)
				Exit
			Else
				MsgBox($MB_OK, "Error", "Please select a build option under step 4 to continue")
			EndIf
		Case $CapMul_men
			SetWinPos($Form2)
			GUIDelete($Form2)
			MSMode()
		Case $SDefault_men
			$usrMode = MsgBox($MB_YESNO, "Set Default Mode", "Do you want to set the default mode to Single Source Mode?")
			If $usrMode = 6 Then
				IniWrite($settingsINI, "Settings", "Mode", 1)
			EndIf
			IniWrite($settingsINI, "SSMode", "defAddress", GUICtrlRead($SrcAdd_bx))
			IniWrite($settingsINI, "SSMode", "defPrj", GUICtrlRead($Proj_bx))
			If GUICtrlRead($DestDir_bx) = @ScriptDir Then
					IniWrite($settingsINI, "SSMode", "defDest", "ScriptDir")
			Else
				IniWrite($settingsINI, "SSMode", "defDest", GUICtrlRead($DestDir_bx))
			EndIf
			If GUICtrlRead($Build_rd) = 1 Then
				IniWrite($settingsINI, "SSMode", "defExec", 0)
			ElseIf GUICtrlRead($BuildEX_rd) = 1 Then
				IniWrite($settingsINI, "SSMode", "defExec", 1)
			Else
				IniWrite($settingsINI, "SSMode", "defExec", 0)
			EndIf
		Case $Cancel_btn
			Exit
	EndSwitch
WEnd
EndFunc

Func MSMode()
#Region ### START Koda GUI section ### Form=D:\AutoIt\GitHub_Repo_Builder\GitHub_Repo_Builder-MSMode.kxf
$Form3 = GUICreate("GitHub Repo Builder - Multiple Source Mode", $wWidth, $wHeight, $xLeft, $yTop)
$Opt_menu = GUICtrlCreateMenu("Options")
$ssource_men = GUICtrlCreateMenuItem("Single Source Mode", $Opt_menu)
$SDefault_men = GUICtrlCreateMenuItem("Save Current Settings as Default", $Opt_menu)
$Label1 = GUICtrlCreateLabel("1: Please enter or select the Multiple Source List INI file", 8, 8, 264, 17)
$Label2 = GUICtrlCreateLabel("INI File:", 8, 32, 40, 17)
$srcini_tbx = GUICtrlCreateInput(IniRead($settingsINI, "MSMode", "defIni", ""), 80, 30, 375, 21)
$iniBrowse_btn = GUICtrlCreateButton("Browse", 464, 29, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Label3 = GUICtrlCreateLabel("2: Enter a name for your project below", 8, 56, 183, 17)
$Proj_bx = GUICtrlCreateInput(IniRead($settingsINI, "MSMode", "defPrj", "Project Name"), 80, 78, 451, 21)
$Label4 = GUICtrlCreateLabel("Destination:", 8, 128, 60, 17)
If IniRead($settingsINI, "MSMode", "defDest", "ScriptDir") = "ScriptDir" Then
	$dest_tbx = GUICtrlCreateInput(@ScriptDir, 80, 128, 375, 21)
Else
	$dest_tbx = GUICtrlCreateInput(IniRead($settingsINI, "MSMode", "defDest", ""), 80, 128, 375, 21)
EndIf
$destBrowse_btn = GUICtrlCreateButton("Browse", 464, 126, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Label5 = GUICtrlCreateLabel("3: Enter or select a destination directory for the project below", 8, 104, 289, 17)
$Build_rd = GUICtrlCreateRadio("Build Only", 8, 176, 73, 17)
If IniRead($settingsINI, "MSMode", "defExec", 0) = 0 Then
	GUICtrlSetState($Build_rd, $GUI_CHECKED)
EndIf
$BuildEX_rd = GUICtrlCreateRadio("Build and Execute", 88, 176, 113, 17)
If IniRead($settingsINI, "MSMode", "defExec", 0) = 1 Then
	GUICtrlSetState($BuildEX_rd, $GUI_CHECKED)
EndIf
$Build_btn = GUICtrlCreateButton("Build", 8, 200, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Cancel_btn = GUICtrlCreateButton("Cancel", 112, 200, 75, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$Label6 = GUICtrlCreateLabel("Project Name:", 8, 80, 71, 17)
$Label7 = GUICtrlCreateLabel("4: Execute After Retriving Source", 8, 152, 162, 17)
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
		Case $ssource_men
			SetWinPos($Form3)
			GUIDelete($Form3)
			SSMode()
		Case $iniBrowse_btn
			$fsFile = FileOpenDialog("Select Multi Source INI", @ScriptDir, "INI files (*.ini)|All (*.*)", 1)
			GUICtrlSetData($srcini_tbx, $fsFile)
			$sNames = IniReadSectionNames($fsFile)
			For $i = 1 To $sNames[0] Step + 1
				If $sNames[$i] = "Settings" Then
					$usrChoice = MsgBox($MB_YESNO, "Found Settings", "Found Configuration Settings in INI file!" & @CRLF & @CRLF & "Do you want to load these settings now?")
					If $usrChoice = 6 Then
						;User Selected Yes!
						$prjName = IniRead($fsFile, "Settings", "prjName", "")
						$dstDir = IniRead($fsFile, "Settings", "dstDir", "")
						$buildOpt = IniRead($fsFile, "Settings", "buildOpt", 1)
						GUICtrlSetData($Proj_bx, $prjName)
						GUICtrlSetData($dest_tbx, $dstDir)
						If $buildOpt = 1 Then
							GUICtrlSetState($Build_rd, $GUI_CHECKED)
							GUICtrlSetState($BuildEX_rd, $GUI_UNCHECKED)
						ElseIf $buildOpt = 2 Then
							GUICtrlSetState($BuildEX_rd, $GUI_CHECKED)
							GUICtrlSetState($Build_rd, $GUI_UNCHECKED)
						Else
							GUICtrlSetState($BuildEX_rd, $GUI_UNCHECKED)
							GUICtrlSetState($Build_rd, $GUI_UNCHECKED)
						EndIf
					EndIf
				EndIf
			Next
		Case $destBrowse_btn
			$fsFolder = FileSelectFolder("Select Destination Folder", @ScriptDir)
			$prjName = ReplaceRsrvd(GUICtrlRead($Proj_bx))
			$dstFolder = StringReplace($fsFolder & "\" & $prjName, "\\", "\")
			GUICtrlSetData($dest_tbx, $dstFolder)
			GUICtrlSetData($Proj_bx, $prjName)
		Case $Build_btn
			$rdbStatus = GUICtrlRead($Build_rd)
			$rdeStatus = GUICtrlRead($BuildEX_rd)
			If $rdbStatus = 1 Then
				$dstDir = GUICtrlRead($dest_tbx)
				$prjName = GUICtrlRead($Proj_bx)
				$sINI = GUICtrlRead($srcini_tbx)
				GUISetState(@SW_HIDE)
				$rArray = GitMultipleSrc($sINI, $dstDir)
				;_ArrayDisplay($rArray)
				Exit
			ElseIf $rdeStatus = 1 Then
				$dstDir = GUICtrlRead($dest_tbx)
				$prjName = GUICtrlRead($Proj_bx)
				$sINI = GUICtrlRead($srcini_tbx)
				GUISetState(@SW_HIDE)
				$rArray = GitMultipleSrc($sINI, $dstDir)
				;_ArrayDisplay($rArray)
				For $i = 1 To $rArray[0] Step + 1
					RunWait($rArray[$i], $dstDir)
				Next
				Exit
			Else
				MsgBox($MB_OK, "Error", "Please select a build option under step 4 to continue")
			EndIf
		Case $SDefault_men
			$usrMode = MsgBox($MB_YESNO, "Set Default Mode", "Do you want to set the default mode to Multiple Source Mode?")
			If $usrMode = 6 Then
				IniWrite($settingsINI, "Settings", "Mode", 2)
			EndIf
			IniWrite($settingsINI, "MSMode", "defINI", GUICtrlRead($srcini_tbx))
			IniWrite($settingsINI, "MSMode", "defPrj", GUICtrlRead($Proj_bx))
			If GUICtrlRead($dest_tbx) = @ScriptDir Then
					IniWrite($settingsINI, "MSMode", "defDest", "ScriptDir")
			Else
				IniWrite($settingsINI, "MSMode", "defDest", GUICtrlRead($dest_tbx))
			EndIf
			If GUICtrlRead($Build_rd) = 1 Then
				IniWrite($settingsINI, "MSMode", "defExec", 0)
			ElseIf GUICtrlRead($BuildEX_rd) = 1 Then
				IniWrite($settingsINI, "MSMode", "defExec", 1)
			Else
				IniWrite($settingsINI, "MSMode", "defExec", 0)
			EndIf
		Case $Cancel_btn
			Exit
	EndSwitch
WEnd
EndFunc

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------