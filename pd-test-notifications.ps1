param
(
    [string]$h = "cadev1",
    [string]$adminHost = "dev",
    [string]$procHost = "pdcore",
    [string]$language = "EN",
    [string]$emailFormat = "HTML",
    [switch]$notify,
    [int] $port = 80,
    [string]$p = "Password1",
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
    Write-Host "Automate, PD player notifications."
    Write-Host "USAGE: ${ScriptName} [options] -h <hostname> -adminHost <hostname> -u <username> -p <password>"
    Write-Host "Options:"
    Write-Host "  -procHost  default=${procHost}"
    Write-Host "  -hostname default=${hostname}:${port}"
    Write-Host "  -emailFormat default=${emailFormat}"
    Write-Host "  -language default=${language}"
    Write-Host "  -quiet"

    exit 1
}
function sendNotifications()
{
    Write-Host "Sending AccountActivationMail ... " -NoNewLine
    (pdplayer -h $h -port $port -u $u -p $p -resendActivationMail).StatusCode

    Write-Host "Sending PasswordForgotten ... " -NoNewLine
    (pdplayer -h $h -port $port -forgotpassword $u).StatusCode

    Write-Host "Sending 2x ACCOUNT UPDATED - changed values: Password"
    $results = player-chpwd -hostname $h -port $port -username $u -password $p

    Write-Host "Sending AccountDeactivationMail ... " -NoNewLine
    (pdplayer -h $h -port $port -lock "Lock me out!" -u $u -p $p).StatusCode

    Write-Host "Unlocking account ... " -NoNewLine
    (pdplayer -h $h -port $port -unlock "Let me in!" -u $u -p $p).StatusCode

    $playerid = (pd2-admin --host $adminHost --api search --email $u | ConvertFrom-Json).playerId

    Write-Host "Sending AdminNotification for ${playerid} ... " -NoNewLine
    pd2-admin --host $adminHost --api mknote --playerid $playerid
    $?

    Write-Host "Sending Winner Notification ... " -NoNewLine
    pd-winner-notification.js -e $u -h $procHost -i $playerid
    $?

    # Write-Host "Sending AccountActivationUnverified ... " -NoNewLine
    # processes-account.js --hostname $procHost --activate -i $playerid
    # $?
}

function getEmailFormat()
{
    $commprefs = (pdplayer -h $h -port $port -u $u -p $p -getcommprefs).Content | ConvertFrom-Json
    $commprefs.emailFormat
}

function setEmailFormat( [string] $newEmailFormat )
{
    $commprefs = (pdplayer -h $h -port $port -u $u -p $p -getcommprefs).Content | ConvertFrom-Json
    $commprefs.emailFormat = $newEmailFormat
    $commprefs | ConvertTo-Json | Out-File -Encoding UTF8 -Force /tmp/comprefs.json
    (((pdplayer -h $h -port $port -u $u -p $p -updatecommprefs /tmp/comprefs.json).Content)|ConvertFrom-Json).emailFormat
}

function getLanguage()
{
    $profile = (pdplayer -h $h -port $port -u $u -p $p -getprofile).Content | ConvertFrom-Json
    $profile.language
}

function setLanguage( [string] $newLanguage )
{
    $profile = (pdplayer -h $h -port $port -u $u -p $p -getprofile).Content | ConvertFrom-Json
    $profile.language = $newLanguage
    $profile | ConvertTo-Json | Out-File -Encoding UTF8 -Force /tmp/pro.json
    (((pdplayer -h $h -port $port -u $u -p $p -updateprofile /tmp/pro.json).Content)|ConvertFrom-Json).language
}

function getEmailAddress([int] $playerid)
{
    pd2-
}

if (     $help) {showHelp}
if ( -not($h) ) {showHelp}
if ( -not($adminHost)) {showHelp}
if ( -not($u) ) {showHelp}
if ( -not($p) ) {showHelp}

$emailFormat = $emailFormat.ToUpper()
$language = $language.ToUpper()

$initialEmailFormat = getEmailFormat
if ($initialEmailFormat -eq $emailFormat)
{
    Write-Host ("Email format: {0} " -f $initialEmailFormat)
}
else
{
    Write-Host ("Updating emailFormat from {0} to setting ${emailFormat} ..." -f $initialEmailFormat)
    Write-Host ("Email format now: {0} " -f (setEmailFormat $emailFormat))
}

$initialLanguage = getLanguage
if ($initialLanguage -eq $language)
{
    Write-Host ("Language: {0} " -f $initialLanguage)
}
else
{
    Write-Host ("Updating language from {0} to setting ${language} ..." -f $initialLanguage)
    Write-Host ("Language now: {0} " -f (setLanguage $language))
}

if ($notify)
{
    sendNotifications
}

