@echo off
echo Starting GitHub Make...
echo Clearing Previous Variables...
set "num="
Set "pName="
Set "dstDir="
Set "srcLst="
Set "srcCount="
Set "var="
Set "str="
PING 1.1.1.1 -n 1 -w 1500 >>Null
echo Setting Variables...
set num=0
Set pName=Google_GitHub_Source
Set dstDir=Google_GitHub_Source
Set srcLst=SourceList.txt
PING 1.1.1.1 -n 1 -w 1500 >>Null
::Check and make sure that the srcLst path exists
echo Starting PreChecks...
echo Checking Source List Exists...
PING 1.1.1.1 -n 1 -w 500 >>Null
IF NOT EXIST "%srcLst%" (
   echo ERROR Cannot Locate SourceList: %srcLst%...
   echo Please check the Name of the SourceList and make sure its in this directory!
   echo Exiting Script Now!
   Exit /B
) ELSE (
   echo Found SourceList '%srcLst%'! Continuing...
   PING 1.1.1.1 -n 1 -w 500 >>Null
)
::Check and see if dstDir needs to be created...
echo Checking for Destination Directory...
PING 1.1.1.1 -n 1 -w 500 >>Null
IF NOT EXIST "%dstDir%" (
   echo Destination Directory Does Not Exist...
   echo Creating GitHub Directory for %pName%...
   mkdir %dstDir%
   PING 1.1.1.1 -n 1 -w 500 >>Null
   echo Copying Source List to Destination Directory...
   copy %srcLst% %dstDir%
   PING 1.1.1.1 -n 1 -w 500 >>Null
) ELSE (
   echo Destination Directory Already Exists...
   echo Copying Source List to Destination Directory...
   copy %srcLst% %dstDir%
   PING 1.1.1.1 -n 1 -w 500 >>Null
)
echo Moving into GitHub Directory...
cd %dstDir%
echo Parsing Source Repo List...
PING 1.1.1.1 -n 1 -w 1000 >>Null
for /f %%C in ('Find /V /C "" ^< %srcLst%') do set srcCount=%%C
echo Total Repos to Cloan %srcCount%
PING 1.1.1.1 -n 1 -w 500 >>Null
echo Completed Initalization Steps Successfully!
echo Prepare to Start Processing Repos...
PING 1.1.1.1 -n 1 -w 1500 >>Null
echo Starting Cloaning Repositories Please wait...
PING 1.1.1.1 -n 1 -w 1000 >>Null
for /F "tokens=*" %%A in (%srcLst%) do Call:GitDown %%A
echo Done Cloaning Repos!
PING 1.1.1.1 -n 1 -w 1500 >>Null
echo Creating Directory List for update script
PING 1.1.1.1 -n 1 -w 1500 >>Null
dir /b >FileList.txt
echo Removing TXT Entries from file 'FileList.txt'
PING 1.1.1.1 -n 1 -w 1500 >>Null
type FileList.txt | findstr /v .txt >FileList2.txt
PING 1.1.1.1 -n 1 -w 1500 >>Null
del FileList.txt
::type FileList2.txt >FileList.txt
echo Removing Null from file 'FileList.txt'
PING 1.1.1.1 -n 1 -w 1500 >>Null
type FileList2.txt | findstr /v Null >FileList.txt
del FileList2.txt
echo Checking for Existing GitUpdate Batch File...
PING 1.1.1.1 -n 1 -w 1500 >>Null
If EXIST "GitUpdate_%pname%.bat" (
	echo Found existing file GitUpdate_%pname%.bat!
	echo Removing File!
	PING 1.1.1.1 -n 1 -w 1500 >>Null
	DEL "GitUpdate_%pname%.bat"
	echo File Removed Successfully!
	PING 1.1.1.1 -n 1 -w 1500 >>Null
) ELSE (
	echo No Existing Update File Found...
	PING 1.1.1.1 -n 1 -w 1500 >>Null
)
echo Getting Repos Parent Directory...
PING 1.1.1.1 -n 1 -w 1500 >>Null
FOR /F "tokens=* USEBACKQ" %%F IN (`chdir`) DO (
SET var=%%F
)
:: Original For Loop for Writing Git Update Commands for Each Repo
::for /F "tokens=*" %%A in (FileList.txt) do echo Writing Repo Entry '%%A' & echo cd "%var%\%%A">>GitUpdate_%pname%.bat & echo.Updating Repo '%%A'>>GitUpdate_%pname%.bat & echo.git pull>>GitUpdate_%pname%.bat

::Replacement For Loop using Function to Write Git Update Commands for Each Repo
echo @echo Off>>GitUpdate_%pname%.bat
for /F "tokens=*" %%A in (FileList.txt) do Call:wGitUpdate %%A
echo Closing File 'GitUpdate_%pname%.bat' 
echo cd "%var%">>GitUpdate_%pname%.bat
echo Completed Creating 'GitUpdate_%pname%.bat'
echo Cleaning Up Old Files...
echo Removing 'FileList.txt'
del FileList.txt
echo Removing 'Null'
del Null
echo Removing '%srcLst%'
del %srcLst%
echo Returning to Original Directory...
cd ..
del Null
echo Completed File Cleanup...
PING 1.1.1.1 -n 1 -w 1000 >>Null
echo GitHub Make Completed Successfully!

echo.&goto:eof

:: Function to Download Source Repo and Echo Number
:GitDown
set /a num=%num%+1
set str=%~1
set strName=%~1
set strName=%strName:http://github.com/=%
set strName=%strName:https://github.com/=%
set str=%str:~-4%
echo. Cloaning Repo # %num% of %srcCount%: %strName%
IF "%str%" == ".git" (
	git clone %~1
) ELSE (
	git clone %~1.git
)
echo. Done Cloaining Repo # %num% of %srcCount%
PING 1.1.1.1 -n 1 -w 1500 >>Null
goto:eof

:: Function to Write Repo Update Entry
:wGitUpdate
echo Writing Repo Entry '%~1'
echo.cd "%var%\%~1">>GitUpdate_%pname%.bat & echo.echo Updating Repo '%~1'>>GitUpdate_%pname%.bat & echo.git pull>>GitUpdate_%pname%.bat
goto:eof
