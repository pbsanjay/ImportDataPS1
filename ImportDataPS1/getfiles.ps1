param (
    # Use Generate Session URL function to obtain a value for -sessionUrl parameter.
    $sessionUrl = "sftp://<user>:<pass>;fingerprint= =@<ip>",
    $remotePath = "/home/a8user/sftp/sftp/CentralData"
)
 

#$sessionUrl = "sftp://user:mypassword;fingerprint=ssh-rsa-xx-xx-xx@example.com/",
$controlfilename = 'last.files'
$controlfilepath = 'C:\Data\Complete\'
$remortpath = "/home/a8user/sftp/sftp/CentralData/*"
$localpath = "C:\Data\Download\"
$localtemppath="C:\Data\DownloadEnc\"
$RootName = 'SFTPLog '
$LogDate = Get-Date -Format d
$FileName = $RootName + $LogDate + '.log'
#log contents:
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\Data\Logs\$FileName -append

try
{
    # Load WinSCP .NET assembly  
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.ParseUrl($sessionUrl)
 
    $session = New-Object WinSCP.Session
	
	$glancesscriptPath="C:\Tools\ps1\importdata.ps1"
    try
    {
        # Connect
        $session.Open($sessionOptions)
		# clean up temp download location.
		Remove-Item $localtemppath*.* -recurse -force
	    #while ($True)
        #{
            # Collect file list
            $files =
                $session.EnumerateRemoteFiles(
                    $remotePath, "*.*", [WinSCP.EnumerationOptions]::AllDirectories) |
                Select-Object -ExpandProperty FullName
					try
					{
							# Download files
							$transferOptions = New-Object WinSCP.TransferOptions
							$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
							$transferOptions.filemask= "*.*|*.filepart"

							$transferResult =
								$session.GetFiles($remortpath, $localtemppath, $True, $transferOptions)

							# Throw on any error
							$transferResult.Check()
							 # Print results
							 
							foreach ($transfer in $transferResult.Transfers)
							{
								Write-Host "Download of $($transfer.FileName) succeeded"
								$outputFile = Split-Path $transfer.FileName -leaf
								Write-Host "Got file name : $outputFile"
								try{
										Write-Host "Starting file decryption with gpg key"
										gpg --pinentry-mode loopback --batch --yes --passphrase "kontron.uk" --output $localpath$outputFile --decrypt $localtemppath$outputFile
										Write-Host "complete file decryption "$outputFile
									}catch{
										Write-Host "Error: $($_.Exception.Message)"
									}
							}
							Write-Host "File download complete to  : $localtemppath"
					}
					 catch
					{
						Write-Host "Error: $($_.Exception.Message)"
					}
				#Call file processors for process downloaded files.
		C:\Tools\ps1\processdownload.ps1 
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
		Stop-Transcript
  }
  }
 catch
{
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
	Stop-Transcript
}
 