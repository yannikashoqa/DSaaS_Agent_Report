Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$ErrorActionPreference = 'Continue'

$Config     = (Get-Content "$PSScriptRoot\DS-Config.json" -Raw) | ConvertFrom-Json
$Manager    = $Config.MANAGER
$Port       = $Config.PORT
$APIKEY     = $Config.APIKEY
$REPORTNAME = $Config.REPORTNAME

$StartTime  = $(get-date)

$REPORTFILE          = $REPORTNAME + ".csv"
$DSM_URI             = "https://" + $Manager + ":" + $Port
$Computers_Uri       = $DSM_URI + "/api/computers"
$Policies_Uri        = $DSM_URI + "/api/policies"
$CurrentAPIKeys_Uri	 = $DSM_URI + "/api/apikeys/current"

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("api-secret-key", $APIKEY)
$headers.Add("api-version", 'v1')

try {
    $CurrentAPIKeys = Invoke-RestMethod -Uri $CurrentAPIKeys_Uri -Method Get -Headers $Headers
    If ($CurrentAPIKeys.active){
        Write-Host "API Key Exist and Active"
    }    
}
catch {    
    If ( $_ | Select-String -Pattern 'Unknown account'){
        Write-Host "[ERROR] : Invalid API Key"
    }Else{
        Write-Host "[ERROR]	: $_"
    }
    Exit
}

try {
	$Computers = Invoke-RestMethod -Uri $Computers_Uri -Method Get -Headers $Headers
}
catch {
	Write-Host "[ERROR]	Pulling Computers: $_"
    Exit
}

try {
	$Policies  = Invoke-RestMethod -Uri $Policies_Uri -Method Get -Headers $Headers
}
catch {
	Write-Host "[ERROR]	Pulling Policies: $_"
    Exit
}

if ((Test-Path $REPORTFILE) -eq $true){
    $BackupDate          = get-date -format MMddyyyy-HHmm
    $BackupReportName    = $REPORTNAME + "_" + $BackupDate + ".csv"
    copy-item -Path $REPORTFILE -Destination $BackupReportName
    Remove-item $REPORTFILE
}

$ReportHeader = 'AWSAccountID, Host_ID, HostName, DisplayName, RelayID, AgentStatus, AgentVersion, AgentOS, InstanceID, InstancePowerState, PolicyName, AntiMalwareState, WebReputationState, FirewallState, IntrusionPreventionState, IntegrityMnitoringState, LogInspectionState, ApplicaionControlState'
Add-Content -Path $REPORTFILE -Value $ReportHeader

foreach ($Item in $Computers.computers){
	$Host_ID					= $Item.ID
	$PolicyID					= $Item.policyID
	$PolicyName					= ($Policies.policies | Where-Object {$_.ID -eq $PolicyID}).name
	$HostName					= $Item.hostName
	$DisplayName				= $Item.displayName
	$RelayID					= $Item.relayListID
	$AgentStatus				= $Item.computerStatus.agentStatusMessages
	$AgentVersion				= $Item.agentVersion
	$AgentOS					= $Item.ec2VirtualMachineSummary.operatingSystem
	$InstanceID					= $Item.ec2VirtualMachineSummary.instanceID
	$InstancePowerState			= $Item.ec2VirtualMachineSummary.state
	$AWSAccountID				= $Item.ec2VirtualMachineSummary.accountID
	$AntiMalwareState			= $Item.antiMalware.state
	$WebReputationState			= $Item.webReputation.state
	$FirewallState				= $Item.firewall.state 
	$IntrusionPreventionState	= $Item.intrusionPrevention.state
	$IntegrityMnitoringState	= $Item.integrityMonitoring.state
	$LogInspectionState			= $Item.logInspection.state
	$ApplicaionControlState		= $Item.applicationControl.state

	$ReportData =  "$AWSAccountID, $Host_ID, $HostName, $DisplayName, $RelayID, $AgentStatus, $AgentVersion, $AgentOS, $InstanceID, $InstancePowerState, $PolicyName, $AntiMalwareState, $WebReputationState, $FirewallState, $IntrusionPreventionState, $IntegrityMnitoringState, $LogInspectionState, $ApplicaionControlState"
	Add-Content -Path $REPORTFILE -Value $ReportData
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)

Write-Host "Script Execution is Complete.  It took $totalTime"
