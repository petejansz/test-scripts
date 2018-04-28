param
(
    [string]    $refhost,
    [string]    $city = 'l%',
    [string]    $firstname = 't%',
    [string]    $lastname = 'lastname',
    [switch]    $help,
    [switch]    $h
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Off #-Trace 2

$ScriptName = $MyInvocation.MyCommand.Name
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path

function showHelp()
{
    Write-Output "USAGE: $ScriptName [options] -refhost <host>"
    Write-Output "Options:"
    Write-Output "  -city        city"
    Write-Output "  -firstname   name"
    Write-Output "  -lastname    name"
    exit 1
}

if ($h -or $help) {showHelp}
if (-not($refhost)) {showHelp}

Set-Location "$env:USERPROFILE\Documents\json\search-players\$refhost"

function fileAndReport($testName, $refJson, $myJSon)
{
    $refJson | Out-File -Encoding utf8 -force "$refhost-$testName.json"
    $myJson  | Out-File -Encoding utf8 -force "my-$testName.json"

    $refCount = ($refJson | ConvertFrom-Json).length
    $myCount = ($myJson   | ConvertFrom-Json).length

    "{0}: DevCount: {1}, MyCount: {2}" -f $testName, $refCount, $myCount

    Compare-Object (Get-Content "$refhost-$testName.json") (Get-Content "my-$testName.json")
}

function testCity()
{
    $refJson = pd2-admin.js --host $refHost --api search   --city $city
    $myJson = pd2-admin.js --host localhost --api search   --city $city
    fileAndReport 'TestCity' $refJson $myJson
}

function testState()
{
    $refJson = pd2-admin.js --host $refHost --api search   --state 'CA'
    $myJson = pd2-admin.js --host localhost --api search   --state 'CA'
    fileAndReport 'TestState' $refJson $myJson
}

function testZipCode()
{
    $refJson = pd2-admin.js --host $refHost --api search   --zipcode '956%'
    $myJson = pd2-admin.js --host localhost --api search   --zipcode '956%'
    fileAndReport 'TestZipCode' $refJson $myJson
}

function testEmail()
{
    $emails = @('%yopmail.com' )
    foreach ($email in $emails)
    {
        $refJson = pd2-admin.js --host $refHost  --api search --email $email
        $myJson = pd2-admin.js --host  localhost --api search --email $email
        fileAndReport "TestEmail [ $email ]" $refJson $myJson
    }
}

function testName()
{
    $refJson = pd2-admin.js --host $refHost --api search --firstname $firstName --lastname $lastName
    $myJson = pd2-admin.js  --host localhost --api search --firstname $firstName --lastname $lastName
    fileAndReport 'TestName' $refJson $myJson
}

testCity
testState
testZipCode
testName
# testEmail
