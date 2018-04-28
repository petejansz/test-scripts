param
(
    [string]$username,
    [string]$password = "RegTest6100",
    [string]$hostname = "cadev1",
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
    Write-Host "USAGE: ${ScriptName} [options] -hostname <hostname> -username <username>"
    Write-Host "Options:"
    Write-Host "  -password <password default=RegTest6100>"
    Write-Host "  -port <int default=80>"
    exit 1
}

if ($h -or $help) {showHelp}
if ( -not($hostname) -or -not($username) ) {showHelp}

. lib-register-ca-player.ps1

for ($i=1; $i -lt 2; $i++)
{
    Write-Output "login $hostname $port $username $password"
    $token = login $hostname $port $username $password

    Write-Output "execRestGetAttributes"
    $jsonResponse = execRestGetAttributes $hostname $port $token

    Write-Output "execRestGetComPrefs"
    $jsonResponse = execRestGetComPrefs $hostname $port $token

    Write-Output "execRestGetNotificationsPrefs"
    $jsonResponse = execRestGetNotificationsPrefs $hostname $port $token

    Write-Output "execRestGetPersonalInfo"
    $jsonResponse = execRestGetPersonalInfo $hostname $port $token

    Write-Output "execRestGetProfile"
    $jsonResponse = execRestGetProfile $hostname $port $token

    if ($jsonResponse.StatusCode -ne 200)
    {
        $jsonResponse
    }
    else
    {
        $jsonResponse.StatusCode
    }

    # Start-Sleep 1
}
