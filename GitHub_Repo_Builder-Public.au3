#cs ---------------------------------------------------------------------------------------------------------------------------------------------------------------------

 AutoIt Version: 3.3.15.0 (Beta)
 Author:         CaptainMidnite

 Script Function:	GUI GitHub_Repo_Builder - v3.7

 Current Version:	V4.0

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
						=================================================================================================================================================

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
						=================================================================================================================================================

						Also full example INI Files can be found in the folder 'Example_inis'

				V3.1	Added better error messages in the ini checking process to better inform the issue with the ini file.

				V3.2	Added error checking on source web address to be able to copy both user repos and users forked repos.
						Added shared global constants for form measurements and position and will now follow the position the user placed the form when switching
						between single source form and multiple source form.

				V3.3	Added startup check to make sure user has git installed.
						Added settings.ini file to store default settings and store last run settings.

				V3.5	Changed html string match for git repo location.

				V3.6	During startup will check clipboard for a copied github address and ask user if they want to use this as the source web address and
						populate based on the users response.

				V3.7	Added new function to request users repos using the GitHub API (Faster, and more complete results) included progress bar for request process

				V3.8	Updated some GitHub API functions added in previous version to handle users with less than 100 repos. Previously the application would fail
						with any user repos that would only populate one page of results. Also added some additional debug options for both Uncompiled and Compiled
						versions of the application for testing.

				V3.9	Fixed an issue where API could not retrieve repos if the Web Address ended with "/". Added checks within the API to remove this character so
						it doesnt get parsed as part of the user name, as well added a portion of code to remove this when using the URL from the clipboard.

				V4.0	Updated all message boxs with the TopMost flag so message boxes dont get lost behind the GUI.

#ce ---------------------------------------------------------------------------------------------------------------------------------------------------------------------

; Script Start - Add your code below here
; Globals
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#include <Array.au3>
#include <AutoItConstants.au3>
#include <ButtonConstants.au3>
#include <Constants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <InetConstants.au3>
#include <MsgBoxConstants.au3>
#include <StaticConstants.au3>
#include <String.au3>
#include <WinHttpConstants.au3>
#include <WindowsConstants.au3>
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; Start GUI.
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
Global $aUrl = "https://api.github.com" ;>> GitHub API Head URL
If StringInStr(@ScriptFullPath, ".au3") > 0 Then
	Global $debug = True ;>> Set to true to get increased debug messaging
Else
	Global $debug = False ;>> Dont use debug mode once compiled
EndIf

;Check and create ini file to store settings and presets in...
If FileExists($settingsINI) = 0 Then
	CreatSetini($settingsINI)
EndIf
;Check if git commands are installed allready...
If IniRead($settingsINI, "Settings", "GitChk", 0) = 0 Then
	CheckGit()
EndIf
;Debug Mode Overide when compiled!
If IniRead($settingsINI, "Settings", "Debug", 0) = 0 And StringInStr(@ScriptFullPath, ".exe") > 0 Then
	Global $debug = False
ElseIf IniRead($settingsINI, "Settings", "Debug", 0) <> 0 And StringInStr(@ScriptFullPath, ".exe") > 0 Then
	Global $debug = True
EndIf
;Check which mode to launch in based off the settings ini file...
If IniRead($settingsINI, "Settings", "Mode", 1) = 2 Then
	MSMode()
Else
	SSMode()
EndIf
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; Functions
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Func GitSrcRepos($srcString, $DestDir, $ProjectName, $iNum = "", $tCount = "")
	;Remove trailing slash if user entered
	If StringRight($DestDir, 1) = "\" Then
		$DestDir = StringTrimRight($DestDir, 1)
	EndIf
	;Remove any reserved characters from the project name that may conflict with filesnames in windows
	$rProjectName = ReplaceRsrvd($ProjectName)
	;Set the Source List file name that will be outputed in the end
	$srcLst = $DestDir & "\" & $rProjectName & "-SourceList.txt"
	;If the Source List already exists then delete it so that we dont append to it and repeate repos
	If FileExists($srcLst) = 1 Then
		FileDelete($srcLst)
	EndIf
	;Create an empty variable for the array
	$aArray = ""
	;Extract the GitHub User from the src string
	$sUser = StringReplace($srcString, "https://github.com/", "")
	$sUser = StringReplace($sUser, "http://github.com/", "")
	$sUser = StringReplace($sUser, "github.com/", "")
	;Get the page range for the repo requests
	$pages = GetPageRange($sUser, False)
	;Get the Users Repos and retun in array
	$aArray = GetRepos($sUser, $pages, False)
	;_ArrayDisplay($aArray)
	;Create and Open the Source List file for writing
	Local $hFileOpen = FileOpen($srcLst, $FO_APPEND)
	;Set progress to 100% and update text to reflect that we are writing to the file
	ProgressSet(100, "Please Wait", "Writing Text to SourceList.txt")
	;Loop through $aArray from begining to end with its new legth and process each line
	For $i = 1 To $aArray[0] Step + 1
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
EndFunc

