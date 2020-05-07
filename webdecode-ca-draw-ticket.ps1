param
(
    [string]$caDrawTicket,
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
    Write-Host "USAGE: ${ScriptName} [options] -caDrawTicket <caDrawTicket>"
    Write-Host "Options:"
    exit 1
}

if ($h -or $help -or (-not($caDrawTicket))) {showHelp}

$classPath = "$env:USERPROFILE/Documents/Projects/igt/esa/b2b/branches/cas-b2b_r4_0_dev_br/cas-esa-b2b-translet/target/classes"
# mvn test
java -cp $classPath cas.gtech.translets.WebcodeDecoder $caDrawTicket