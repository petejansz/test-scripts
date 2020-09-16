param
(
    [int]    $count = 1,
    [string] $vhost,
    [switch] $help
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Off #-Trace 2

trap [Exception]
{
    [Console]::Error.WriteLine($_.Exception)
}

$ScriptName = $MyInvocation.MyCommand.Name
function showHelp()
{
    Write-Host "Run a JMeter performance load test on APL"
    Write-Host "USAGE: $ScriptName [options] -vhost < mobile | pws >"
    Write-Host "  [options]"
    Write-Host "    -count <number (default=1)> Repeat"

    exit 1
}

if ( $help ) { showHelp }
if (-not($vhost)) { showHelp }

for ($i = 1; $i -le $count; $i++)
{
    $runDate = Get-Date -Format "yyyy-MM-dd-HH-mm"
    Write-Host "Run $i of $count $env:PD_SITE/tools/jmeter/runs/$runDate ..."

    mkdir $env:PD_SITE/tools/jmeter/runs/$runDate | Out-Null
    Set-Location $env:PD_SITE/tools/jmeter/runs/$runDate
    set-jboss-version.ps1 -v 6

    $site = "ca"
    $envname = "apl"

    $jmxFile = "$env:PD_SITE/tools/jmeter/${site}-pd-test.jmx"
    $propertiesFile = "$env:PD_SITE/tools/jmeter/${site}-${envname}-pd-${vhost}-jmeter.properties"

    $logFile = "${site}-${envname}-pd-${vhost}-test-jmeter.log"
    $resultsCsvFile = "${site}-${envname}-pd-${vhost}-test-results-{0}.csv" -f $runDate

    jmeter -n -t $jmxFile -l $resultsCsvFile -p $propertiesFile -j $logFile -e -o output
    jmeter -g $resultsCsvFile -o reports
    & reports/index.html
}