Func GitMultipleSrc($srcIni, $DestDir)
	;Create an empty array to return to the call function
	Local $oArray = ["0"]
	;Read the SourceList ini file to $mArray
	$mArray = IniReadSection($srcIni, "General")
	$ckmArray = UBound($mArray, 2)
	ConsoleWrite("$ckmArray = " & $ckmArray & @CRLF)
	If $ckmArray < 2 Then
		MsgBox($MB_OK + $MB_TOPMOST, "Fatal Error", "There is an error in the config file, please consult the instructions and correct to continue!" & @CRLF & @CRLF & "Exiting Now...")
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
		$usrAlert = MsgBox($MB_YESNO + $MB_TOPMOST, "Git Not Found", "It looks like git is not currently installed on your computer. Would you like to download and install git now?")
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
			MsgBox($MB_OK + $MB_TOPMOST, "Installer Confirmation", "Follow through the installation of Git for Windows and this program will pickup back up once completed.")
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

Func GetRepos($user, $pages = 100, $debug = False)
Local $aRepos[1] = ["0"]

If StringRight($user, 1) = "/" Then $user = StringLeft($user, (StringLen($user) - 1))

ProgressOn("Get Repos", "Requesting Repos from GitHub API", "0.00% ~ Complete", $prgX, $prgY)

For $i = 1 To $pages Step + 1
	$sURL = $aURL & "/users/" & $user & "/repos?page=" & $i & "&per_page=100&"
	If $debug = True Then ConsoleWrite("URL: " & $sURL & @CRLF)
	$sGet = HttpGet($sURL)
	$aData = StringSplit($sGet, ",")
	$progress = ($i / $pages) * 100
	$sprogress = StringFormat("%.2f", $progress)
	ProgressSet($progress, $sprogress & "% ~ Complete")
	If $debug = True Then _ArrayDisplay($aData, "Returned Data")
	If $aData[0] > 1 Then
		For $j = 1 To $aData[0] Step + 1
			$line = $aData[$j]
			If StringInStr($line, "clone_url") <> 0 Then
				$cline = StringSplit($line, ":")
				If $debug = True Then _ArrayDisplay($cline, "Line Data")
				$data = StringReplace($cline[2] & ":" & $cline[3], Chr(34), "")
				_ArrayAdd($aRepos, $data)
				$aRepos[0] = UBound($aRepos) - 1
			EndIf
		Next
	Else
		ExitLoop
	EndIf
Next
ProgressSet(100, "100.00% ~ Complete", "Completed Requests!")
Sleep(1500)
ProgressOff()

If $debug = True Then _ArrayDisplay($aRepos, "Repos List")
Return $aRepos
EndFunc		;==>GetRepos

Func GetPageRange($user, $debug)
	If StringRight($user, 1) = "/" Then $user = StringLeft($user, (StringLen($user) - 1))

	$sURL = $aURL & "/users/" & $user & "/repos?page=1&per_page=100&"

	If $debug = True Then ConsoleWrite("GetPageRange_URL: " & $sURL & @CRLF)

	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")

	$oHTTP.Open("GET", $sURL, False)
	If (@error) Then Return SetError(1, 0, 0)

	$oHTTP.Send()
	If (@error) Then Return SetError(2, 0, 0)

	; Get a List of all headers
	$aHeaders = _ParseAllHeaders($oHTTP.GetAllResponseHeaders())
	If $debug = True Then _ArrayDisplay($aHeaders, "Request Headers")

	; Check if Link Header was returned
	If _ResponseHeaderExists($oHTTP.GetAllResponseHeaders(), "Link") = True Then
		; Link Header Returned! Repo list is multipage
		; Get the Page Links
		$link = $oHTTP.GetResponseHeader("Link")
		$link = StringReplace(StringReplace($link, ";", ","), " ", "")
		$alink = StringSplit($link, ",")
		If $debug = True Then _ArrayDisplay($alink, "Links")

		; Extract the last page number from the last page url
		$last = $alink[3]
		$istart = StringInStr($last, "page=") + 5
		$istop = StringInStr($last, "&", 0, 1, $istart)
		$page = StringMid($last, $istart, ($istop - $istart))

		; Convert the page number string to a number
		$page = Number($page, 0)

		If $debug = True Then ConsoleWrite("Total Pages: " & $page & @CRLF)

		;Return the last page number
		Return $page
	Else
		; Link Header Not Returned! Repo list is single page
		Return 1
	EndIf
