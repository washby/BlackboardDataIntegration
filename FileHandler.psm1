####################################################################
###
### @author 	= Wade Ashby - wade.ashby@hsutx.edu
### @lastUpdate = 5/14/15
###
####################################################################
function Invoke-HTTPPostCommand{
    param(
        [Parameter(Mandatory=$true)]$URL,
		[Parameter(Mandatory=$true)]$FileToUpload,
		[Parameter(Mandatory=$true)]$Username,
		[Parameter(Mandatory=$true)]$Password
    )

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
