# file must be saved in UTF16 LE

invoke-expression -Command $PSScriptRoot\..\vars\email.ps1
invoke-expression -Command $PSScriptRoot\..\vars\telegram.ps1

function Global:Send-Email {
    param (
        [string[]]$To,
        [string]$Subject,
        [string]$Body,
        [string[]]$Attachments
    )

    # Загружаем библиотеки MimeKit и MailKit
    # Add-Type -Path "$env:USERPROFILE\.nuget\packages\mimekit\3.4.0\lib\netstandard2.0\MimeKit.dll"
    # Add-Type -Path "$env:USERPROFILE\.nuget\packages\mailkit\3.4.0\lib\netstandard2.0\MailKit.dll"
    $libraries = @(
      "BouncyCastle.Crypto.dll",
      "MailKit.dll",
      "MimeKit.dll",
      "System.Buffers.dll",
      "System.Memory.dll",
      "System.Numerics.Vectors.dll",
      "System.Runtime.CompilerServices.Unsafe.dll",
      "System.Threading.Tasks.Extensions.dll"
    )
    foreach ($lib in $libraries) {
      [Reflection.Assembly]::LoadFile((Resolve-Path "lib\$lib").Path) | out-null
    }

    # Создаем MIME-сообщение
    $message = [MimeKit.MimeMessage]::new()
    $message.From.Add([MimeKit.MailboxAddress]::new($SmtpUser, $SmtpUser))
    foreach ($recipient in $To) {
        $message.To.Add([MimeKit.MailboxAddress]::new($recipient, $recipient))
    }
    $message.Subject = $Subject

    # Создаем тело письма
    $bodyBuilder = [MimeKit.BodyBuilder]::new()
    $bodyBuilder.TextBody = $Body
    $fileStreams = @()
    # Добавляем вложения
    foreach ($attachmentPath in $Attachments) {
        if (Test-Path $attachmentPath) {
            $fileStream = [System.IO.File]::OpenRead($attachmentPath)
            $fileStreams += $fileStream
            $attachment = [MimeKit.MimePart]::new()
            $attachment.Content = [MimeKit.MimeContent]::new($fileStream)
            $attachment.ContentDisposition = [MimeKit.ContentDisposition]::new("attachment")
            $attachment.ContentTransferEncoding = [MimeKit.ContentEncoding]::Base64
            $attachment.FileName = ([System.IO.Path]::GetFileName($attachmentPath)) + ".txt"
            $bodyBuilder.Attachments.Add($attachment)
        } else {
            Write-Warning "File not found: $attachmentPath"
        }
    }

    $message.Body = $bodyBuilder.ToMessageBody()

    # Настраиваем SMTP-клиент
    # $smtpClient = [MailKit.Net.Smtp.SmtpClient]::new([MailKit.ProtocolLogger]::new("d:\temp\smtp.log"))
    $smtpClient = [MailKit.Net.Smtp.SmtpClient]::new()
    try {
        $smtpClient.Connect($SmtpServer, $SmtpPort, $True)
        $smtpClient.Authenticate($SmtpUser, $SmtpPassword)
        $smtpClient.Send($message)
        Write-Host "Message send success"
    } catch {
        Write-Error "Message send error: $_"
    } finally {
        $smtpClient.Disconnect($true)
        $smtpClient.Dispose()
        foreach($fileStream in $fileStreams) {
            $fileStream.Dispose()
        }
    }
}

Function Global:Send-Telegram {
    Param(
        [Parameter(Mandatory=$true)][String]$Message,
        [string[]]$Attachments,
        [bool]$IsError = $false
      )
    if($IsError) {
        $telegramChatId = $telegramChatIdForErrors
    } else {
        $telegramChatId = $telegramChatIdForReports
    }
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($telegramToken)/sendMessage?chat_id=$($telegramChatId)&text=$($Message)"

    if ($null -eq $Attachments -or $Attachments.Length -eq 0) {
      $url = "https://api.telegram.org/bot$($telegramToken)/sendMessage"
      $contentType = "application/x-www-form-urlencoded"
      $Body = @{
        chat_id = $telegramChatId
        text = $Message
        disable_notification = $true
      }
      Invoke-RestMethod -Uri $url -Method Post -Body $Body -ContentType $contentType
    } else {

      $FilePath = $Attachments[0]
      # Build Body for our form-data manually since PS does not support multipart/form-data out of the box
      $LF = "`r`n"
      $boundary = [System.Guid]::NewGuid().ToString()
      # Формируем тело запроса
      $CODEPAGE = "iso-8859-1" # alternatives are ASCII, UTF-8 
      $fileBin = [System.IO.File]::ReadAllBytes($FilePath)
      $enc = [System.Text.Encoding]::GetEncoding($CODEPAGE)
      $fileEnc = $enc.GetString($fileBin)
      $attachmentFileName = ([System.IO.Path]::GetFileName($FilePath))
      $Body = (
        "--$boundary",
          "Content-Disposition: form-data; name=`"chat_id`"",
          "",
          $telegramChatId,
        "--$boundary",
          "Content-Disposition: form-data; name=`"caption`"",
          "",
          $Message,
          "--$boundary",
          "Content-Disposition: form-data; name=`"document`"; filename=`"$attachmentFileName`"",
          "Content-Type: application/octet-stream$LF",
          $fileEnc,
          "--$boundary--$LF"
        )
      $invokeRestMethodSplat = @{
        Uri         = ("https://api.telegram.org/bot{0}/sendDocument" -f $telegramToken)
        Body        = $Body -join $LF
        ErrorAction = 'Stop'
        ContentType = "multipart/form-data; boundary=`"$boundary`""
        Method      = 'Post'
      }
      Invoke-RestMethod @invokeRestMethodSplat | out-null
    }
}

function Global:Send-Report {
      param (
        [string]$Subject,
        [string]$Body,
        [string[]]$Attachments,
        [bool] $IsError
    )
  Send-Email -To @("ltv@gto.by") -Subject $Subject -Body $Body -Attachments $Attachments
  Send-Telegram -Message ($subject + "`r`n`r`n" + $body) -Attachments $Attachments -IsError $IsError
}

# test:
# Send-Report -Subject ("subject " + (get-date).ToString()) -Body ("body " + (get-date).ToString()) -IsError $true -Attachments @("d:\temp\1590.tiff.p7s", "d:\temp\dolg2arm.epf")
