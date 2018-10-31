param
(
    [string]$hostname = "cadev1",
    [string]$username,
    [string]$password,
    [int]$spawncount = 1,
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
    Write-Host "USAGE: ${ScriptName} [options] -hostname <hostname> -username <name> -password <pwd> [-spawncount <n>]"
    Write-Host "Options:"
    Write-Host "  -port <int default=80>"
    exit 1
}

if ($h -or $help) {showHelp}
if ( -not($hostname) ) {showHelp}
if ( -not($username) ) {showHelp}
if ( -not($password) ) {showHelp}

# Login, get token:
$token = pd-login -h $hostname -u $username -p $password

# Define asynchronous job:
$scriptBlock = {param ($hostname, $port, $token) exercise-players-self-apis.ps1 -hostname $hostname -port $port -token $token}
$argList = @($hostname, $port, $token)
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
    if ($result.StatusCode -ne 200)
    {
        Write-Host $result
    }
}

