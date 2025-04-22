invoke-expression -Command $PSScriptRoot\funcs.ps1
invoke-expression -Command $PSScriptRoot\..\vars\mssql-db.ps1

# Текущая дата
$now = Get-Date

foreach ($db in $Global:databases) {
  $cron = getvalue-ordefault $db.cron $Global:dbDefaultCron
  $backupType = getvalue-ordefault $db.type $Global:dbDefaultBackupType
  if (-not (Test-CronSchedule -CronExpression $cron -Date $now)) {
    Write-Host "NOT Making $backupType backup of $($db.db)"
  }
}
