$currentPath=Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path;
Import-Module ("{0}\updater-functions.ps1" -f $currentPath);

$hostname = "YOUR HOST";
$password = "YOUT PASSWORD";
$url = "https://dyn.dns.he.net/nic/update?hostname={0}&password={1}" -f $hostname, $password;

$regkey = 'HKCU:\Software\dnsupdater\dns.he.updater';

# get oldip from registry
$oldip = $( (Get-ItemProperty -path $regkey).oldip 2>$null );
if (-not $oldip) { $oldip = "UNKNOWN"; }

Ignore-SLL-Errors;
UseUnsafeHeaderParsing;
$wc = Get-Webclient;

# get newip from checkip.dns.he.net
$regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b";
$htmltext = $wc.DownloadString("http://checkip.dns.he.net");
$myip = $regex.Matches($htmltext) | %{ $_.value; }

# quit if oldip == newip
if ($myip -eq $oldip) { exit 0; }

# if you want to test
#$myip = "1.1.1.1";

$url = "$url&myip=$myip";

# send newip to dyn.dns.he.net; save to registry if successful
$htmlResponse = $wc.DownloadString($url);
echo $htmlResponse;

if ($htmlResponse -Match "good"){
	echo "ip updated";
	
	New-Item -Path $regkey -Type directory -Force;
	Set-ItemProperty -path $regkey -name oldip -value $myip;
	
	echo "script finished";
	
	$date = date;
	$msg = "$date IP changed, old: $oldip actual $myip response: $htmlResponse";
	$msg | Add-Content 'log.txt';
} else { # nochg or badautentication or others msg
	echo "Error updating IP";
	$date = date;
	$msg = "$date Cannot change ip, old: $oldip actual $myip response: $htmlResponse";
	$msg | Add-Content 'log.txt';
}

# uncomment if you want to see the msg in powershell

#echo "my url: $url";
#echo "my actual ip (remote): $myip";
#echo "my old ip (register): $oldip";

Read-Host -Prompt "Press Enter to exit";
