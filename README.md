# DSaaS_Agent_Report

AUTHOR		: Yanni Kashoqa

TITLE		: Deep Security Agent Information

VERSION		: 0.2

DESCRIPTION	: This Powershell script will perform report the Deep Security Agent status information from either DSaaS or a local DSM

FEATURES
The ability to perform the following:-
- Access the Deep Security Manager using SOAP and REST protocols to pull Agent status information

REQUIRMENTS
- Supports Deep Security as a Service
- PowerShell 6.x
- Login name and password with role "Full Access" assigned to it
- An API key that is created on DSM/DSaaS console
- Create a DS-Config.json in the same folder with the following content:

{
    "MANAGER": "app.deepsecurity.trendmicro.com",
    "PORT": "443",
    "TENANT": "",
    "USER_NAME": "",
    "PASSWORD": "",
    "APIKEY" : ""
}

REPORTED VALUES
- Host ID
- overallStatus
- overallVersion
- operating_system
- instance_id
- securityProfileName
- AntiMalwareStatus
- LastRecommendationScan
