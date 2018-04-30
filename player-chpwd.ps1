param
(
    [string]$hostname,
    [int] $port = 80,
    [string]$username,
    [string]$password,
    [int] $changeCount = 1,
    [switch]$quiet = $false,
    [switch]$go = $false,
    [switch]$help,
    [switch]$h
)

$ErrorActionPreference = "stop"
Set-StrictMode -Version Latest
$ScriptName = $MyInvocation.MyCommand.Name
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
function showHelp()
{
    Write-Host "USAGE: ${ScriptName} [options] -hostname <hostname> -username <name> -password <password>"
    Write-Host "Options:"
    Write-Host "  -port <port>                      default = 80"
    Write-Host "  -changeCount <int>                default = 1"
    Write-Host "  -go                               Default print what would be done"
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

    if ($go)
    {
        pdplayer -hostname $hostname -port $port -username $username -chpwd $curpwd -newpwd $restorepwd
    }
}

function changePassword ($curpwd, $newpwd)
{
    $theCall = "-hostname $hostname -port $port -username $username -chpwd $curpwd -newpwd $newpwd"
    $msg = "  {0}: `t{1}" -f 'changePassword', $theCall
    if (-not ($quiet)) {Write-Output $msg}

    if ($go)
    {
        pdplayer -hostname $hostname -port $port -username $username -chpwd $curpwd -newpwd $newpwd
    }
}

$newPassword = "Newpassword1"

for ($i = 1; $i -le ($changeCount) ; $i++)
{
    changePassword $password $newPassword
    restorePassword $newPassword  $password
}
