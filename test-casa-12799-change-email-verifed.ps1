# CASA-12799: Change email verifed flag when 2C acct reactivated

param
(
    [string]$envname = "ca-dev-pd",
    [string]$p = "Password1",
    [switch]$current,
    [switch]$activate,
    [switch]$preactivate,
    [switch]$suspend,
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
    Write-Host "USAGE: ${ScriptName} [options] -envname <env-name (default=${envname})> -u <username> [-p <password>] "
    Write-Host "Options:"
    Write-Host "  -activate"
    Write-Host "  -current"
    Write-Host "  -preactivate"
    Write-Host "  -suspend"
    exit 1
}

function serviceState([int] $serviceStatus)
{
    $state = ""
    if     ($serviceStatus -eq 1) {$state = "PRE"}
    elseif ($serviceStatus -eq 2) {$state = "ACT"}
    elseif ($serviceStatus -eq 3) {$state = "SUS"}

    return $state
}
function playerServiceToStr($services)
{
    $str = "playerPortalServiceStatus: {0}, secondChanceServiceStatus: {1}, emailVerified: {2}" -f `
    (serviceState $services.playerPortalServiceStatus), (serviceState $services.secondChanceServiceStatus), $services.emailVerified
    return $str
}

function currentState()
{

    $playerServices = pdplayer -h (env-alias.js -a $envname) -u $u -p $p -getattributes | ConvertFrom-Json
    Write-Host  (playerServiceToStr $playerServices)
}
function activate()
{
    Write-Host "Setting account to verified, activated state ... "  #-NoNewLine
    $adminHost = $envname.split('-')[1]
    $playerid = (pd2-admin --host $adminHost --api search --email $u | ConvertFrom-Json).playerid
    $code = get-activation-code.ps1 -u $u
    pdplayer -h (env-alias.js -a $envname) -u $u -activate $code | Out-Null
    currentState
}

function suspendAccount
{
    Write-Host "Suspending account ... " #-NoNewLine
    (pdplayer -h (env-alias.js -a $envname) -u $u -p $p -lock 'Lock it!').statuscode
    currentState
}

function preactivateAccount
{
    Write-Host "Preactivating account ... "<#
    .SYNOPSIS


    .DESCRIPTION
    Long description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    -NoNewLine
    (pdplayer -h (env-alias.js -a $envname) -u $u -p $p -unlock 'Unlock it!').statuscode
    currentState
}

if (     $help) {showHelp}
if ( -not($envname) ) {showHelp}
if ( -not($u) ) {showHelp}
if ( -not($p) ) {showHelp}

if ($current)       {currentState}
if ($activate)      { activate }
if ($suspend)       {suspendAccount}
if ($preactivate)   {preactivateAccount}
