<#
    Rename pdplayer username to newname
#>

param
(
    [string]$username,
    [string]$password = "RegTest6100",
    [switch]    $help,
    [switch]    $h
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Off #-Trace 2

$ScriptName = $MyInvocation.MyCommand.Name
function showHelp()
{
    Write-Output "Rename pdplayer username to newname"
    Write-Output "USAGE: $ScriptName [option] -username <curUsername>"
    Write-Output "  option"
    Write-Output "      -password <password default=RegTest6100>"
    exit 1
}

if ($h -or $help) {showHelp}
if ( -not($username) ) {showHelp}

$curUsername = $username
($base, $domain) = $curUsername.split('@')
$theChange = $base.Chars($base.Length - 1)
$newUsername = "{0}{1}@{2}" -f $base, $theChange, $domain

Write-Output "Renaming $curUsername to $newUsername ..."
$curUsernameJson = pdplayer.ps1 -hostname cadev1 -getpersonalinfo -username $curUsername -password $password
$obj = $curUsernameJson | convertfrom-json
$obj.emails[0].PERSONAL.address = $newUsername
$filename = "$env:TEMP/ch-email.json"
$obj | ConvertTo-Json | Out-file -encoding UTF8 -force $filename
pdplayer.ps1 -hostname cadev1 -updatepersonalinfo $filename -username $curUsername -password $password | out-null