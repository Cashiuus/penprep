##############################################################################
##
## Install-PythonPip
##
## by Cashiuus on 9/8/2015
## 
## *NOTE: To run PS scripts, first type: Set-ExecutionPolicy Unrestricted
## This is designed to work with Win7, which runs PowerShell v2
## Where v3+ methods exist, they are commented out and prefixed with "v3-"
##############################################################################

<#

.SYNOPSIS

Retrieve and install easy_install and pip, and ensure they are in your PATH.
Designed for Python 2.7 installations.

.EXAMPLE

PS > Install-Pip.ps1

#>

#Set-StrictMode -Version Latest
$static_env_path = 'c:\envs'
$static_python_path = 'Python27\Scripts'
## ----------------------------------------
##
## ----------------------------------------
function Test-CommandExists
{
	<#
	.SYNOPSIS
	Determines if the provided command exists.
	Returns true if exists, or false if it doesn't.
	.EXAMPLE
	PS C:\> Test_CommandExists cmd
	#>
	
	Param ($command)
	$oldPreference = $ErrorActionPreference
	$ErrorActionPreference = 'stop'
	# If the command exists, return boolean true
	try {if(Get-Command $command){RETURN $true}}
	# If the command fails to exist, return boolean false
	Catch {RETURN $false}
	Finally {$ErrorActionPreference=$oldPreference}
}


## Begin Script
if( -not (Test-Path $static_env_path -PathType Container))
{
	mkdir $static_env_path | Out-Null
}
cd c:\envs

## EASY_INSTALL
## Always run easy_install because it's the only way to update it
(new-object System.Net.WebClient).DownloadFile('https://bootstrap.pypa.io/ez_setup.py', 'c:\envs\distribute_setup.py')
python c:\envs\distribute_setup.py
#v3-(Invoke-WebRequest https://bootstrap.pypa.io/ez_setup.py).Content | python -
if($?)
{
	rm "c:\envs\distribute_setup.py"
}


## PIP
if(Test-CommandExists "pip")
{
	# Pip already exists
	Write-Host " [*] Pip already exists in PATH; running pip install --upgrade pip" -ForegroundColor Green
	pip install --upgrade pip
}
else
{
	# Pip doesn't exist so assume it needs installed
	Write-Host " [*] Now installing Pip..." -ForegroundColor Green
	(new-object System.Net.WebClient).DownloadFile('https://raw.github.com/pypa/pip/master/contrib/get-pip.py', 'c:\envs\get-pip.py')
	python c:\envs\get-pip.py
	#v3-(Invoke-WebRequest https://raw.github.com/pypa/pip/master/contrib/get-pip.py).Content | python -
}

# Check if PATH contains the current python path & the python27\Scripts directory
$path_check = $env:PATH
if($path_check.contains($static_python_path))
{
	Write-Host " [*] PATH already contains the proper entries" -ForegroundColor Yellow
	Write-Host " [PATH]: " -ForegroundColor Green -NoNewLine
	Write-Host $path_check
}
else
{
	## If it doesn't, add it
	Write-Host " [*] PATH missing '\\Scripts' entry. Adding it now..." -ForegroundColor Yellow
	Write-Host " [Old Path]: " -ForegroundColor Green -NoNewLine
	Write-Host "${path_check}"
	#setx PATH "%PATH%;C:\Python27\Scripts"
	$pathElements = @([Environment]::GetEnvironmentVariable("Path", "User") -split ";")
	$pathElements += "c:\"
	$newPath = $pathElements -join ";"
	[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
	Write-Host ""
	Write-Host " [New Path]: " -ForegroundColor Green -NoNewLine
	Write-Host "${newPath}"
}
Write-Host ""



# ===========[ Visual C for Python ]===========
#(new-object System.Net.WebClient).DownloadFile('http://aka.ms/vcpython27', 'c:\envs\vcpython27.msi'



# Install default pip modules
if(Test-CommandExists "pip")
{
    #pip install lxml
    # If using python 64-bit, don't install lxml this way, get the x64 installer instead: https://pypi.python.org/pypi/lxml
    pip install beautifulsoup4
    pip install colorama
    pip install requests
    Write-Host ""
}