<#
    Rename pdplayer username to newname
#>

param
(
    [int]$port = 80,
    [string]$h, # hostname
    [string]$hostname,
    [string]$u,
    [string]$username,
    [string]$newUsername,
    [string]$p        = "Password1",
    [string]$password = "Password1",
    [switch]    $help
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Off #-Trace 2

$ScriptName = $MyInvocation.MyCommand.Name
function showHelp()
{
    Write-Output "Rename pdplayer username to newname"
    Write-Output "USAGE: $ScriptName [option] -h[ostname] <hostname> -username <name> -newUsername <name>"
    Write-Output "  option"
    Write-Output "  -p[assword] <password default=$password>"
    Write-Host "    -port <int default=${port}>"
    exit 1
}

if ($help) {showHelp}
if (-not ($h -or $hostname)) { showHelp }
if ( -not($u -or $username) ) { showHelp }
if ( -not($newUsername) ) { showHelp }

if ($h) { $hostname = $h }
if ($p) { $password = $p }
if ($u) { $username = $u }

$curUsername = $username
Write-Output "Renaming $curUsername to $newUsername ..."
$obj = (pdplayer.ps1 -hostname $hostname -getpersonalinfo -username $curUsername -password $password).Content | convertfrom-json
$obj.emails[0].PERSONAL.address = $newUsername
$filename = "$env:TEMP/ch-email.json"
$obj | ConvertTo-Json | Out-file -encoding UTF8 -force $filename
pdplayer.ps1 -h $hostname -updatepersonalinfo $filename -username $curUsername -password $password | out-null
Start-Sleep 2
$sessionToken = pdplayer.ps1 -h $hostname -logintoken $newUsername -password $password
Write-Output "$newUsername logged in, session token: $sessionToken"