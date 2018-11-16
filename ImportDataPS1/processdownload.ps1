param (
    # Use as base download folder, for -stagedPath parameter.
    $stagedPath = "D:\f\GlancesFTP\"
)
 
$stagedPath = "C:\Data\Download\"
$glancesscriptPath="C:\Tools\ps1\importdata.ps1"
$processDigitechdataexe ="C:\Tools\DigitechPP\DigitechReport.exe"
$glancefilename=""
$completepath = "C:\Data\Complete\"
try
{
	$glancefilename=""
    try
    {
        Get-ChildItem $stagedPath -Filter *.* | Where { ! $_.PSIsContainer }|
		Foreach-Object {
		$fileName = $_.FullName

			 Write-Host "Got FileName:$fileName "
			$outputFile = Split-Path $fileName -leaf
			Write-Host "Got file name : $outputFile"
			if($outputFile -like "glancesdata_*.zip"){
				try
				{
				Write-Host "Calling Glances import with  $($outputFile) "
					C:\Tools\ps1\importdata.ps1 $outputFile
				}
				catch
				{
					Write-Host "Error: $($_.Exception.Message)"
				}		
			}
			
			if($outputFile -like "Digitech_*.log"){
				try
				{
				 Write-Host "Calling Digitech import with  $($outputFile) "
				
				$file =[IO.Path]::GetFileNameWithoutExtension($outputFile)
				$a,$b,$c = $file.split('_')
				
				$flightno=$c
				$flightno
				
				$fpath = "C:\Data\Download\"+$outputFile
				& $processDigitechdataexe $fpath $flightno  /run 
				
				$p1 = $stagedPath+$outputFile
				$p2 = $completepath+$outputFile
				Move-Item -Path $p1 -Destination $p2
				
				}
				catch
				{
					Write-Host "Error: $($_.Exception.Message)"
				}		
			}
		}
    }
    finally
    {
        # Disconnect, clean up
         
		 
  }
  }
 catch
{
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
	 
}
 