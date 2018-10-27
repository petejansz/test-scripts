param
(
    [string]$hostname = "cadev1",
    [string]$token,
    [int]$port = 80,
    [switch]$help,
    [switch]$h
)

$ErrorActionPreference = "stop"
Set-StrictMode -Version Latest
Set-PSDebug -Off #-Trace 2

$ScriptName = $MyInvocation.MyCommand.Name
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
function showHelp()
{
    Write-Host "USAGE: ${ScriptName} [options] -hostname <hostname> -token <token>"
    Write-Host "Options:"
    Write-Host "  -port <int default=80>"
    exit 1
}

if ($h -or $help) {showHelp}
if ( -not($hostname) -or -not $token ) {showHelp}

. lib-register-ca-player.ps1

$responses = @()
$responses += execRestGetAttributes $hostname $port $token
# $responses += execRestGetComPrefs $hostname $port $token
# $responses += execRestGetNotificationsPrefs $hostname $port $token
# $responses += execRestGetPersonalInfo $hostname $port $token
# $responses += execRestGetProfile $hostname $port $token

$responses
