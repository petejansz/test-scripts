param
(
    [string]$h = "cadev1",
    [string]$adminHost = "dev",
    [string]$procHost = "pdcore",
    [string]$language,
    [string]$emailFormat,
    [switch]$notify,
    [switch]$doPhone,
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
    Write-Host "USAGE: ${ScriptName} [options] -h <hostname> -adminHost <hostname> -u <username> -p <password> -emailFormat <html|text> -language <en|es>"
    Write-Host "Options:"
    Write-Host "  -procHost default=${procHost}"
    Write-Host "  -port default=hostname:${port}"
    Write-Host "  -quiet"

    exit 1
}
function sendNotifications()
{
    # Write-Host "Sending AccountActivationMail ... " -NoNewLine
    # (pdplayer -h $h -port $port -u $u -p $p -resendActivationMail).StatusCode

    Write-Host "Sending PasswordForgotten ... " -NoNewLine
    (pdplayer -h $h -port $port -forgotpassword $u).StatusCode

    Write-Host "Sending 2x ACCOUNT UPDATED - changed values: Password"
    $results = player-chpwd -hostname $h -port $port -username $u -password $p

    Write-Host "Sending ACCOUNT UPDATED - changed values: Phone number ... " #-NoNewLine
    setPhoneNumber ( Get-Random -min 2000000001 )

    Write-Host "Sending AccountDeactivationMail ... " -NoNewLine
    $foo = pdplayer -h $h -port $port -lock "Lock me out!" -u $u -p $p | ConvertFrom-Json
    Write-Host $foo #.StatusCode

    Write-Host "Unlocking account ... " -NoNewLine
    $foo = pdplayer -h $h -port $port -unlock "Let me in!" -u $u -p $p | ConvertFrom-Json
    Write-Host $foo #.StatusCode

    Write-Host "Sending AdminNotification for ${playerid} ... " -NoNewLine
    pd2-admin --host $adminHost --api mknote --playerid $playerid
    $?

    Write-Host "Sending Winner Notification ... " -NoNewLine
    pd-winner-notification.js -e $u -h $procHost -i $playerid
    $?

    Write-Host "Sending AccountActivationUnverified ... " -NoNewLine
    processes-account.js --hostname $procHost --activate -i $playerid
    $?
}

function getEmailAddress()
{
    $per = (pdplayer -h $h -port $port -u $u -p $p -getPersonalinfo).Content | ConvertFrom-Json
    $per.emails.personal.address
}

function setEmailAddress( [string] $newEmailAddress )
{
    $per = pdplayer -h $h -port $port -u $u -p $p -getPersonalinfo | ConvertFrom-Json
    $per.emails.personal.address = $newEmailAddress
    $per | ConvertTo-Json | Out-File -Encoding UTF8 -Force /tmp/per.json
    $o1 = pdplayer -h $h -port $port -u $u -p $p -updatePersonalinfo /tmp/per.json | ConvertFrom-Json
    $o1.emails.personal.address
}
function getPhoneNumber()
{
    $per = pdplayer -h $h -port $port -u $u -p $p -getPersonalinfo | ConvertFrom-Json
    $per.phones.home.number
}

function setPhoneNumber( [int] $newPhoneNumber )
{
    $per = pdplayer -h $h -port $port -u $u -p $p -getPersonalinfo | ConvertFrom-Json
    $per.phones.home.number = $newPhoneNumber
    $tempFile = New-TemporaryFile
    $per | ConvertTo-Json | Out-File -Encoding UTF8 -Force $tempFile
    sleep 4
    $o1 = pdplayer -h $h -port $port -u $u -p $p -updatePersonalinfo $tempFile #| ConvertFrom-Json
    # $o1.phones.home.number
    rm $tempFile
}

function getEmailFormat()
{
    $commprefs = pdplayer -h $h -port $port -u $u -p $p -getcommprefs | ConvertFrom-Json
    $commprefs.emailFormat
}

function setEmailFormat( [string] $newEmailFormat )
{
    $commprefs = pdplayer -h $h -port $port -u $u -p $p -getcommprefs | ConvertFrom-Json
    $commprefs.emailFormat = $newEmailFormat
    $commprefs | ConvertTo-Json | Out-File -Encoding UTF8 -Force /tmp/comprefs.json
    $o = pdplayer -h $h -port $port -u $u -p $p -updatecommprefs /tmp/comprefs.json | ConvertFrom-Json
    $o.emailFormat
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
    $o = pdplayer -h $h -port $port -u $u -p $p -updateprofile /tmp/pro.json | ConvertFrom-Json
    $o.language
}

if (     $help) {showHelp}
if ( -not($h) ) {showHelp}
if ( -not($adminHost)) {showHelp}
if ( -not($u) ) {showHelp}
if ( -not($p) ) {showHelp}
if ( -not($emailFormat) ) {showHelp}
if ( -not($language) ) {showHelp}

$emailFormat = $emailFormat.ToUpper()
$language = $language.ToUpper()
$playerid = (pdadmin --host $adminHost --api search --email $u | ConvertFrom-Json).playerId
$origEmailFormat = getEmailFormat

if ($origEmailFormat -eq $emailFormat)
{
    Write-Host ("Email format: {0} " -f $origEmailFormat)
}
else
{
    Write-Host ("Updating emailFormat from {0} to setting ${emailFormat} ..." -f $origEmailFormat)
    Write-Host ("Email format now: {0} " -f (setEmailFormat $emailFormat))
}

$origLanguage = getLanguage
if ($origLanguage -eq $language)
{
    Write-Host ("Language: {0} " -f $origLanguage)
}
else
{
    Write-Host ("Updating language from {0} to setting ${language} ..." -f $origLanguage)
    Write-Host ("Language now: {0} " -f (setLanguage $language))
}

if ($notify)
{
    sendNotifications
}