EndFunc		;==>GetPageRange

Func HttpGet($sURL, $sData = "")
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")

	$oHTTP.Open("GET", $sURL & "?" & $sData, False)
	If (@error) Then Return SetError(1, 0, 0)

	$oHTTP.Send()
	If (@error) Then Return SetError(2, 0, 0)

	; Get the Rate Limit specs for the current request from the headers.
	$xrlLimit = $oHTTP.GetResponseHeader("X-RateLimit-Limit")
	$xrlRemaining = $oHTTP.GetResponseHeader("X-RateLimit-Remaining")
	$xrlReset = $oHTTP.GetResponseHeader("X-RateLimit-Reset")

	If $debug = True Then ConsoleWrite("Rate Limit Header Data:" & @CRLF & _
										"Request Limit:" & @TAB & $xrlLimit & @CRLF & _
										"Remaining:" & @TAB & $xrlRemaining & @CRLF & _
										"Reset Epoch: " & @TAB & $xrlReset & @CRLF)

	; Convert the reset point to human readable time
	$xrlDT = _GetDate_fromEpoch($xrlReset)
	Local $tzInfo = _Date_Time_GetTimeZoneInformation()
	If $tzInfo[0] = 1 Then
		$tzName = StringReplace(StringRegExpReplace($tzInfo[2], '[a-z]', ''), ' ', '')
	ElseIf $tzInfo[0] = 2 Then
		$tzName = StringReplace(StringRegExpReplace($tzInfo[5], '[a-z]', ''), ' ', '')
	Else
		$tzName = ""
	EndIf

	If $debug = True Then ConsoleWrite("Next Rate Limit Reset at " & $xrlDT & " " & $tzName & @CRLF)

	If $xrlRemaining = 0 Then
		If $debug = True Then ConsoleWrite("Rate Limit Reached!" & @CRLF)
		$UsrResp = MsgBox($MB_YESNOCANCEL + $MB_TOPMOST, "Rate Limit Reached", "The maximum request rate limit has been reached but there are still requests that need to be made. " & _
		"The next rate limit reset will occur at " & $xrlDT & " " & $tzName & @CRLF & @CRLF & "Do you want to wait for the reset? Press Yes to wait, or No to cancel the remaining requests.")
		; Action based on user response
		If $UsrResp = 6 Then
			; User Clicked Yes
			$sWait = _DateDiff("s", _Now(), $xrlDT)
			$nWait = $sWait * 1000
			Sleep($nWait)
		ElseIf $UsrResp = 7 Then
			; User Clicked No
			Return SetError(3, 0, 0)
		Else
			; Error unhandled response
			Return SetError(3, 0, 0)
		EndIf
	EndIf

	If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3, 0, 0)

	Return SetError(0, 0, $oHTTP.ResponseText)

EndFunc		;==> HttpGet

Func _GetDate_fromEpoch($iEpoch, $iReturnLocal = True)
    Local $aRet = 0, $aDate = 0
    Local $aMonthNumberAbbrev[13] = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    Local $timeAdj = 0
    If Not $iReturnLocal Then
        Local $aSysTimeInfo = _Date_Time_GetTimeZoneInformation()
        Local $timeAdj = $aSysTimeInfo[1] * 60
        If $aSysTimeInfo[0] = 2 Then $timeAdj += $aSysTimeInfo[7] * 60
    EndIf

    $aRet = DllCall("msvcrt.dll", "str:cdecl", "ctime", "int*", $iEpoch + $timeAdj )

    If @error Or Not $aRet[0] Then Return ""

    $aDate = StringSplit(StringTrimRight($aRet[0], 1), " ", 2)

    Return $aDate[4] & "/" & StringFormat("%.2d", _ArraySearch($aMonthNumberAbbrev, $aDate[1])) & "/" & $aDate[2] & " " & $aDate[3]
