# Серверная часть

Backend создан на ASP.NET Core Web API. Для работы с SQL Server используется Dapper.

В стартовой версии реализованы операции просмотра и создания:

- клиентов;
- автомобилей;
- заказ-нарядов.

## Запуск

```bash
dotnet restore Autoservice.sln
dotnet run --project src/Autoservice.Api
```

Перед запуском необходимо создать `src/Autoservice.Api/appsettings.Development.json` на основе файла-примера и указать строку подключения.

## Тесты

```bash
dotnet test Autoservice.sln
```

В текущей версии нет полноценной аутентификации. Она указана в плане дальнейшего развития проекта.
