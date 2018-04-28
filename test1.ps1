param
(
    [string]$exfile,
    [string]$sqlfile
)

. lib-general.ps1

$s1 = "C0 E1 C EE 40 0 1 23 0 C6 18 99 5 0 CC 67 2 C 84 28 0 0 0 0 0 0 0 88 A6 2C BC 29 32 1 4 BB 90 1 40 A5 2C 5 3 D1 E9 0"
foreach ($v in ($s1.split()))
{
    $dec = hex2Dec $v
    $hex = convert2hex $v
    Write-Host ("{0}  {1}" -f $hex, $dec)
}