EndFunc   ;==>_GetDate_fromEpoch

Func _ParseAllHeaders($saHeaders)
	If IsArray($saHeaders) = 0 Then
		$aHeaders = StringSplit($saHeaders, @LF)
	Else
		$aHeaders = $saHeaders
	EndIf

	; Remove any Carige Returns from elements
	For $i = 1 To (UBound($aHeaders) - 1) Step + 1
		$aHeaders[$i] = StringReplace(StringReplace($aHeaders[$i], @CR, ""), @LF, "")
	Next

	; Remove any empty elements
	For $i = (UBound($aHeaders) - 1) To 0 Step - 1
		If $aHeaders[$i] = "" Or StringLen($aHeaders[$i]) = 0 Then
			_ArrayDelete($aHeaders, $i)
			If IsNumber($aHeaders[0]) = 1 Then $aHeaders[0] = UBound($aHeaders) - 1
		EndIf
	Next

	; Create an empty 2D Return Array
	Local $rHeaders[1][2] = [["0", ""]]
	;If $debug = True Then _ArrayDisplay($rHeaders, "Return Array Base")

	; Split Http Header Names and Values into 2D Array
	For $i = 1 To (UBound($aHeaders) - 1) Step + 1
		;$element = StringSplit($aHeaders[$i], ": ", $STR_ENTIRESPLIT + $STR_NOCOUNT)
		;_ArrayDisplay($element, "Element Array")
		;_ArrayAdd($rHeaders, $element, 0)
		_ArrayAdd($rHeaders, $aHeaders[$i], 0, ": ")
		$rHeaders[0][0] = UBound($rHeaders) - 1
	Next

	;Return $aHeaders
	Return $rHeaders
EndFunc   ;==>_ParseAllHeaders

Func _ResponseHeaderExists($saHeaders, $sHeader)
	$aHeaders = _ParseAllHeaders($saHeaders)
	$bMatch = False

	For $i = 1 To $aHeaders[0][0] Step + 1
		If $aHeaders[$i][1] = $sHeader Then
			$bMatch = True
			ExitLoop
		EndIf
	Next

	Return $bMatch
EndFunc   ;==>_ResponseHeaderExists

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

