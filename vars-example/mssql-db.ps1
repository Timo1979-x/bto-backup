# file must be saved in UTF16 LE

# Глобальный пользователь БД. Используется, если для конкретной БД не указан конкретный пользователь
$Global:dbDefaultUsername='sa'
# Пароль глобального пользователя БД. Используется, если для конкретной БД не указан конкретный пароль
$Global:dbDefaultPassword="global_password"
# Временная папка для складирования РК. В нее записывается РК во время ее создания SQL-сервером. Так сделано, чтобы еще не полностью сделанную РК не начал обрабатывать скрипт сжатия.
$Global:dbTempFolder='\\gtoserv3\backups\_temp'
# папка для складирования РК. В нее перемещается РК после ее создания сервером.
$Global:dbUncompressedFolder='\\gtoserv3\backups\_uncompressed'
# Целевая папка для складирования сжатых (архивированных) РК.
$Global:dbDefaultBackupFolder='\\gtoserv3\backups'
# тип РК по умолчанию (full/diff)
$Global:dbDefaultBackupType = 'full'
# cron-подобное расписание по умолчанию
$Global:dbDefaultCron = '* * * * *'

# Список баз данных для РК. Поля объектов в списке:
# - host - Имя или IP адрес сервера БД. Обязательное.
# - db - Название БД. Обязательное.
# - username - имя пользователя. Необязательное. Если не указать, будет взято глобальное значение.
# - password - пароль пользователя. Необязательное. Если не указать, будет взято глобальное значение.
$Global:databases = @(
    @{host='server_ip1'; db='database_name1'; username='user1'; password='password1'},
    @{host='server_ip2'; db='database_name2'; username='user2'; password='password2'}
)
