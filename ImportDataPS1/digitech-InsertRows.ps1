param([string] $filename = "")
$filename
#$filename = "Arinc10"
$date = Get-Date -format "yyyy-MM-dd HH:mm"
$stagepath = 'C:\Data\Download\'
$completepath = 'C:\Data\Complete\'
$flightno =''
# setup vars
$user = 'root'
$pass = 'root'
$database = 'airhubdb'
$MySQLHost = 'localhost'

	$currentfilename =$filename
	$file =[IO.Path]::GetFileNameWithoutExtension($filename)
	$file
	$a,$b,$c = $file.split('_')
	$flightno=$c
	
 startProcess()
 
function ConnectMySQL([string]$user,[string]$pass,[string]$MySQLHost,[string]$database) {
 
  # Load MySQL .NET Connector Objects
  [void][system.reflection.Assembly]::LoadWithPartialName("MySql.Data")
 
  # Open Connection
  $connStr = "server=" + $MySQLHost + ";port=3306;uid=" + $user + ";pwd=" + $pass + ";database="+$database+";Pooling=FALSE"
  $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr)
  $conn.Open()
  $cmd = New-Object MySql.Data.MySqlClient.MySqlCommand("USE $database", $conn)
  return $conn
 
}
 
function WriteMySQLQuery($conn, [string]$query) {
 
  $command = $conn.CreateCommand()
  $command.CommandText = $query
  $RowsInserted = $command.ExecuteNonQuery()
  $command.Dispose()
  if ($RowsInserted) {
    return $RowInserted
  } else {
    return $false
  }
}
function startProcess(){
	# Connect to MySQL Database
	$conn = ConnectMySQL $user $pass $MySQLHost $database
	# Read all the records from table
	$query = "INSERT INTO flightdetails (FlightNumber,FlyDateTime,LandDateTime) VALUES ('$filename','$date','$date')"
	$Rows = WriteMySQLQuery $conn $query
	Write-Host $Rows " inserted into database"
	Move-Item -Path $stagepath$filename -Destination $completepath$filename
}