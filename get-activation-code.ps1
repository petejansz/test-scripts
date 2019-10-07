param
(
    [string]$db2host = "cadevdb",
    [string]$db2password = "b2cinst1",
    [string]$db2username = "b2cinst1",
    [int]   $port = 55000,
    [switch]$grepformat,
    [switch]$help,
    [string]$u
)

$ErrorActionPreference = "stop"
Set-StrictMode -Version Latest
$ScriptName = $MyInvocation.MyCommand.Name
$exitCode = 1
function showHelp()
{
    Write-Host "Get PD player activation mail activation code, notification id"
    Write-Host "USAGE: ${ScriptName} [options] -u <username> "
    Write-Host "Options:"
    Write-Host "  -db2host default=${db2host}      # Non-dev tunnel: rengw2"
    Write-Host "  -port default=${port}           # Non-dev tunnel: 5150"
    Write-Host "  -db2password default=${db2password} # Non-dev tunnel: gtkinst1"
    Write-Host "  -db2username default=${db2username} # Non-dev tunnel: gtkinst1"
    Write-Host "  -grepformat   # grep -e {id} -e {code} -e {emailAddress}"

    exit $exitCode
}

function grepFormat( $obj )
{
    $s = "grep -e {0} -e {1} -e {2}" -f $obj.id, $obj.emailAddress, $obj.code
    return $s
}

if (     $help) { showHelp }
if ( -not($u) ) { showHelp }

$sqlTemplateFile = "$env:PD_SITE/../sql/get-activationmail-activation-code.sql"
$defaultUsername = 'mansir@mailinator.com'
$sql = (Get-Content $sqlTemplateFile) -replace $defaultUsername, $u
$sqlFile = New-TemporaryFile
Set-Content $sqlFile $sql
$obj = use-ibm-db2.js -f $sqlFile.Fullname -h $db2host --port $port -u $db2username --password $db2password | ConvertFrom-Json

if ($obj -and $obj.extra_parameters)
{
    $code = $obj.extra_parameters.split(';') | ForEach-Object { if ($_ -match "^token=") { $_.split('=')[1] } }
    $activationCodeObj = @{ 'id' = $obj.plugin_notification_key; 'code' = $code; 'emailAddress' = $u }

    if ($grepformat)
    {
        Write-Output (grepFormat $activationCodeObj)
    }
    else
    {
        Write-Output $activationCodeObj
    }

    $exitCode = 0
}

Remove-Item $sqlFile.Fullname
exit $exitCode