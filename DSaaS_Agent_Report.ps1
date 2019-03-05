Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$Credentials = (Get-Content "$PSScriptRoot\DS-Config.json" -Raw) | ConvertFrom-Json

$Manager = $Credentials.MANAGER
$Port = $Credentials.PORT
$Tenant = $Credentials.TENANT
$UserName = $Credentials.USER_NAME
$Password = $Credentials.PASSWORD
$APIKEY = $Credentials.APIKEY

$ErrorActionPreference = 'Stop'

$DSM_URI="https://" + $Manager + ":" + $Port
Function Connect-DSM {

	#$DSM_Cred	= Get-Credential -Message "Enter DSM Credentials"
	#$DSM_ID		= $DSM_Cred.GetNetworkCredential().UserName
    #$DSM_PASS	= $DSM_Cred.GetNetworkCredential().Password

	$DSM_ID		= $UserName
    $DSM_PASS	= $Password

	$creds = @{
		dsCredentials = @{
			userName = $DSM_ID
	    	password = $DSM_PASS
			}
	}

	if (!$Tenant) {
		$AUTH_URI = $DSM_URI + "/rest/authentication/login/primary"
	}
	else {
		$AUTH_URI = $DSM_URI + "/rest/authentication/login"
		$creds.dsCredentials.Add("tenantName", $tenant)
	}

	$AuthData = $creds | ConvertTo-Json
    $headers = @{'Content-Type'='application/json'}

	try{
        $sID = Invoke-RestMethod -Uri $AUTH_URI -Method Post -Body $AuthData -Headers $headers
        Return $sID
	}
	catch{
		Write-Host "[ERROR]	Failed to logon to $DSM_URI.	$_"
		Write-Host "An error occurred during authentication. Verify username and password and try again. `nError returned was: $($_.Exception.Message)"
		Exit
	}
}

Function Get-LastRecommendationScan {

	$WSDL = "/webservice/Manager?WSDL"
	$DSM_URI = $DSM_URI + $WSDL

	$HostName = "lt-ubuntu18"

	[xml] $SoapRequest = '
	<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager">
	   <soapenv:Header/>
	   <soapenv:Body>
		  <urn:hostDetailRetrieveByName>
			 <urn:hostname></urn:hostname>
			 <urn:hostDetailLevel>LOW</urn:hostDetailLevel>
			 <urn:sID></urn:sID>
		  </urn:hostDetailRetrieveByName>
	   </soapenv:Body>
	</soapenv:Envelope>
	'

	$SoapRequest.Envelope.Body.hostDetailRetrieveByName.hostname = $HostName
	$SoapRequest.Envelope.Body.hostDetailRetrieveByName.sID = $sID

	$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$headers.Add("Content-Type", "text/xml")
	$headers.Add("soapaction", "hostDetailRetrieveByName")

	[xml] $obj_Manager = Invoke-WebRequest -Uri $DSM_URI -Headers $headers -Method Post -Body $SoapRequest -SkipHeaderValidation

	$HostDetails = $obj_Manager.Envelope.Body.hostDetailRetrieveByNameResponse.hostDetailRetrieveByNameReturn
	$Results =  $HostDetails.overallLastRecommendationScan
	Return $Results
}

$sID = Connect-DSM
write-host $sID

$LastRecommendationScan = Get-LastRecommendationScan
Write-Host $LastRecommendationScan

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("api-secret-key", $APIKEY)
$headers.Add("api-version", 'v1')

$Policies_apipath = "/api/policies"
$Computers_apipath = "/api/computers/5002"

$Computers_Uri= $DSM_URI + $Computers_apipath
$Policies_Uri= $DSM_URI + $Policies_apipath

$Computers = Invoke-RestMethod -Uri $Computers_Uri  -Headers $Headers -Method Get
$Policies  = Invoke-RestMethod -Uri $Policies_Uri -Headers $Headers -Method Get


#$Computers
$PolicyID = $Computers.policyID
$PolicyID
$PolicyName = $Policies.policies | Where-Object {$_.ID -eq $PolicyID}


$Computers.computerStatus.agentStatusMessages
$Computers.agentVersion
$Computers.ec2VirtualMachineSummary.operatingSystem
$Computers.ec2VirtualMachineSummary.instanceID
$PolicyName.name
$Computers.antiMalware.state
