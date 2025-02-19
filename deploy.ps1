# Variables
$remoteUser = "admin"
$remoteHost = "dhemasnurjaya.com"
$remoteDir = "/home/admin/apps/dhemasnurjaya_site/public/"
$localDir = "public/"
$keyPath = "X:\Secrets\lightsail-defaultkey-ap-southeast-1.ppk"
$winscpExecutable = "C:\Users\dhemas\AppData\Local\Programs\WinSCP\winscp.com"  # Update this if needed

# Build using production environment
hugo --environment production

# Generate WinSCP commands
$scriptContent = @"
open sftp://$remoteUser@$remoteHost -privatekey=$keyPath
synchronize remote $localDir $remoteDir
exit
"@

# Save the script to a temporary file
$tempScript = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempScript -Value $scriptContent

# Execute the WinSCP command
& $winscpExecutable /script=$tempScript

# Clean up
Remove-Item $tempScript

Write-Host "Deployed to $remoteHost!"
