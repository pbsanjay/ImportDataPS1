#script to restore influxdb backup from Kontron server .
#uses importdata.ps1 <backupfilename.zip>
#script compare file date to do a full restore or a incremental restore.
#
param([string] $name = "")
$name 
$stagepath = 'C:\Data\Download\'
$completepath = 'C:\Data\Complete\'
$temppath ='C:\Data\Temp\'
$databasename = 'glances'
$tempdatabase = 'tempglances'
$isfullrestore = $false
$controlfilename = 'last.restore'
$controlfilepath = 'C:\Data\Complete\'
$date =''
$currentfilename=''
$influxcmd ='C:\influxdb-1.6.4\influx'
$influxdcmd ='C:\influxdb-1.6.4\influxd'
$daydatabasestagepath='C:\Data\Archive\'
#$regex = '(?<filedate>\d{4}(?:\.|-|_)?\d{2}(?:\.|-|_)?\d{2})[^0-9]'
$regex =  '(?<filedate>\d{4}(?:\.|-|_)?\d{2}(?:\.|-|_)?\d{2}(?:\.|-|_)?\d{2}(?:\.|-|_)?\d{2}(?:\.|-|_)?\d{2})[^0-9]'
#If we need to do incremental backup all the time , need to set this to true.
$overwritedatecompare = $True
$processdataexe ="C:\Tools\InfluxPP\GetInfluxData.exe"
$flightno=''
#ForEach($name in $names) {
if (-not ([string]::IsNullOrEmpty($name)))
{
    
	Write-Host "Processing file "$name
	$currentfilename =$name
	$file =[IO.Path]::GetFileNameWithoutExtension($name)
	$file
	$a,$b,$c = $file.split('_')
	$flightno=$c
	$y = (get-date).year
	$b =$b -replace '(\.|-|_)',''
	$date="$($y)$($b)"
	$date = [datetime]::ParseExact($date,'yyyyMMddHHmm',[cultureinfo]::InvariantCulture)
	
	$lastrestoredate =''
	$FileExists = Test-Path $controlfilepath$controlfilename
	#if the file exist
	If ($FileExists -eq $True) {
	#check over write configuration.
		if($overwritedatecompare -eq $True){

			$lastrestoredate = get-date (Get-Content -Path $controlfilepath$controlfilename)
			Write-Host "Last restore date time . " $lastrestoredate
			Write-Host "overwrite date compare is set to  " $overwritedatecompare
			$isfullrestore = $False
			Write-Host "Full restore set to false. "
		}else{
			Write-Host "Control file exist. " $controlfilename
			$lastrestoredate = get-date (Get-Content -Path $controlfilepath$controlfilename)
			Write-Host "Last restore date time . " $lastrestoredate
			$isfullrestore = $False
		}
		
	}else{
		#create file with current datetime.
		$lastrestoredate = (get-date $date ).AddDays(-1) 
		$lastrestoredate
		if($overwritedatecompare -eq $True){
			$isfullrestore = $False
			Write-Host "overwrite date compare is set to  " $overwritedatecompare
			Write-Host "Full restore set to false. "
		}else{
			$isfullrestore = $True
			Write-Host "Control file not found. " $controlfilename
			Write-Host "Full restore set to True. "
		}
		 
	}
	$date.Day
	$lastrestoredate.Day
	$date.Month
	$lastrestoredate.Month
	$isfullrestore
		
	if ((($date.Day -eq $lastrestoredate.Day) -and ($date.Month -eq $lastrestoredate.Month) -and ($isfullrestore -eq $False)) -or ($overwritedatecompare -eq $True))
	{	#The current database is restored today.
		#Do a incremental restore.
		Write-Host "Processing incremental restore "
		$isfullrestore = $False
		Remove-Item $temppath*.* -recurse -force
		Write-Host "Cleaning temp working location " $temppath
		#[System.IO.Compression.ZipFile]::ExtractToDirectory($stagepath$currentfilename, $temppath)
		Expand-Archive $stagepath$currentfilename -DestinationPath $temppath
		Write-Host "Extract To Directory " $temppath
		& influx -execute "DROP database $tempdatabase" 
		Write-Host "DROP database $tempdatabase"
		Write-Host "restore database $tempdatabase $temppath "
		& influxd restore -portable -db glances -newdb  $tempdatabase $temppath
		Start-Sleep -s 10
		Write-Host "Importing new data to glances database "
		& influx -database $tempdatabase -execute "SELECT * INTO glances..:MEASUREMENT FROM /.*/ GROUP BY * "
		#Start-Sleep -s 10
		try
		{
			Write-Host "Exporting new data to CSV for Tui "
			C:\Tools\ps1\export2Csv.ps1 $tempdatabase
		 }
		 catch
		{
			Write-Host "Error Exporting CSV : $($_.Exception.Message)"
			
		}
		try
		{
			Write-Host "Processing new data for dashboard "
			& $processdataexe $flightno /run
			#Invoke-Expression "& `"C:\Program Files\Automated QA\TestExecute 8\Bin\TestExecute.exe`" C:\temp\TestProject1\TestProject1.pjs /run /exit /SilentMode"
		 }
		 catch
		{
			Write-Host "Error Processing: $($_.Exception.Message)"
			
		}
		Write-Host "DROP database $tempdatabase"
		Move-Item -Path $stagepath$currentfilename -Destination $completepath$currentfilename
		#& influx -execute "DROP database $tempdatabase" 
	}else{
		#The current database is restored yesterday.
		#Do a fullday influxBackup.
		#Do a full restore.
		Write-Host "Processing full restore "
		$isfullrestore = $True
		Remove-Item $temppath*.* -recurse -force
		Write-Host "Cleaning temp working location " $temppath
		Write-Host "Backing up current glances database to location $daydatabasestagepath " 
		& influxd backup -portable -database glances $temppath #$daydatabasestagepath
		$filename = Get-Date
		$filename = $filename.ToString("yyyy-MM-dd hh-mm-ss")
		 
		Compress-Archive -Path $temppath* -CompressionLevel Fastest -DestinationPath $daydatabasestagepath$filename.zip
		Write-Host "Drop database glances " 
		& influx -execute "drop database glances"
		Remove-Item $temppath*.* -recurse -force
		Write-Host "Extract To Directory " $temppath
		Expand-Archive $stagepath$currentfilename -DestinationPath $temppath
		Write-Host "Restoring new data from $temppath " 
		& influxd restore -portable -db $databasename $temppath
		
		try
		{
			Write-Host "Exporting new data to CSV for Tui "
			C:\Tools\ps1\export2Csv.ps1 $databasename
		 }
		 catch
		{
			Write-Host "Error: $($_.Exception.Message)"
			
		}	
		try
		{
			Write-Host "Processing new data for dashboard "
			& $processdataexe $flightno /run
			#Invoke-Expression "& `"C:\Program Files\Automated QA\TestExecute 8\Bin\TestExecute.exe`" C:\temp\TestProject1\TestProject1.pjs /run /exit /SilentMode"
		 }
		 catch
		{
			Write-Host "Error Processing: $($_.Exception.Message)"
			
		}		
		#Set-Content -Path $controlfilepath$controlfilename -Value get-date -Force
		Set-Content -Path $controlfilepath$controlfilename -Value $date -Force
		Write-Host "Update control file  valus $date @$controlfilepath$controlfilename"
		Move-Item -Path $stagepath$currentfilename -Destination $completepath$currentfilename
	}

}else{
	Write-Host "No backup file name provided for restore."
}
