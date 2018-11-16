#Script to export all measurement from Influxdb to multiple csv file.
param([string] $name = "")
$stagepath = 'C:\Data\Download\'
$completepath = 'C:\Data\Export\'
$temppath ='C:\Data\Export\temp\'
$databasename = 'glances'
$tempdatabase = 'tempglances'
$controlfilepath = 'C:\Data\complete\'
$influxcmd ='C:\influxdb-1.6.4\influx'
$influxdcmd ='C:\influxdb-1.6.4\influxd'
$names = @(
'localhost.cpu',
'localhost.diskio',
'localhost.docker',
'localhost.fs',
'localhost.load',
'localhost.mem',
'localhost.memswap',
'localhost.network',
'localhost.sensors'

)

if (-not ([string]::IsNullOrEmpty($name)))
{
	$databasename = $name
}
Write-Host "Processing CSV export from $databasename "
		
Remove-Item $temppath*.* -recurse -force
Write-Host "Cleaning temp working location " $temppath
#& influx -database $databasename -execute "CLEAR rp"
ForEach($name in $names) {
		
		Write-Host "Exporting $name to " $temppath
		Write-Host "influx  -database $databasename -format csv -execute \"SELECT * FROM \"$name\" "  > $temppath$name.csv"
		$filename =$name.replace('.','_')
		& influx -host localhost -database $databasename -format csv -execute " SELECT * FROM \`"$name\`" " > $temppath$filename.csv
}
Write-Host "CSV export completed"
$filename = Get-Date
$filename = $filename.ToString("yyyy-MM-dd hh-mm-ss")
Write-Host "Compressing all file as " $completepath$filename.zip	 
Compress-Archive -Path $temppath* -CompressionLevel Fastest -DestinationPath $completepath"csv_export_"$filename.zip
Write-Host "Compression completed"