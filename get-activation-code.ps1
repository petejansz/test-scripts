param
(
    [string]$db2host = "cadevdb",
    [string]$db2password = "b2cinst1",
    [string]$db2username = "b2cinst1",
    [int]   $port = 55000,
    [switch]$help,
    [string]$u
)

$ErrorActionPreference = "stop"
Set-StrictMode -Version Latest
$ScriptName = $MyInvocation.MyCommand.Name

function showHelp()
{
    Write-Host "Get PD player activation mail activation code"
    Write-Host "USAGE: ${ScriptName} [options] -u <username> "
    Write-Host "Options:"
    Write-Host "  -db2host default=${db2host}      # Non-dev tunnel: rengw2"
    Write-Host "  -port default=${port}           # Non-dev tunnel: 5150"
    Write-Host "  -db2password default=${db2password} # Non-dev tunnel: gtkinst1"
    Write-Host "  -db2username default=${db2username} # Non-dev tunnel: gtkinst1"

    exit 1
}

if (     $help) { showHelp }
if ( -not($u) ) { showHelp }

$sqlTemplateFile = "$env:Ca/../sql/get-activationmail-activation-code.sql"
$defaultUsername = 'mansir@mailinator.com'
$sql = (Get-Content $sqlTemplateFile) -replace $defaultUsername, $u
$sqlFile = New-TemporaryFile
Set-Content $sqlFile $sql
$obj = use-ibm-db2.js -f $sqlFile.Fullname -h $db2host --port $port -u $db2username --password $db2password | ConvertFrom-Json
if ($obj -and $obj.extra_parameters)
{
    $obj.extra_parameters.split(';') | ForEach-Object { if ($_ -match "^token=") { $_.split('=')[1] } }
}

Remove-Item $sqlFile.Fullname
