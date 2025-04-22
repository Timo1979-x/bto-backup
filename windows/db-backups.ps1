# file must be saved in UTF16 LE
# runas /savecred /user:maingto\schedulingUser "powershell d:\temp\backup\windows\db-backups-daily.ps1"
 
invoke-expression -Command $PSScriptRoot\..\vars\mssql-db.ps1
invoke-expression -Command $PSScriptRoot\..\messaging\messaging.ps1
invoke-expression -Command $PSScriptRoot\funcs.ps1

$now = Get-Date
foreach ($db in $databases) {
    $cron = getvalue-ordefault $db.cron $Global:dbDefaultCron
    $backupType = getvalue-ordefault $db.type $Global:dbDefaultBackupType
    $password = getvalue-ordefault $db.password $Global:dbDefaultPassword
    $username = getvalue-ordefault $db.username $Global:dbDefaultUsername
    $dbName=$db.db
    if (-not (Test-CronSchedule -CronExpression $cron -Date $now)) {
        continue
    }
    # write-host "${cron}: make $backupType backup of $dbName with user/password: $username/$password"
    Send-Telegram("$dbName ${cron}: starting backup") | Out-Null
    $t1 = Get-Date
    $cleanDbName = $db.db.Replace("[", "").Replace("]", "")
    # mkdir "$dbTempFolder\$cleanDbName"
    New-Item -Force -Path "$dbTempFolder" -Name "$cleanDbName" -ItemType "directory" | Out-Null
#    New-Item -Force -Path "$dbDefaultBackupFolder" -Name "$cleanDbName" -ItemType "directory"
    New-Item -Force -Path "$dbUncompressedFolder" -Name "$cleanDbName" -ItemType "directory" | Out-Null
    $host1=$db.host
    $backupLocation="$dbTempFolder\\$cleanDbName\"
    $command="EXEC sp_BackupDatabases @backupLocation='$backupLocation', @backupType='F', @databaseName='$dbName'"
    sqlcmd -U "$username" -P "$password" -S "$host1" -Q """$command"""
    Move-Item -Path "$backupLocation\*" -Destination "$dbUncompressedFolder\\$cleanDbName\"
    $t2 = Get-Date
    Send-Telegram("$dbName ${cron}: finished backup in time " + ($t2 - $t1).ToString())
    # d:\backup\scripts\rar.exe a -ep -ag-YY-MM-DD_HH-MM-SS -df -m3 -ma5 -md256m -t -rr -s "$dbDefaultBackupFolder\$cleanDbName\$cleanDbName.rar" "$dbTempFolder\$cleanDbName\*"
}

