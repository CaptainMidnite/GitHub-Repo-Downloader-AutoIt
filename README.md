# GitHub-Repo-Downloader-AutoIt

NOTE: README.md Updates Pending...

Tools to allow you to download a members complete repository list. Using AutoIt & Batch Files (Windows Only).

Includes .au3 files for source functions 'GitHubRepos.au3' (Use as include) as well as GUI version 'GitHub_Repo_Builder-Public.au3'
as well as a precompiled version of the GUI version 'GitHub_Repo_Builder-Public.exe' (Available under 'Precompiled Versions' Directory).
Also sample output files are available under 'Sample Output Files' directory incase you want to see what the batch files are doing.
Basically the sample file 'GitHub_Make_Google_GitHub_Source.bat' is the batch file that will download all of the repos listed in the
file 'SourceList.txt' after it has finished downloading these files it will create a additonal batch file within the source directory
that will loop through each of the repo's directorys and update its contents.

Note that this is a work in progress so I will go back and add additonal functions and features as I get time as well I will go back
and make comments in the .au3 files and the sample batch files to explain whats going on in them.

In the examples as well as the set defaults in the GUI the repo used is Google's (https://github.com/google) which has 780 sub repos
to say the least its pretty big so I wouldnt use it for testing unless you have alot of time on your hands for downloading all of
their repos. If you want to test just the portion for building the batch file thats fine and only takes a few moments to process.

If you have any suggested changes or requests to add any additonal functionality feel free to send me a message on github.

-CaptainMidnite

Detailed Descriptions:
----------------------------------------------------------------------------------------------------------------------------------------------------------
 Script Function:	GUI GitHub_Repo_Builder - v2.0

 File Name:			GitHub_Repo_Builder-Public.au3
 
 Release:			Public Release!

 Description:		GUI Version to Download a Members Complete Repository Set
			Includes the Ability to Just Download and Create Batch File for Later Processing of Repositories
			Or You Download, Create Batch File, and Download all Repositories. Starting in V3.0: Included a new section in the GUI under the options menu for "Multiple Source Mode", use this if you need to grab all Repositories from multiple members at once. This process works similar to the Single Source Mode but you have to provide a approriately formatted ini file that contains the head address to the repo and the names of the projects that you want to have for them.
		

 Functions:				
 					
 					GetHub_Repo_Builder() - SSMode
					Description: 	**GUI** Downloads a list of members repos and creates batch file to use to 	download them and excute this batch file
									if requested. The items below describe each of the input boxes and radio buttons available on the GUI, for info
									on the functions that are ran within the GUI please see next section below for details.
					$Web Address:			Main web address of user (i.e. https://github.com/google)
					$Project Name:			Name of project to be created will also use as part of directory name (i.e. Google_GitHub_Source)
					$Destination:			Destination Directory where the project will be stored (i.e. C:\Users)
					$Build Only:				Will only create the Project Directory and the inital batch file to download the repos for user to run later
					$Build and Execute:		Will do the same as Build And will Start Running the Batch File after build process is complete	
					
					GetHub_RepoBuilder() - MSMode
					Description:	**GUI** Downloads multiple members or sources repos list and creates batch file to use to download them and execute this batch file 
									if requested. The items below describe each of the input boxes and radio buttons available on the GUI, for info
									on the functions that are ran within the GUI please see next section below for details.
						
					$INI File:			Full path to INI file containing the address to the source repos and a project name whcih to identify the repo (See examples below).
					$Project Name:			Over All Project Name used to store all resulting batch files source lists and source repos once executed.
					$Destination:			Full destination directory for all of the content above to be stored to.
					$Build Only:				Will only create the Project Directory and the inital batch file to download the repos for user to run later
					$Build and Execute:		Will do the same as Build And will Start Running the Batch Files after build process is complete
					
					$Example INI Files:
					Basic INI Example:
					[General]
					head address=project name
					https://github.com/angular=angular
					https://github.com/antirez=antirez
					...
					----------------------------------------------------------------------------------------------
					$Advanced INI File:
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
					----------------------------------------------------------------------------------------------
					
					Also full example INI Files can be found in the folder 'Example_inis'
==========================================================================================================================================================
 Script Function:	GitHubRepos - V2.0

 File Name:			GitHubRepos.au3
 
 Release:			Public Release!

 Description:		AutoIt Functions to Download a Members Complete Repository Set.

 Functions:
 
					GitSrcRepos($ghAddress, $dstDir)
					Description: 	Downloads a complete list of a members repository set as a text file and saves it as SourceList.txt
					$ghAddress			=	GitHub Address - Ex: https://github.com/google
					$dstDir				=	Destination Directory for Source List - Ex: @ScriptDir

					WriteBatch($prjName, $dstDir)
					Description:	Creates a windows batch file "GitHub_Make_%Project Name%.bat" to process SourceList.txt. Running this batch file will
									download all repos from SourceList.txt and create an additonal batch file "GitUpdate_%Project Name%.bat" to use to
									update all of the downloaded repos. If function is used in a variable then the function will return the path to the
									batch file "GitHub_Make_%Project Name%.bat".
					$prjName			=	Project Name - Ex: Google_Github
					$dstDir				=	Destination Directory for "GitHub_Make_%Project Name%.bat"

					ReplaceRsrvd($inString)
					Description:	Used to Remove/Replace any reserved characters in the input string that may conflict with windows directory namespace
									or have conflicts within the batch files.
					$inString			=	Input String - Ex: Google_GitHub
					Example:		ReplaceRsrvd("Google* GitHub") = Returns: Google_GitHub
----------------------------------------------------------------------------------------------------------------------------------------------------------
