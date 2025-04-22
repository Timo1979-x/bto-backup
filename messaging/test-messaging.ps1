# file must be saved in UTF16 LE

invoke-expression -Command $PSScriptRoot\messaging.ps1

Send-Report -Subject "subject1" -Body "Body1" -IsError $True -Attachments @("d:\backup\messaging\test.ps1", "d:\backup\messaging\messaging.ps1")
