#cs ------------------------------------------------------------------------------------------------------------------------------------------------------

 AutoIt Version: 3.3.15.0 (Beta)
 Author:         CaptainMidnite

 Script Function:	GitHubRepos - V3.0

 Release:			Public Release!

 Description:		AutoIt Functions to Download a Members Complete Repository Set.

 Functions:			GitSrcRepos($ghAddress, $dstDir, $ProjectName)
					Description: 	Downloads a complete list of a members repository set as a text file and saves it as SourceList.txt
					$ghAddress		=	GitHub Address - Ex: https://github.com/google
					$dstDir			=	Destination Directory for Source List - Ex: @ScriptDir
					$ProjectName	=	Name of Project to add to SourceList.txt name (Primarily used for processing multiple sources)
		Optional	$iNum			=	Used when processing multiple source repos to show what item number in the Progress GUI title
		Optional	$tCount			=	Used when processing multiple source repos to show total number of source repos in Progress GUI title

					WriteBatch($prjName, $dstDir)
					Description:	Creates a windows batch file "GitHub_Make_%Project Name%.bat" to process SourceList.txt. Running this batch file will
									download all repos from SourceList.txt and create an additonal batch file "GitUpdate_%Project Name%.bat" to use to
									update all of the downloaded repos. If function is used in a variable then the function will return the path to the
									batch file "GitHub_Make_%Project Name%.bat".
					$prjName		=	Project Name - Ex: Google_Github
					$dstDir			=	Destination Directory for "GitHub_Make_%Project Name%.bat"

					GitMultipleSrc($srcIni, $DestDir)
					Description:	Used for creating Multiple Source Lists and Batch files for different repo sources at the same time.
					$srcIni			=	Path to Source INI file (This file should be set up like a standard INI with General as the section name
										then the repo web address as the key and then the repos project name as the key value
					$DestDir		=	Destination Directory to store all SourceList.txt & Batch Files in.

					ReplaceRsrvd($inString)
					Description:	Used to Remove/Replace any reserved characters in the input string that may conflict with windows directory namespace
									or have conflicts within the batch files.
					$inString		=	Input String - Ex: Google_GitHub
					Example:		ReplaceRsrvd("Google* GitHub") = Returns: Google_GitHub


#ce -------------------------------------------------------------------------------------------------------------------------------------------------------

; Script Start - Add your code below here
; Globals
;----------------------------------------------------------------------------------------------------------------------------------------------------------
#include <Array.au3>
#include <File.au3>
;----------------------------------------------------------------------------------------------------------------------------------------------------------

GitMultipleSrc(@ScriptDir & "\MS_SourceList.ini", @ScriptDir)

; Functions
;----------------------------------------------------------------------------------------------------------------------------------------------------------
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
		If StringInStr($aLine, "list-item repo-list-item") = 0 Or StringInStr($aLine, "list-item repo-list-item") = 1 Then
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
		$sLine = StringReplace($sLine, '      <a class="list-item repo-list-item" href="', 'http://github.com')
		;remove trailing html marks from $sline
		$sLine = StringReplace($sLine, '">', "")
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
		$gtSource = GitSrcRepos($mArray[$i][0], $DestDir, $mArray[$i][1], $i, $mArray[0][0])
		If $gtSource = True Then
			$dstBatch = WriteBatch($mArray[$i][1], $DestDir)
			_ArrayAdd($oArray, $dstBatch)
		Else
			ConsoleWrite("Error: '" & $mArray[$i][1] & "' <---Not Available" & @CRLF)
		EndIf
	Next
	$oUBound = UBound($oArray) - 1
	_ArrayInsert($oArray, 0, $oUBound)
	_ArrayDisplay($oArray)
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

;----------------------------------------------------------------------------------------------------------------------------------------------------------