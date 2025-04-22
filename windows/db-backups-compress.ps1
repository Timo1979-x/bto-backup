# file must be saved in UTF16 LE
# runas /savecred /user:maingto\schedulingUser "powershell d:\temp\backup\windows\compress-backups.ps1"

invoke-expression -Command $PSScriptRoot\..\vars\mssql-db.ps1
invoke-expression -Command $PSScriptRoot\..\messaging\messaging.ps1
invoke-expression -Command $PSScriptRoot\funcs.ps1

$backupFolder = $Global:dbDefaultBackupFolder
$uncompressedFolder = $Global:dbUncompressedFolder
$backups = Get-ChildItem -Path "$uncompressedFolder\*.bak" -Recurse

foreach ($backup in $backups) {
  $fileName = $backup.Name
  $fullName = $backup.FullName
  $pathComponents = $backup.DirectoryName -Split '\\'
  $dbName = $pathComponents[$pathComponents.length - 1]

  Send-Telegram("${fullName}: compress started")
  $t1 = Get-Date
  New-Item -Path "$backupFolder\$dbName" -ItemType Directory
  d:\backup\scripts\rar.exe a -ep -ag-YY-MM-DD_HH-MM-SS -df -m3 -ma5 -md256m -mt24 -t -rr -s "$backupFolder\$dbName\$fileName.rar" "$fullName"
  $t2 = Get-Date
  Send-Telegram("${fullName}: compress finished in time " + ($t2 - $t1).ToString())
}