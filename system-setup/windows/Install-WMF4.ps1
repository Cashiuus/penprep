##############################################################################
##
## Install-WMF4 (PowerShell 4.0)
##
## by Cashiuus on 9/8/2015
## 
##
## WMF 4.0: http://www.microsoft.com/en-us/download/details.aspx?id=40855
##############################################################################

## Setup PowerShell 4.0 using Chocolatey - https://chocolatey.org/packages/PowerShell
## @powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%systemdrive%\chocolatey\bin
## cinst powershell

Set-StrictMode -Version Latest
$static_env_path = 'c:\envs'
$silent_args = "/quiet /norestart"
$LatestPSHVersion = '5.0'
$os_arch = $env:PROCESSOR_ARCHITECTURE    #AMD64
$url_net45 = "http://download.microsoft.com/download/B/A/4/BA4A7E71-2906-4B2D-A0E1-80CF16844F5F/dotNetFx45_Full_setup.exe"
$url_wmf4_x86 = "http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x86-MultiPkg.msu"
$url_wmf4_x64 = "http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu"
$url_wmf4_32win7   =  'http://download.microsoft.com/download/3/F/D/3FD04B49-26F9-4D9A-8C34-4533B9D5B020/Win7AndW2K8R2-KB3066439-x86.msu'
$url_wmf4_64win7 = 'http://download.microsoft.com/download/3/F/D/3FD04B49-26F9-4D9A-8C34-4533B9D5B020/Win7AndW2K8R2-KB3066439-x64.msu'
$url_wmf4_win2012 = 'http://download.microsoft.com/download/3/F/D/3FD04B49-26F9-4D9A-8C34-4533B9D5B020/W2K12-KB3066438-x64.msu'

## Begin Script
if( -not (Test-Path $static_env_path -PathType Container))
{
	mkdir c:\envs
}
cd c:\envs

if ($PSVersionTable -and ($PSVersionTable.PSVersion -ge [Version]$LatestPSHVersion))
{
	Write-Warning "The installed PowerShell $(PSVersionTable.PSVersion) is already the current version."
}
else
{
	$osVersion = (Get-WmiObject Win32_OperatingSystem).Version
	$net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue)

	if($net4Version)
	{
		


	(new-object System.Net.WebClient).DownloadFile($url_wmf4_x64, 'c:\envs\wmf4.msu')
	c:\envs\wmf4.msu /quiet /norestart /log


}