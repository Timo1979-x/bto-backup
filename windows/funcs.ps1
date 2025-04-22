# file must be saved in UTF16 LE

# Эмуляция ternary operator
function Global:getvalue-ordefault {
  param($value, $default)
  if ($null -eq $value) { return $default }
  return $value
}

# Функция для проверки cron-подобных условий (* * * * *) (minute hour dayOfMonth month dayOfWeek)
# первые два поля (минуты, часы) - не проверяются, но должны присутствовать
function Global:Test-CronSchedule {
  param(
    [string]$CronExpression,
    [datetime]$Date = (Get-Date)
  )

  $parts = ($CronExpression.Trim()) -split '\s+'

  if ($parts.Count -ne 5) {
    throw "Invalid cron expression. Expected 5 parts, got $($parts.Count)"
  }

  $minute, $hour, $dayOfMonth, $month, $dayOfWeek = $parts
  
  # write-host "minute = $minute | hour = $hour | dayOfMonth = $dayOfMonth | month = $month | dayOfWeek = $dayOfWeek"
  # # Проверка минут (пока не используем, но оставляем для совместимости)
  # if ($minute -ne '*' -and $Date.Minute -notin ($minute -split ',')) {
  #   return $false
  # }

  # # Проверка часов (пока не используем)
  # if ($hour -ne '*' -and $Date.Hour -notin ($hour -split ',')) {
  #   return $false
  # }

  # Проверка дня месяца
  if ($dayOfMonth -ne '*' -and $Date.Day -notin ($dayOfMonth -split ',')) {
    return $false
  }

  # Проверка месяца
  if ($month -ne '*' -and $Date.Month -notin ($month -split ',')) {
    return $false
  }

  # Проверка дня недели (0-6, где 0 - воскресенье)
  if ($dayOfWeek -ne '*' -and [int]$Date.DayOfWeek -notin ($dayOfWeek -split ',')) {
    return $false
  }

  return $true
}