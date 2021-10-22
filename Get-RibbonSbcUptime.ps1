<#
.SYNOPSIS
Get-RibbonSbcUptime.ps1 invokes a REST login to your Sonus/Ribbon SBC 1k/2k/SWe-Lite and reports how long it's been running: the CpuUptime.

.DESCRIPTION
Get-RibbonSbcUptime.ps1 invokes a REST login to your Sonus/Ribbon SBC 1k/2k/SWe-Lite and reports how long it's been running: the CpuUptime.
It outputs either a timespan object to the pipeline, or a literal string in the same format the SBC displays on its System / Overview tab.


.NOTES
	Version				: 1.1
	Date				: 23rd October 2021
	Author				: Greig Sheridan

		Wishlist / TODO:
						#?

	Revision History	:

					v1.1: 23rd October 2021
						Changed fn 'BasicHandler' to accept varying 'xml' responses from the SBC
					
					v1.0: 16th November 2019



.LINK
	https://greiginsydney.com/Get-RibbonSbcUptime.ps1

.EXAMPLE
	.\Get-RibbonSbcUptime.ps1 -SbcFQDN mysbc.contoso.local -RestLogin REST -RestPassword PA$$W0rd

	Description
	-----------
	Logs in to the SBC and reports the "rt_CPUUptime" value (as a timespan object) to screen and pipeline

.EXAMPLE
	.\Get-RibbonSbcUptime.ps1 -SbcFQDN mysbc.contoso.local -RestLogin REST -RestPassword PA$$W0rd -AsTimeString

	Description
	-----------
	Logs in to the SBC and reports the "rt_CPUUptime" value (as a long format text string) to screen and pipeline
	
.EXAMPLE
	.\$UPTIME = (Get-RibbonSbcUptime.ps1 -SbcFQDN mysbc.contoso.local -RestLogin REST -RestPassword PA$$W0rd -SkipUpdateCheck)

	Description
	-----------
	Executes the script - skipping the update check - then logs into the SBC and captures the "rt_CPUUptime" as a timespan object in the variable $UPTIME


.PARAMETER SbcFQDN
	String.

.PARAMETER RestLogin
	String.

.PARAMETER RestPassword
	String.

.PARAMETER AsTimeString
	Switch. If specified, outputs the uptime in the same format as rendered in the broswser.

.PARAMETER SkipUpdateCheck
	Switch. Skips the automatic check for an Update. Courtesy of Pat: http://www.ucunleashed.com/3168

#>

[CmdletBinding(SupportsShouldProcess = $False)]
Param(

	[string]$SbcFQDN,
	[string]$RestLogin,
	[string]$RestPassword,
	[switch]$AsTimeString,
	[switch]$SkipUpdateCheck
)


#--------------------------------
# START FUNCTIONS ---------------
#--------------------------------
#region functions

