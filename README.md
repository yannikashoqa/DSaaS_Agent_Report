# DSaaS_Agent_Report

AUTHOR		: Yanni Kashoqa

TITLE		: Deep Security Agent Information

DESCRIPTION	: This Powershell script will perform report the Deep Security Agent status information from DSaaS

FEATURES
The ability to perform the following:-
- Access the Deep Security Manager using SOAP and REST protocols to pull Agent status information

REQUIRMENTS
- Supports Deep Security as a Service
- PowerShell 6.x for the REST version (DSaaS_Agent_Report.ps1)
- Powershell 5.1 for the SOAP version (DSaaS_Agent_Report_SOAP.ps1)
- An API key that is created on DSM/DSaaS console
- Create a DS-Config.json in the same folder with the following content:
- For REST:
{
    "MANAGER": "app.deepsecurity.trendmicro.com",
    "PORT": "443",
    "APIKEY" : "",
    "REPORTNAME" : "DSaaS_Agent_Report"
}

- For SOAP:
{
    "MANAGER": "app.deepsecurity.trendmicro.com",
    "PORT": "443",
    "TENANT": "",
    "USER_NAME": "",
    "PASSWORD": "",
    "REPORTNAME" : "DSaaS_Agent_Report"
}