Func PathChars($inString)
	$rtn = StringReplace($inString, "<", "")
	$rtn = StringReplace($rtn, ">", "")
	$rtn = StringReplace($rtn, ":", "")
	$rtn = StringReplace($rtn, Chr(34), "")
	$rtn = StringReplace($rtn, "/", "")
	$rtn = StringReplace($rtn, "\", "")
	$rtn = StringReplace($rtn, "|", "")
	$rtn = StringReplace($rtn, "?", "")
	$rtn = StringReplace($rtn, "*", "")
	Return $rtn
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
	IniWrite($strINIPath, "Settings", "Debug", 0)
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

Func WriteBatch($ProjectName, $DestDir)
	$q = Chr(39)
	$qq = Chr(34)
	;Remove trailing slash if user entered
	If StringRight($DestDir, 1) = "\" Then
		$DestDir = StringTrimRight($DestDir, 1)
	EndIf
	;Remove any reserved characters from the project name that may conflict with filesnames in windows
	$rProjectName = ReplaceRsrvd($ProjectName)
	;Set the full path for the batch file to be written to
	$batFile = $DestDir & "\GitHub_Make_" & $rProjectName & ".bat"
	;Check if $batFile already exists and if so delete it
	If Not (FileExists($batFile) = 0) Then FileDelete($batFile)
	;Create and open the batch file for writing
	Local $hFileOpen = FileOpen($batFile, $FO_APPEND)
	;All FileWriteLine( lines here after are writing the batch file which will process the source list and
	;download each repo then create a update repo batch file to use to update the contents later
	FileWriteLine($hFileOpen, "@echo off")
	FileWriteLine($hFileOpen, "echo Starting GitHub Make")
	FileWriteLine($hFileOpen, "echo Clearing Previous Variables")
	FileWriteLine($hFileOpen, "set " & $qq & "num=" & $qq)
	FileWriteLine($hFileOpen, "Set " & $qq & "pName=" & $qq)
	FileWriteLine($hFileOpen, "Set " & $qq & "dstDir=" & $qq)
	FileWriteLine($hFileOpen, "Set " & $qq & "srcLst=" & $qq)
	FileWriteLine($hFileOpen, "Set " & $qq & "srcCount=" & $qq)
	FileWriteLine($hFileOpen, "Set " & $qq & "var=" & $qq)
	FileWriteLine($hFileOpen, "Set " & $qq & "str=" & $qq)
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
	FileWriteLine($hFileOpen, "IF NOT EXIST " & $qq & "%srcLst%" & $qq & " (")
	FileWriteLine($hFileOpen, "   echo ERROR Cannot Locate SourceList: %srcLst%")
	FileWriteLine($hFileOpen, "   echo Please check the Name of the SourceList and make sure its in this directory!")
	FileWriteLine($hFileOpen, "   echo Exiting Script Now!")
	FileWriteLine($hFileOpen, "   Exit /B")
	FileWriteLine($hFileOpen, ") ELSE (")
	FileWriteLine($hFileOpen, "   echo Found SourceList " & $q & "%srcLst%" & $q & "! Continuing")
	FileWriteLine($hFileOpen, "   Call:sleep 500")
	FileWriteLine($hFileOpen, ")")
	FileWriteLine($hFileOpen, "::Check and see if dstDir needs to be created")
	FileWriteLine($hFileOpen, "echo Checking for Destination Directory")
	FileWriteLine($hFileOpen, "Call:sleep 500")
	FileWriteLine($hFileOpen, "IF NOT EXIST " & $qq & "%dstDir%" & $qq & " (")
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
	FileWriteLine($hFileOpen, "for /f %%C in (" & $q & "Find /V /C " & $qq & "" & $qq & " ^< %srcLst%" & $q & ") do set srcCount=%%C")
	FileWriteLine($hFileOpen, "echo Total Repos to Cloan %srcCount%")
	FileWriteLine($hFileOpen, "Call:sleep 500")
	FileWriteLine($hFileOpen, "echo Completed Initalization Steps Successfully!")
	FileWriteLine($hFileOpen, "echo Prepare to Start Processing Repos")
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "echo Starting Cloaning Repositories Please wait")
	FileWriteLine($hFileOpen, "Call:sleep 1000")
	FileWriteLine($hFileOpen, "for /F " & $qq & "tokens=*" & $qq & " %%A in (%srcLst%) do Call:GitDown %%A")
	FileWriteLine($hFileOpen, "echo Done Cloaning Repos!")
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "echo Creating Directory List for update script")
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "dir /b >FileList.txt")
	FileWriteLine($hFileOpen, "echo Removing TXT Entries from file " & $q & "FileList.txt" & $q)
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "type FileList.txt | findstr /v .txt >FileList2.txt")
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "del FileList.txt")
	FileWriteLine($hFileOpen, "::type FileList2.txt >FileList.txt")
	FileWriteLine($hFileOpen, "echo Removing Null from file " & $q & "FileList.txt" & $q)
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "type FileList2.txt | findstr /v Null >FileList.txt")
	FileWriteLine($hFileOpen, "del FileList2.txt")
	FileWriteLine($hFileOpen, "echo Checking for Existing GitUpdate Batch File")
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "If EXIST " & $qq & "GitUpdate_%pname%.bat" & $qq & " (")
	FileWriteLine($hFileOpen, "	echo Found existing file GitUpdate_%pname%.bat!")
	FileWriteLine($hFileOpen, "	echo Removing File!")
	FileWriteLine($hFileOpen, "	Call:sleep 1500")
	FileWriteLine($hFileOpen, "	DEL " & $qq & "GitUpdate_%pname%.bat" & $qq)
	FileWriteLine($hFileOpen, "	echo File Removed Successfully!")
	FileWriteLine($hFileOpen, "	Call:sleep 1500")
	FileWriteLine($hFileOpen, ") ELSE (")
	FileWriteLine($hFileOpen, "	echo No Existing Update File Found")
	FileWriteLine($hFileOpen, "	Call:sleep 1500")
	FileWriteLine($hFileOpen, ")")
	FileWriteLine($hFileOpen, "echo Getting Repos Parent Directory")
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "FOR /F " & $qq & "tokens=* USEBACKQ" & $qq & " %%F IN (`chdir`) DO (")
	FileWriteLine($hFileOpen, "SET var=%%F")
	FileWriteLine($hFileOpen, ")")
	FileWriteLine($hFileOpen, ":: Original For Loop for Writing Git Update Commands for Each Repo")
	FileWriteLine($hFileOpen, "::for /F " & $qq & "tokens=*" & $qq & " %%A in (FileList.txt) do echo Writing Repo Entry " & $q & "%%A" & $q & " & echo cd " & $qq & "%var%\%%A" & $qq & ">>GitUpdate_%pname%.bat & echo.Updating Repo " & $q & "%%A" & $q & ">>GitUpdate_%pname%.bat & echo.git pull>>GitUpdate_%pname%.bat")
	FileWriteLine($hFileOpen, "")
	FileWriteLine($hFileOpen, "::Replacement For Loop using Function to Write Git Update Commands for Each Repo")
	FileWriteLine($hFileOpen, "echo @echo Off>>GitUpdate_%pname%.bat")
	FileWriteLine($hFileOpen, "for /F " & $qq & "tokens=*" & $qq & " %%A in (FileList.txt) do Call:wGitUpdate %%A")
	FileWriteLine($hFileOpen, "echo Closing File " & $q & "GitUpdate_%pname%.bat" & $q & " ")
	FileWriteLine($hFileOpen, "echo cd " & $qq & "%var%" & $qq & ">>GitUpdate_%pname%.bat")
	FileWriteLine($hFileOpen, "echo Completed Creating " & $q & "GitUpdate_%pname%.bat" & $q)
	FileWriteLine($hFileOpen, "echo Cleaning Up Old Files")
	FileWriteLine($hFileOpen, "echo Removing " & $q & "FileList.txt" & $q)
	FileWriteLine($hFileOpen, "del FileList.txt")
	FileWriteLine($hFileOpen, "echo Removing " & $q & "Null" & $q)
	FileWriteLine($hFileOpen, "del Null")
	FileWriteLine($hFileOpen, "echo Removing " & $q & "%srcLst%" & $q)
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
	FileWriteLine($hFileOpen, ":: Remove the URL Protocol & Domain Name to get just the URL Path for later use")
	FileWriteLine($hFileOpen, "set strName=%~1")
	FileWriteLine($hFileOpen, "set strName=%strName:http://github.com/=%")
	FileWriteLine($hFileOpen, "set strName=%strName:https://github.com/=%")
	FileWriteLine($hFileOpen, "set str=%str:~-4%")
	FileWriteLine($hFileOpen, "for /F " & $qq & "tokens=1,2 delims=/" & $qq & " %%a in (" & $qq & "%strName%" & $qq & ") do (set dirname=%%b)")
	FileWriteLine($hFileOpen, "set sdir=%cd%\%dirname%")
	FileWriteLine($hFileOpen, ":: echo %sdir%")
	FileWriteLine($hFileOpen, ":: Check if the repo has already been downloaded or not")
	FileWriteLine($hFileOpen, "IF NOT EXIST " & $qq & "%sdir%" & $qq & " (")
	FileWriteLine($hFileOpen, "	:: Sense the output directory doesnt exist we can cloan this repo")
	FileWriteLine($hFileOpen, "	echo. Cloaning Repo # %num% of %srcCount%: %strName%")
	FileWriteLine($hFileOpen, "	IF " & $qq & "%str%" & $qq & " == " & $qq & ".git" & $qq & " (")
	FileWriteLine($hFileOpen, "		git clone %~1")
	FileWriteLine($hFileOpen, "	) ELSE (")
	FileWriteLine($hFileOpen, "		git clone %~1.git")
	FileWriteLine($hFileOpen, "	)")
	FileWriteLine($hFileOpen, "	echo. Done Cloaining Repo # %num% of %srcCount%")
	FileWriteLine($hFileOpen, ") ELSE (")
	FileWriteLine($hFileOpen, "	:: Output directory already exists skip this repo")
	FileWriteLine($hFileOpen, "	echo. Repo # %num% of %srcCount%: %strName% already exists! Skipping...")
	FileWriteLine($hFileOpen, ")")
	FileWriteLine($hFileOpen, ":: Clear variables that will get replaced later so there arent any accidents")
	FileWriteLine($hFileOpen, "set " & $qq & "str=" & $qq & "")
	FileWriteLine($hFileOpen, "set " & $qq & "strName=" & $qq & "")
	FileWriteLine($hFileOpen, "set " & $qq & "dirname" & $qq & "")
	FileWriteLine($hFileOpen, "set " & $qq & "sdir=" & $qq & "")
	FileWriteLine($hFileOpen, "Call:sleep 1500")
	FileWriteLine($hFileOpen, "goto:eof")
	FileWriteLine($hFileOpen, "")
	FileWriteLine($hFileOpen, ":: Function to Write Repo Update Entry")
	FileWriteLine($hFileOpen, ":wGitUpdate")
	FileWriteLine($hFileOpen, "echo Writing Repo Entry " & $q & "%~1" & $q)
	FileWriteLine($hFileOpen, "echo.cd " & $qq & "%var%\%~1" & $qq & ">>GitUpdate_%pname%.bat & echo.echo Updating Repo " & $q & "%~1" & $q & ">>GitUpdate_%pname%.bat & echo.git pull>>GitUpdate_%pname%.bat")
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

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; GUI Functions
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Func SSMode()
	#Region ### START Koda GUI section ### Form=D:\AutoIt\GitHub_Repo_Builder\GitHub_Repo_Builder-SSMode.kxf
	$SSForm = GUICreate("GitHub Repo Builder - Single Source Mode", $wWidth, $wHeight, $xLeft, $yTop)
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
	$cbData = ClipGet()
	If StringInStr($cbData, "://github.com/") <> 0 Then
		$usr = MsgBox($MB_YESNO + $MB_TOPMOST, "Copied Address", "Do you want to use the coppied address as the Web Address?")
		If $usr = $IDYES Then
			If StringRight($cbData, 1) = "/" Then
				$slen = StringLen($cbData) - 1
				$cbData = StringLeft($cbData, $slen)
				ConsoleWrite("Output Source Name: " & $cbData & @CRLF)
			EndIf
			GUICtrlSetData($SrcAdd_bx, $cbData)
			$srcName = PathChars(_StringProper(StringReplace(StringReplace($cbData, "https://github.com/", ""), "http://github.com/", "")))
			ConsoleWrite("Current Source Name: " & $srcName & @CRLF)
			GUICtrlSetData($Proj_bx, $srcName & "_GitHub_Source")
		EndIf
	EndIf
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
						MsgBox($MB_OK + $MB_TOPMOST, "Error In Web Address", "We corrected an error in the web address you provided for the source repo. The new Address is now '" & $ghAddress & "'.", 60, $SSForm)
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
					MsgBox($MB_OK + $MB_TOPMOST, "Error", "Please select a build option under step 4 to continue")
				EndIf
			Case $CapMul_men
				SetWinPos($SSForm)
				GUIDelete($SSForm)
				MSMode()
			Case $SDefault_men
				$usrMode = MsgBox($MB_YESNO + $MB_TOPMOST, "Set Default Mode", "Do you want to set the default mode to Single Source Mode?")
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
	$MSForm = GUICreate("GitHub Repo Builder - Multiple Source Mode", $wWidth, $wHeight, $xLeft, $yTop)
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
				SetWinPos($MSForm)
				GUIDelete($MSForm)
				SSMode()
			Case $iniBrowse_btn
				$fsFile = FileOpenDialog("Select Multi Source INI", @ScriptDir, "INI files (*.ini)|All (*.*)", 1)
				GUICtrlSetData($srcini_tbx, $fsFile)
				$sNames = IniReadSectionNames($fsFile)
				For $i = 1 To $sNames[0] Step + 1
					If $sNames[$i] = "Settings" Then
						$usrChoice = MsgBox($MB_YESNO + $MB_TOPMOST, "Found Settings", "Found Configuration Settings in INI file!" & @CRLF & @CRLF & "Do you want to load these settings now?")
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
					MsgBox($MB_OK + $MB_TOPMOST, "Error", "Please select a build option under step 4 to continue")
				EndIf
			Case $SDefault_men
				$usrMode = MsgBox($MB_YESNO + $MB_TOPMOST, "Set Default Mode", "Do you want to set the default mode to Multiple Source Mode?")
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

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------