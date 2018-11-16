param
(
    [string]$hostname,
    [int]$playerid,
    [int]$spawncount = 1,
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
    Write-Host "USAGE: ${ScriptName} [options] -hostname <hostname> -playerid <playerid> [-spawncount <n>]"
    Write-Host "Options:"
    Write-Host "  -port <int default=80>"
    exit 1
}

if ($h -or $help) {showHelp}
if ( -not($hostname) ) {showHelp}
if ( -not($playerid) ) {showHelp}

# Define asynchronous job:
$scriptBlock = {param ($hostname, $playerid) pd2-admin.js --host $hostname --api personal-info --playerid $playerid}
$argList = @($hostname, $playerid)
$jobs = @()

# Fork!
for ($i = 1; $i -le $spawncount; $i++)
{
    $jobs += start-job $scriptBlock -ArgumentList $argList
}

# Wait for all jobs, putting all results into $results[]

$results = Get-Job | Wait-Job | Receive-Job
foreach ($result in $results)
{
    try
    {
        $result | Out-Null
    }
    catch
    {
        $_.Exception
    }
}

get-job | remove-job

