# CASA-12799: Change email verifed flag when 2C acct reactivated

param
(
    [string]$envname = "ca-dev-pd",
    [string]$p = "Password1",
    #[int]$playerid,
    [switch]$quiet = $false,
    [string]$u,
    [switch]$help
)

$ErrorActionPreference = "stop"
Set-StrictMode -Version Latest
$ScriptName = $MyInvocation.MyCommand.Name
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
function showHelp()
{
    Write-Host "Test PD player activated->suspended->preactive"
    Write-Host "USAGE: ${ScriptName} [options] -envname <env-name (default=${envname}) > -u <username> -p <password> "
    Write-Host "Options:"

    exit 1
}

function playerServiceToStr($services)
{
    $str = "playerPortalServiceStatus: {0}, secondChanceServiceStatus: {1}, emailVerified: {2}" -f `
        $services.playerPortalServiceStatus, $services.secondChanceServiceStatus, $services.emailVerified
    return $str
}

function setAccountToActivatedState()
{
    Write-Host "Setting account to verified, activated state ... "  -NoNewLine
    $adminHost = $envname.split('-')[1]
    $playerid = (pd2-admin --host $adminHost --api search --email $u | ConvertFrom-Json).playerid
    pdplayer -h (env-alias.js -a $envname) -u $u -verify $playerid | Out-Null

    $playerServices = pdplayer -h (env-alias.js -a $envname) -u $u -p $p -getattributes | ConvertFrom-Json
    Write-Host  (playerServiceToStr $playerServices)
}

function suspendAccount
{
    Write-Host "Suspending account ... " -NoNewLine
    (pdplayer -h (env-alias.js -a $envname) -u $u -p $p -lock 'Lock it!').statuscode
    $playerServices = pdplayer -h (env-alias.js -a $envname) -u $u -p $p -getattributes | ConvertFrom-Json
    Write-Host  (playerServiceToStr $playerServices)
}

function preactivateAccount
{
    Write-Host "PREACTIVating account ... " -NoNewLine
    (pdplayer -h (env-alias.js -a $envname) -u $u -p $p -unlock 'Unlock it!').statuscode
    $playerServices = pdplayer -h (env-alias.js -a $envname) -u $u -p $p -getattributes | ConvertFrom-Json
    Write-Host  (playerServiceToStr $playerServices)
}

if (     $help) {showHelp}
if ( -not($envname) ) {showHelp}
if ( -not($u) ) {showHelp}
if ( -not($p) ) {showHelp}

Write-Host  "Current state ... " -NoNewLine
$playerServices = pdplayer -h (env-alias.js -a $envname) -u $u -p $p -getattributes | ConvertFrom-Json
Write-Host  (playerServiceToStr $playerServices)

if ($playerServices.emailVerified -eq $false)
{ setAccountToActivatedState }
suspendAccount
preactivateAccount