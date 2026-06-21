param(
    [string]$Server = "localhost",
    [string]$DatabaseScript = "..\database\sql-server\autoservice_sqlserver_2017.sql"
)

Write-Host "Импорт базы данных autoservice_db в SQL Server: $Server"
sqlcmd -S $Server -E -i $DatabaseScript
Write-Host "Готово. Проверьте базу autoservice_db в SQL Server Management Studio."