function Get-UpdateInfo
{
	<#
		.SYNOPSIS
		Queries an online XML source for version information to determine if a new version of the script is available.
		*** This version customised by Greig Sheridan. @greiginsydney https://greiginsydney.com ***

		.DESCRIPTION
		Queries an online XML source for version information to determine if a new version of the script is available.

		.NOTES
		Version					: 1.2 - See changelog at https://ucunleashed.com/3168 for fixes & changes introduced with each version
		Wish list				: Better error trapping
		Rights Required			: N/A
		Sched Task Required		: No
		Lync/Skype4B Version	: N/A
		Author/Copyright		: © Pat Richard, Office Servers and Services (Skype for Business) MVP - All Rights Reserved
		Email/Blog/Twitter		: pat@innervation.com  https://ucunleashed.com	@patrichard
		Donations				: https://www.paypal.me/PatRichard
		Dedicated Post			: https://ucunleashed.com/3168
		Disclaimer				: You running this script/function means you will not blame the author(s) if this breaks your stuff. This script/function
								is provided AS IS without warranty of any kind. Author(s) disclaim all implied warranties including, without limitation,
								any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use
								or performance of the sample scripts and documentation remains with you. In no event shall author(s) be held liable for
								any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss
								of business information, or other pecuniary loss) arising out of the use of or inability to use the script or
								documentation. Neither this script/function, nor any part of it other than those parts that are explicitly copied from
								others, may be republished without author(s) express written permission. Author(s) retain the right to alter this
								disclaimer at any time. For the most up to date version of the disclaimer, see https://ucunleashed.com/code-disclaimer.
		Acknowledgements		: Reading XML files
								http://stackoverflow.com/questions/18509358/how-to-read-xml-in-powershell
								http://stackoverflow.com/questions/20433932/determine-xml-node-exists
		Assumptions				: ExecutionPolicy of AllSigned (recommended), RemoteSigned, or Unrestricted (not recommended)
		Limitations				:
		Known issues			:

		.EXAMPLE
		Get-UpdateInfo -Title 'Get-RibbonSbcUptime.ps1'

		Description
		-----------
		Runs function to check for updates to script called 'Get-RibbonSbcUptime.ps1'.

		.INPUTS
		None. You cannot pipe objects to this script.
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	[string] $title
	)
	try
	{
		[bool] $HasInternetAccess = ([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet)
		if ($HasInternetAccess)
		{
			write-verbose -message 'Performing update check'
			# ------------------ TLS 1.2 fixup from https://github.com/chocolatey/choco/wiki/Installation#installing-with-restricted-tls
			$securityProtocolSettingsOriginal = [Net.ServicePointManager]::SecurityProtocol
			try {
			  # Set TLS 1.2 (3072). Use integers because the enumeration values for TLS 1.2 won't exist in .NET 4.0, even though they are
			  # addressable if .NET 4.5+ is installed (.NET 4.5 is an in-place upgrade).
			  [Net.ServicePointManager]::SecurityProtocol = 3072
			} catch {
			  write-verbose -message 'Unable to set PowerShell to use TLS 1.2 due to old .NET Framework installed.'
			}
			# ------------------ end TLS 1.2 fixup
			[xml] $xml = (New-Object -TypeName System.Net.WebClient).DownloadString('https://greiginsydney.com/wp-content/version.xml')
			[Net.ServicePointManager]::SecurityProtocol = $securityProtocolSettingsOriginal #Reinstate original SecurityProtocol settings
			$article  = select-XML -xml $xml -xpath ("//article[@title='{0}']" -f ($title))
			[string] $Ga = $article.node.version.trim()
			if ($article.node.changeLog)
			{
				[string] $changelog = 'This version includes: ' + $article.node.changeLog.trim() + "`n`n"
			}
			if ($Ga -gt $ScriptVersion)
			{
				$wshell = New-Object -ComObject Wscript.Shell -ErrorAction Stop
				$updatePrompt = $wshell.Popup(("Version {0} is available.`n`n{1}Would you like to download it?" -f ($ga), ($changelog)),0,'New version available',68)
				if ($updatePrompt -eq 6)
				{
					Start-Process -FilePath $article.node.downloadUrl
					write-warning -message "Script is exiting. Please run the new version of the script after you've downloaded it."
					exit
				}
				else
				{
					write-verbose -message ('Upgrade to version {0} was declined' -f ($ga))
				}
			}
			elseif ($Ga -eq $ScriptVersion)
			{
				write-verbose -message ('Script version {0} is the latest released version' -f ($Scriptversion))
			}
			else
			{
				write-verbose -message ('Script version {0} is newer than the latest released version {1}' -f ($Scriptversion), ($ga))
			}
		}
		else
		{
		}

	} # end function Get-UpdateInfo
	catch
	{
		write-verbose -message 'Caught error in Get-UpdateInfo'
		if ($Global:Debug)
		{
			$Global:error | Format-List -Property * -Force #This dumps to screen as white for the time being. I haven't been able to get it to dump in red
		}
	}
}

function Read-UserInput
{
	param (
	[string] $prompt,
	[string] $default,
	[boolean] $displayOnly
	)

	#"Padright" done a little differently:
	while (($prompt.length + $default.length) -le 30)
	{
		$prompt = $prompt + " "
	}
	if ($default -ne "")
	{
		$prompt =  "{0} [{1}]" -f $prompt, $default
	}
	else
	{
		#Don't show the square brackets if there's no default value
		$prompt =  "{0}	  " -f $prompt
	}

	if ($DisplayOnly)
	{
		Write-Host $prompt
	}
	else
	{
		if (($response = Read-Host -Prompt $prompt) -eq "")
		{
			$response = $default
		}
	}
	return $response
}


