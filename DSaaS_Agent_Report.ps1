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

$Computers_apipath = "/api/computers"
$Computers_Uri= $DSM_URI + $Computers_apipath

$Policies_apipath = "/api/policies"
$Policies_Uri= $DSM_URI + $Policies_apipath

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("api-secret-key", $APIKEY)
$headers.Add("api-version", 'v1')

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

Function Get-LastRecommendationScanByID {
	Param(	[Parameter(Mandatory=$true)][String] $HostID)

	$WSDL = "/webservice/Manager?WSDL"
	$DSM_URI = $DSM_URI + $WSDL
	$ID = $HostID
	[xml] $SoapRequest = '
	<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager">
		<soapenv:Header/>
		<soapenv:Body>
		<urn:hostDetailRetrieve>
			<urn:hostFilter>
				<urn:hostID></urn:hostID>
				<urn:type>SPECIFIC_HOST</urn:type>
			</urn:hostFilter>
			<urn:hostDetailLevel>LOW</urn:hostDetailLevel>
			<urn:sID></urn:sID>
		</urn:hostDetailRetrieve>
		</soapenv:Body>
 	</soapenv:Envelope>
	'

	$SoapRequest.Envelope.Body.hostDetailRetrieve.hostFilter.hostID = $ID
	$SoapRequest.Envelope.Body.hostDetailRetrieve.sID = $sID

	$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$headers.Add("Content-Type", "text/xml")
	$headers.Add("soapaction", "hostDetailRetrieve")

	[xml] $obj_Manager = Invoke-WebRequest -Uri $DSM_URI -Headers $headers -Method Post -Body $SoapRequest -SkipHeaderValidation

	$Results = $obj_Manager.Envelope.Body.hostDetailRetrieveResponse.hostDetailRetrieveReturn
	$LastRecommendationScan = $Results.overallLastRecommendationScan

	If ($LastRecommendationScan.IsEmpty){
	   Return "No Recommendation scan exist"
	}Else{
	   Return $LastRecommendationScan
	}
}

$sID = Connect-DSM

$Computers = Invoke-RestMethod -Uri $Computers_Uri  -Headers $Headers -Method Get
$Policies  = Invoke-RestMethod -Uri $Policies_Uri -Headers $Headers -Method Get

foreach ($Item in $Computers.computers){
	$Host_ID = $Item.ID
	$PolicyID = $Item.policyID
	$PolicyName = $Policies.policies | Where-Object {$_.ID -eq $PolicyID}

	$HostName = $Item.hostName
	$DisplayName = $Item.displayName
	$AgentStatus = $Item.computerStatus.agentStatusMessages
	$AgentVersion = $Item.agentVersion
	$AgentOS = $Item.ec2VirtualMachineSummary.operatingSystem
	$InstanceID = $Item.ec2VirtualMachineSummary.instanceID
	$PolicyName = $PolicyName.name
	$AntiMalwareState = $Item.antiMalware.state
	$LastRecommendationScan = Get-LastRecommendationScanByID -HostID $Host_ID

	Write-Host "$Host_ID	$HostName	$DisplayName	$AgentStatus	$AgentVersion	$AgentOS	$InstanceID		$PolicyName		$AntiMalwareState	$LastRecommendationScan"

}

