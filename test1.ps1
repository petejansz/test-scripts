param
(
    [string]$exfile,
    [string]$sqlfile
)

$i = 0
$nulls2Fix = (Get-Content "C:\Users\pjansz\Documents\Projects\igt\pd\casa-12042\null-level2-accounts.del_prefix")
$list = @()
foreach ($record in $nulls2Fix)
{
    $i++
    $playerId = $record.split(',')[0]
    $list += $playerId
    # $username = $record.split(',')[3]

    # $personalInfo = (pd2-admin --host prod --api personal-info --playerid $playerId | ConvertFrom-Json)
    # Write-Host $i
    # "{0} {1} {2} {3}" -f $playerId, $username, $personalInfo.addresses.country, $personalInfo.addresses.isoCountryCode
}

$list