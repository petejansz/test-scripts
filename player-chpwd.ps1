$ErrorActionPreference = "stop"
Set-StrictMode -Version Latest

$hostname = 'cadev1'
$port = 443
$username = 'test50@yopmail.com'
# pdplayer -hostname player.calottery.com -port 443 -username test50@yopmail.com -chpwd RegTest6100 -newpwd Password123

for ($i=1; $i -le 200; $i++)
{
    $newpwd = $null
    $chpwd = $null

    if ($i % 2)
    {
        $newpwd = "welcome02"
        $chpwd = "welcome01"
    }
    else
    {
        $newpwd = "welcome01"
        $chpwd = "welcome02"
    }

    $theCall = "pdplayer -hostname $hostname -username $username -chpwd $chpwd -newpwd $newpwd"
    "{0}: `t{1}" -f $i, $theCall
    pdplayer -hostname $hostname -username $username -chpwd $chpwd -newpwd $newpwd
}