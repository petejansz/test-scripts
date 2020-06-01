param
(
    [int]    $count=1,
    [int] $oauthSessionLifeSec = 30,
    [int]    $wait = 0,
    [string] $envname,
    [string] $p = "Password1",
    [switch] $help,
    [string] $u,
    [switch] $verbose = $false
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Off #-Trace 2

trap [Exception]
{
    [Console]::Error.WriteLine($_.Exception)
}

$environments = [ordered]@{ }
$environments['apl'] = 'caapl.lotteryservices.com'
$environments['mobile-apl'] = 'mobile-caapl.lotteryservices.com'
$environments['dev'] = 'cadev1'
$environments['mobile-dev'] = 'mobile-cadev1'
$environments['pdc'] = 'cslplayerdirect.calottery.com'
$environments['mobile-pdc'] = 'cslpdmobile.calottery.com'
$environments['cat1'] = 'player.calottery.com'
$environments['mobile-cat1'] = 'mobile-cat.calottery.com'
$environments['cat2'] = 'ca-cat2-pws.lotteryservices.com'
$environments['mobile-cat2'] = 'ca-cat2-mobile.lotteryservices.com'
$environments['sit'] = 'ca-cat2-pws.lotteryservices.com'
$environments['mobile-sit'] = 'ca-cat2-mobile.lotteryservices.com'

$ScriptName = $MyInvocation.MyCommand.Name
function showHelp()
{
    $valid_names = $environments.Keys
    Write-Host "Check PD"
    Write-Host "USAGE: $ScriptName [options] <args>"
    Write-Host "  <args>"
    Write-Host "      -envname $valid_names "
    Write-Host "      -u <username>"
    Write-Host "      -p <password default=${p}>"
    Write-Host "  [options]"
    Write-Host "    -count <number (default=1)> Repeat"
    Write-Host "    -oauthSessionLifeSec <seconds (default=${oauthSessionLifeSec})> When count > 1"
    Write-Host "    -wait  <seconds (default=0)> If count specified, option to wait between calls"

    exit 1
}

function Check-PlayerDirect([string]$hostname, [string]$sessionToken)
{
    Write-Host "Checking $hostname ..." -foregroundcolor "green"

    if ($verbose)
    {
        $d1 = dateToLong (Get-date)
        pd-player-self -h $hostname -o $sessionToken --api attributes --quiet
        $d2 = dateToLong (Get-date)
        $elapsedTime = $d2 - $d1
        Write-Output "elapsed-time: ${elapsedTime} ms"
    }
    else
    {
        pd-player-self -h $hostname -o $sessionToken --api attributes --quiet
    }
}

if ( $help ) { showHelp }
if (-not($envname)) { showHelp }
if (-not($p)) { showHelp }
if (-not($u)) { showHelp }

if (-not ($environments.Contains($envname)))
{
    Write-Host "Not found: $envname"
    Write-host "Valid names: " $environments.Keys
    exit 1
}

$sessionStartTime = dateToLong (Get-Date)
$oauthSessionToken = pd-login.js -h $environments[$envname] -u $u -p $p

for ($i=1; $i -le $count; $i++)
{
    $now = dateToLong (Get-Date)
    $elapsedTime = ($now - $sessionStartTime)

    if ($elapsedTime -gt $oauthSessionLifeSec * 1000)
    {
        $sessionStartTime = dateToLong (Get-Date)
        $oauthSessionToken = pd-login.js -h $environments[$envname] -u $u -p $p
        if ($verbose) { Write-Output "New oauthSessionToken: $oauthSessionToken" }
    }

    Check-PlayerDirect $environments[$envname] $oauthSessionToken

    Start-Sleep -Seconds $wait
}