### Return the result of the request
Function BasicHandler
{
	Param($MyResult)
	
	if ($myresult.GetType().Fullname -eq 'System.String')
	{
		[xml]$XmlResult = $MyResult.trimstart()
	}
	else
	{
		[xml]$XmlResult = $MyResult
	}
	
	if($XmlResult.root.status.http_code.contains("200"))
	{
		$info = @{
			"Success" = $True;
			"Result" = $XmlResult.root.status.http_code;
			"ErrorCode" = $null;
			"ErrorParam" = $null
		}
	}
	else
	{
		$info = @{
			"Success" = $False;
			"Result" = $XmlResult.root.status.http_code;
			"ErrorCode" = $XmlResult.root.status.app_status.app_status_entry.code;
			"ErrorParam" = $XmlResult.root.status.app_status.app_status_entry.params
		}
	}
	$resultInfo = New-Object -TypeName PSObject -Property $info
	return $resultInfo
}


function Login
{
	param (
	[string] $SbcFqdn,
	[string] $RestLogin,
	[string] $RestPassword
	)

add-type @"
	using System.Net;
	using System.Security.Cryptography.X509Certificates;

	public class IDontCarePolicy : ICertificatePolicy {
		public IDontCarePolicy() {}
		public bool CheckValidationResult(
			ServicePoint sPoint, X509Certificate cert,
			WebRequest wRequest, int certProb) {
			return true;
		}
	}
"@

	[System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy

	$BodyValue = "Username=$RestLogin&Password=$RestPassword"
	$url = "https://$SbcFqdn/rest/login"
	try
	{
		$Query = Invoke-RestMethod -Uri $url -Method Post -Body $BodyValue -SessionVariable SessionVar -verbose:$false
	}
	catch [System.Net.WebException]
	{
		$info = @{
			"Success" = $False;
			"Result" = $_.Exception; # Presumably "The remote name could not be resolved"
			"ErrorCode" = 404;
			"ErrorParam" = ""
		}
		$resultInfo = New-Object -TypeName PSObject -Property $info
		return $resultInfo
	}
	$Global:SessionVar = $SessionVar
	return (BasicHandler $Query)

}

#endregion Functions
#--------------------------------
# END  FUNCTIONS ---------------
#--------------------------------


#--------------------------------
# THE FUN STARTS HERE -----------
#--------------------------------

$ScriptVersion = "1.1"
$Error.Clear()
$Global:Debug = $psboundparameters.debug.ispresent
$Global:SessionVar = $null #This is the ID of the session we have open to the SBC

If ($PsVersionTable.PsVersion.Major -lt 3)
{
	Write-warning -Message "Sorry, your P$ version ($($PsVersionTable.PsVersion.ToString())) is too old: Invoke-RestMethod hasn't been invented yet"
	exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($skipupdatecheck)
{
	Write-verbose "Skipping update check"
}
else
{
	write-progress -id 1 -Activity 'Initialising' -Status 'Performing update check' -PercentComplete (0)
	Get-UpdateInfo -title 'Get-RibbonSbcUptime.ps1'
	write-progress -id 1 -Activity 'Initialising' -Status 'Back from performing update check' -Complete
}

try
{
	if (($SbcFQDN -eq "") -or ($RestLogin -eq "") -or ($RestPassword -eq ""))
	{
		$SbcFQDN = read-UserInput "SBC FQDN" $SbcFQDN
		$RestLogin = read-UserInput "REST login name" $RestLogin
		$RestPassword = read-UserInput "REST password " $RestPassword
	}
	Write-Verbose -Message "Attempting to login"
	$result = Login $SbcFQDN $RestLogin $RestPassword
	if ($result.Success -eq $true)
	{
		Write-Verbose -Message "Login successful"
	}
	else
	{
		if ($Result.Result -like "*Unable to connect to the remote server*")
		{
			Write-Warning -Message "Login failed. Unable to connect to the remote server."
		}
		elseif ($Result.Result -like "*The remote name could not be resolved*")
		{
			Write-Warning -Message "Login failed. The SBC name could not be resolved."
		}
		elseif ($Result.Result -contains 500)
		{
			Write-Warning -Message "Login failed. Bad login name or password."
		}
		else
		{
			Write-Warning -Message "Login failed. Error result = $($Result.Result)"
		}
		exit
	}

	Write-Verbose "About to query historical statistics"
	$url = "https://$SbcFQDN/rest/system/historicalstatistics/1"
	$Query = Invoke-RestMethod -Uri $url -Method GET -WebSession $Global:SessionVar -verbose:$false
	$result = BasicHandler $Query
	if ($Result.Success -eq $true)
	{
		$Uptime = $query.root.historicalstatistics.rt_CPUUptime
		$ts = [timespan]::fromseconds($Uptime)
		$FormattedString = ""
		[int]$totalweeks = $ts.totaldays / 7
		[int]$leftoverdays = $ts.totaldays % 7
		if ($totalweeks -ge 1)
		{
			#Only show weeks if we have been running more than 1
			$FormattedString += $totalweeks.ToString()
			if ($totalweeks -gt 1) { $FormattedString += " weeks, "} else { $FormattedString += " week, "}
		}
		if ($ts.leftoverdays -ne 0)
		{
			#Only show days if we have been running more than 1
			$FormattedString += $leftoverdays.ToString()
			if ($leftoverdays -eq 1) { $FormattedString += " day, "} else { $FormattedString += " days, "}
		}
		if ($ts.hours -ne 0)
		{
			#Only show hours if we have been running more than 1
			$FormattedString += $ts.hours.ToString()
			if ($ts.hours -eq 1) { $FormattedString += " hr, "} else { $FormattedString += " hrs, "}
		}
		if ($ts.minutes -ne 0)
		{
			#Only show minutes if we have been running more than 1
			$FormattedString += $ts.minutes.ToString()
			if ($ts.minutes -eq 1) { $FormattedString += " min, "} else { $FormattedString += " mins, "}
		}
		$FormattedString += $ts.seconds.ToString()
		if ($ts.seconds -eq 1) { $FormattedString += " sec"} else { $FormattedString += " secs"}

		if ($ts.totalseconds -eq 0) { Write-Warning -message "rt_CPUUptime is broken in this version of SBC firmware. Upgrade to v8.0.3 or later" }
		if ($AsTimeString)
		{
			$FormattedString
		}
		else
		{
			$ts
		}
	}
	else
	{
		Write-Warning -Message "Query failed: $($Result.Result)"
	}
}
catch
{
	if ($debug)
	{
		Write-Output "Unhandled crash. Error was $_ "
		$Global:error | Format-List -Property * -Force
	}
	else
	{
		Write-Output "Unhandled crash. Error was $_ "
	}
}

Write-Verbose -Message "Done!"

# References
# Based on "Using REST to deploy an SBA on Sonus SBC1000/2000" by Adrien Plessis
# Largely a "save-as" of https://greiginsydney.com/update-ribbonadcache-ps1/
#	http://www.cusoon.fr/using-rest-to-deploy-an-sba-on-sonus-sbc10002000/#All_in_One
# Function return handling stolen with much gratitude from James Cussen: https://gallery.technet.microsoft.com/Skype-for-Business-Lync-04884260

#Code signing certificate kindly provided by Digicert:
# SIG # Begin signature block
# MIIZkAYJKoZIhvcNAQcCoIIZgTCCGX0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkHxJchs8t3oi3IkkYHt5Waec
# qpygghSeMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAwMDAwMFoXDTMxMDEw
# NjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HXOhFCvQp1dU2UtAxQ
# tSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB+in43Stwhd4CGPN4
# bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPhLxs6t2HWc+xObTOK
# fF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizVI9r0TXhG4wODMSlK
# XAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKbaYK02/xWVLwfoYer
# vnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQECAwEAAaOCAbgwggG0
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYIKwYBBQUHAgEWG2h0
# dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAWgBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ23eNqerwwcQYDVR0f
# BGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJl
# ZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRpbWVzdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucgDo5nRv1CclF0CiNH
# o6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1ppA/2uHDPYuj1UUp4
# eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18jUmmDgvoaU+2QzI2h
# F3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFcz8QRcucbZEnYIpp1
# FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub9y4bTxMd90oNcX6X
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBS8wggQX
# oAMCAQICEAqt2yhVXFSaEiY6y4bT9zkwDQYJKoZIhvcNAQELBQAwcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQTAeFw0yMTA0MjMwMDAwMDBaFw0yMjA4MDQyMzU5NTlaMG0xCzAJ
# BgNVBAYTAkFVMRgwFgYDVQQIEw9OZXcgU291dGggV2FsZXMxEjAQBgNVBAcTCVBl
# dGVyc2hhbTEXMBUGA1UEChMOR3JlaWcgU2hlcmlkYW4xFzAVBgNVBAMTDkdyZWln
# IFNoZXJpZGFuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxrk1NuHH
# qyg9djhyuoE1UdImHdEItBzg/7zQ87RAQthP71A2GJ++zokQ6KfjbH5+UrEdODZN
# ibJF6/PnaVC1tUKPQHnauezk7ozu0JeUjLrxndxV8VEy3R/7wXp4hQ7XGaIehhhI
# u5+b6M0ZdTAmt93cT6AJYy8v/dPJr1DmZkj2KSbj10Ca9unAegKWsyDJmCQQ2EU5
# KxlRmPMwZK6as/SfAYVOxTnb5t7kO/F0HyKZJar5czLZn7CVWVke5QTqL6ZTnQg9
# 0u18c96gesFPAl247h+SgcLP4FOSzKVrF4NeMAyXlxettGiF2iei3r6zz8BEyhR0
# CXdbGzgmqDaU8QIDAQABo4IBxDCCAcAwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPA
# YPkt9mV1DlgwHQYDVR0OBBYEFDGB9TXcWUxGF52VHrnUqrZUeyXyMA4GA1UdDwEB
# /wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9o
# dHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1
# oDOgMYYvaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1n
# MS5jcmwwSwYDVR0gBEQwQjA2BglghkgBhv1sAwEwKTAnBggrBgEFBQcCARYbaHR0
# cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEE
# eDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYB
# BQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJB
# c3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3
# DQEBCwUAA4IBAQDx1qRhZTX/nkQW4jCx2zWZsKJjMbeIUWMLi2dnuU9A9n1fIwwv
# +ab3jBKmoztY171Kxs0U97Tm/IzlwPeekIBKmTtThdBFmSqfU09eUPvtjLuI7H1j
# REAYH6MlzBIGRqbfaTSr7f+bSdSHsXZ68fB4zZyBg3s5N98yEFUe+978Of0hWRA5
# HlsNAdwjgih3dk9h1qBoqjVpt7VFLzpz7c99QBEND1zwn0VAwaxrFylraKjtnApK
# Gbu9Ow0YmL8kQ81B+pop8KzxQVEKA2A5wGpJciWgSSAatyEPZrPdcqIccktfV6gw
# pFZcN20IMqgQMv19mWLgywAJ2Er/ixi7G36qMIIFMDCCBBigAwIBAgIQBAkYG1/V
# u2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYD
# VQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAw
# WhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdp
# Q2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/
# 5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH
# 03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxK
# hwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr
# /mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi
# 6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCC
# AckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAww
# CgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6
# MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1s
# AAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMw
# CgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1Ud
# IwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+
# 7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbR
# knUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7
# uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7
# qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPa
# s7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR
# 6mhsRDKyZqHnGKSaZFHvMIIFMTCCBBmgAwIBAgIQCqEl1tYyG35B5AXaNpfCFTAN
# BgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2Vy
# dCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTYwMTA3MTIwMDAwWhcNMzEwMTA3MTIw
# MDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAvdAy7kvNj3/dqbqCmcU5VChXtiNKxA4HRTNREH3Q+X1NaH7ntqD0
# jbOI5Je/YyGQmL8TvFfTw+F+CNZqFAA49y4eO+7MpvYyWf5fZT/gm+vjRkcGGlV+
# Cyd+wKL1oODeIj8O/36V+/OjuiI+GKwR5PCZA207hXwJ0+5dyJoLVOOoCXFr4M8i
# EA91z3FyTgqt30A6XLdR4aF5FMZNJCMwXbzsPGBqrC8HzP3w6kfZiFBe/WZuVmEn
# KYmEUeaC50ZQ/ZQqLKfkdT66mA+Ef58xFNat1fJky3seBdCEGXIX8RcG7z3N1k3v
# BkL9olMqT4UdxB08r8/arBD13ays6Vb/kwIDAQABo4IBzjCCAcowHQYDVR0OBBYE
# FPS24SAd/imu0uRhpbKiJbLIFzVuMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6en
# IZ3zbcgPMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0
# cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNV
# HR8EejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMFAGA1UdIARJMEcwOAYKYIZI
# AYb9bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20v
# Q1BTMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAQEAcZUS6VGHVmnN793a
# fKpjerN4zwY3QITvS4S/ys8DAv3Fp8MOIEIsr3fzKx8MIVoqtwU0HWqumfgnoma/
# Capg33akOpMP+LLR2HwZYuhegiUexLoceywh4tZbLBQ1QwRostt1AuByx5jWPGTl
# H0gQGF+JOGFNYkYkh2OMkVIsrymJ5Xgf1gsUpYDXEkdws3XVk4WTfraSZ/tTYYmo
# 9WuWwPRYaQ18yAGxuSh1t5ljhSKMYcp5lH5Z/IwP42+1ASa2bKXuh1Eh5Fhgm7oM
# LSttosR+u8QlK0cCCHxJrhO24XxCQijGGFbPQTS2Zl22dHv1VjMiLyI2skuiSpXY
# 9aaOUjGCBFwwggRYAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERp
# Z2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0ECEAqt2yhVXFSa
# EiY6y4bT9zkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAw
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFE6NxxkKADF5GargKtITEyrCltRbMA0G
# CSqGSIb3DQEBAQUABIIBAJVFCesKnaLgbO9JfoeO/9Kuf44mzO5dOEH6keUVaENs
# uFhaZHegBXbf6PtwbGSSeo+Q94inaSqFj51FHW+wwg6cUEZ1JTtXcZNTTPnDCPqU
# CdMZveXF4PBKhsGiuLJGYtXFMzJBMyKIb8IdDTGRGGcv+tXplVSL4cfMu3qDoqXC
# Cfa/FSFDvG7EGcDc/EvT/B7Dy2nV2ocdbwc508CSWOdaempez1VNgB6bRlXVKc73
# n2N6xPee5P/0bLltspO1IyAhTwibDBwLQ0tL5W+tjEGu32GdJnHsrhw68UWARRBb
# 8ULh7BvkTdOejgTYGFdpFgn7Poev+brHTNbe2AXiwGyhggIwMIICLAYJKoZIhvcN
# AQkGMYICHTCCAhkCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIFRpbWVzdGFtcGluZyBDQQIQDUJK4L46iP9g
# QCHOFADw3TANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0B
# BwEwHAYJKoZIhvcNAQkFMQ8XDTIxMTAyMjIyNDU0NlowLwYJKoZIhvcNAQkEMSIE
# IKUXNv5VBXjFNzvgMmhTwAH/r90pufVf1/vH9BK7FSxFMA0GCSqGSIb3DQEBAQUA
# BIIBAENrdR3n4NRXD1tN7ARGDf4jPGByvywdnP9Zx0yf6Nw4xkINgUKcFcr16LMX
# 2oKx9YnNtj0tiQxu4kDWTk6MFtrgwHq1vqa/cmrTuqbda7LPKIVOrz7CybpCoDve
# P5i/uUmsNC+ppEpFkl2MOm0c2MNeled/+wb7+J6POIWql+0M5SehGSJIbRqsVCj0
# eOx501/d0LOCJ7tzgW49juIcSfkBux8+Lw3rc9TgRDHfA6MRf0Pm08aFQ6JSMncj
# oZxGRSrhFzKAuOWURhyX5C29G/Co0Dw3O6rUXVYsPm1juRJ+kGKJKnGsxwgbUlp3
# lxSrR7wFr3PP+O5UQzHJzSk4irQ=
# SIG # End signature block
