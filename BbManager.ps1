Param(
	[Parameter(Mandatory=$false)]$Upload=$true,
	[Parameter(Mandatory=$false)]$UsersInputFile="",
    [Parameter(Mandatory=$false)]$CourseENRLInputFile=""
)
	
####################################################################
function Execute-HTTPPostCommand{
    param(
        [Parameter(Mandatory=$true)]$URL,
		[Parameter(Mandatory=$true)]$FileToUpload,
		[Parameter(Mandatory=$true)]$Username,
		[Parameter(Mandatory=$true)]$Password
    )

	write-host "`n$URL`n$FileToUpload`n$Username`n$Password"
	$content = Get-Content $FileToUpload
	$post = ""
	ForEach($line in $content){
		$post += "$line`r"
	}
	
    $webRequest = [System.Net.WebRequest]::Create($URL)
    $webRequest.ContentType = "text/plain"
    $PostStr = [System.Text.Encoding]::UTF8.GetBytes($Post)
	#return $null
    $webrequest.ContentLength = $PostStr.Length
    $webRequest.ServicePoint.Expect100Continue = $false
    $webRequest.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $Username, $Password 
	$webRequest.Headers.Add("AUTHORIZATION", "${Username}:${Password}")
	
    $webRequest.PreAuthenticate = $true
    $webRequest.Method = "POST"

    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($PostStr, 0,$PostStr.length)
    $requestStream.Close()

	#start-sleep 3
    [System.Net.WebResponse] $resp = $webRequest.GetResponse()
    $rs = $resp.GetResponseStream()
    [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs
    [string] $results = $sr.ReadToEnd()

    return $results;

}
####################################################################

####################################################################
function IsActive{
	Param(
		[Parameter(Mandatory=$true)]$StartDateTime,
		[Parameter(Mandatory=$true)]$EndDateTime
	)
	$today = Get-Date
	$start = Get-Date -Date $StartDateTime
	$end = Get-Date -Date $EndDateTime
	
	if(($start -lt $today) -and ($today -lt $end)){
		return $true;
	}else{
		return $false;
	}
}
####################################################################

####################################################################
function Execute-UsersSnapshot{
	Param(
		[Parameter(Mandatory=$true)]$InputFile,
		[Parameter(Mandatory=$false)]$Delimiter=",",
		[Parameter(Mandatory=$true)]$Upload,
		[Parameter(Mandatory=$true)]$UploadURL,
		[Parameter(Mandatory=$true)]$SharedUsername,
		[Parameter(Mandatory=$true)]$sharedPw
	)
	
	$usersFile = "$rootPath\output\USERS"
	$usersHeader = "EXTERNAL_PERSON_KEY|USER_ID|PASSWD|FIRSTNAME|LASTNAME|EMAIL|AVAILABLE_IND"
	
	if(-not (Test-Path $InputFile)){
		Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tERROR`tCould not find '$InputFile'. Exiting Execute-UsersSnapshot." -Append
		return $null
	}

	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tStarting to process '$InputFile'." -Append

	$usersInInfoFile = Import-Csv -Path $InputFile -Delimiter $Delimiter
	
	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tAdding lines to user file output '$usersFile'." -Append
	Out-File -FilePath $usersFile -InputObject $usersHeader
	Foreach($user in $usersInInfoFile){
		$today = Get-Date
		$isAct = IsActive -StartDateTime $user.START_DATE_TIME -EndDateTime $user.END_DATE_TIME
	
		$outputString = "$($user.BATCH_UID)|$($user.USERNAME)|$($user.PASSWORD)|$($user.FIRSTNAME)|$($user.LASTNAME)|$($user.EMAIL)|"
		if($isAct){
			$outputString+="Y" 
		}else{
			$outputString+="N"
		}
		Out-File -FilePath $usersFile -InputObject $outputString -Append
		Out-File -FilePath $logFile -InputObject "---$outputString" -Append
	}
	
	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tFinished creating users output file." -Append
	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tUpload is set to '$upload'." -Append

	if($Upload){
		Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tProcessing '$usersFile' to '$UploadURL'." -Append
		Execute-HTTPPostCommand -URL $UploadURL -FileToUpload $usersFile -Username $SharedUsername -Password $sharedPw | Out-File -FilePath $logFile -Append
	}
	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tFinished processing '$InputFile'." -Append
}
####################################################################

####################################################################
function Execute-CourseEnrollmentSnapshot{
	Param(
		[Parameter(Mandatory=$true)]$InputFile,
		[Parameter(Mandatory=$false)]$Delimiter=",",
		[Parameter(Mandatory=$true)]$Upload,
		[Parameter(Mandatory=$true)]$UploadURL,
		[Parameter(Mandatory=$true)]$SharedUsername,
		[Parameter(Mandatory=$true)]$sharedPw
	)
	
	$enrollmentFile = "$rootPath\output\CRSENRL"
	$enrollmentHeader = "EXTERNAL_PERSON_KEY|EXTERNAL_COURSE_KEY|ROLE|AVAILABLE_IND"
	
	if(-not (Test-Path $InputFile)){
		Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tERROR`tCould not find '$InputFile'. Exiting Execute-CourseEnrollmentSnapshot." -Append
		return $null
	}

	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tStarting to process '$InputFile'." -Append

	$crsenrlInInfoFile = Import-Csv -Path $InputFile -Delimiter $Delimiter
	
	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tAdding lines to course enrollment file output '$enrollmentFile'." -Append
	Out-File -FilePath $enrollmentFile -InputObject $enrollmentHeader
	Foreach($crsenrl in $crsenrlInInfoFile){
		$today = Get-Date
		$isAct = IsActive -StartDateTime $crsenrl.START_DATE_TIME -EndDateTime $crsenrl.END_DATE_TIME
	
		$outputString = "$($crsenrl.USER_ID)|$($crsenrl.COURSE_ID)|$($crsenrl.ROLE)|"
		if($isAct){
			$outputString+="Y" 
		}else{
			$outputString+="N"
		}
		Out-File -FilePath $enrollmentFile -InputObject $outputString -Append
		Out-File -FilePath $logFile -InputObject "---$outputString" -Append
	}
	
	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tFinished creating crsenrl output file." -Append
	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tUpload is set to '$upload'." -Append

	if($Upload){
		Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tProcessing '$enrollmentFile' to '$UploadURL'." -Append
		Execute-HTTPPostCommand -URL $UploadURL -FileToUpload $enrollmentFile -Username $SharedUsername -Password $sharedPw | Out-File -FilePath $logFile -Append
	}
	Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`tFinished processing '$InputFile'." -Append
}
####################################################################



####################################################################
###                       MAIN SECTION							 ###
$dateStamp = (Get-Date -Format s) -replace "^(.*)T.*$",'$1'

### Change the value of this variable to the path of the 
###  ps1 script file
	New-Variable -Name RootPath -Value "c:\myCode\powershell\Bb" -Scope Global
###
	New-Variable -Name logFile -Value "$rootPath\Logs\snapshot-controller-log.${dateStamp}.txt" -Scope Global
####

Out-File -FilePath $logFile -InputObject "`n$(Get-Date -Format G)`tMESSAGE`tStarting BbManager.ps1" -Append
write-host "setup files"
if ($UsersInputFile -eq ''){
	$UsersInputFile="$RootPath\Input\USERS.csv"
}

if ($CourseENRLInputFile -eq ''){
	$CourseENRLInputFile="$RootPath\Input\CRSENRL.csv"
}

write-host "starting users"
Execute-UsersSnapshot -InputFile $UsersInputFile -Upload $Upload -UploadURL "https://testbbbeta.hsutx.edu/webapps/bb-data-integration-flatfile-BBLEARN/endpoint/person/refresh" -SharedUsername "8c036b29-d224-4fca-9b1a-7c4636d85410" -SharedPw 'BbWorld14'
write-host "Ending users"
Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`Finished BbManager.ps1`n_________________________________________________________" -Append

write-host "starting courses"
Execute-CourseEnrollmentSnapshot -InputFile $CourseENRLInputFile -Upload $Upload -UploadURL "https://testbbbeta.hsutx.edu/webapps/bb-data-integration-flatfile-BBLEARN/endpoint/membership/refresh" -SharedUsername "8c036b29-d224-4fca-9b1a-7c4636d85410" -SharedPw 'BbWorld14'
write-host "Ending courses"
Out-File -FilePath $logFile -InputObject "$(Get-Date -Format G)`tMESSAGE`Finished BbManager.ps1`n_________________________________________________________" -Append