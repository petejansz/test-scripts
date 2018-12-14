<#
    Command-line script to automate, repeatedly a PD player changing thier password. Original password is restored.
    Author: Pete Jansz, IGT, June 2017
#>

param
(
    [string]$hostname,
    [int] $port = 80,
    [string]$username,
    [string]$password,
    [int] $count = 1,
    [switch]$quiet = $false,
    [switch]$help,
    [switch]$h
)

$ErrorActionPreference = "stop"
Set-StrictMode -Version Latest
$ScriptName = $MyInvocation.MyCommand.Name
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
function showHelp()
{
    Write-Host "Automate, repeatedly a PD player changing thier password."
    Write-Host "The original password is restored.`n"
    Write-Host "USAGE: ${ScriptName} [options] -hostname <hostname> -username <name> -password <password>"
    Write-Host "Options:"
    Write-Host "  -port <port>    default = 80"
    Write-Host "  -count <int>    default = 1"
    Write-Host "  -quiet"

    exit 1
}

if ($h -or $help) {showHelp}
if ( -not($hostname) ) {showHelp}
if ( -not($username) ) {showHelp}
if ( -not($password) ) {showHelp}

function restorePassword ($curpwd, $restorepwd)
{
    $theCall = "-hostname $hostname -port $port -username $username -chpwd $curpwd -newpwd $restorepwd"
    $msg = "{0}: `t{1}" -f 'restorePassrword', $theCall

    if (-not ($quiet)) {Write-Output $msg}

    pdplayer -hostname $hostname -port $port -username $username -chpwd $curpwd -newpwd $restorepwd
}

function changePassword ($curpwd, $newpwd)
{
    $theCall = "-hostname $hostname -port $port -username $username -chpwd $curpwd -newpwd $newpwd"
    $msg = "  {0}: `t{1}" -f 'changePassword', $theCall
    if (-not ($quiet)) {Write-Output $msg}

    pdplayer -hostname $hostname -port $port -username $username -chpwd $curpwd -newpwd $newpwd
}

$newPassword = "Newpassword1"

for ($i = 1; $i -le $count; $i++)
{
    changePassword $password $newPassword
    restorePassword $newPassword  $password
}
