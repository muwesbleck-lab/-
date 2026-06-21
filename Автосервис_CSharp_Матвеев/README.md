# Информационная система управления автосервисом — C# версия

Автор: Матвеев Александр Алексеевич, группа УБВТ2402.

Это серверная часть программы на C# для проекта учебной практики. Приложение сделано как ASP.NET Core Web API и работает с Microsoft SQL Server 2017.

## Что входит

- `backend/src/Autoservice.Api` — основная программа на C#.
- `backend/tests/Autoservice.Api.Tests` — тесты для части валидации.
- `database/sql-server/autoservice_sqlserver_2017.sql` — база данных SQL Server 2017.
- `scripts/import-database.ps1` — импорт базы через `sqlcmd`.
- `scripts/run-api.ps1` — запуск API.

## Основные функции

- проверка работоспособности API;
- список клиентов;
- создание клиента;
- просмотр клиента по id;
- список автомобилей;
- добавление автомобиля клиенту;
- список заказ-нарядов;
- создание заказ-наряда.

## Требования

- Windows 10/11 или Windows Server;
- Visual Studio 2022;
- .NET 8 SDK;
- SQL Server 2017 или выше;
- SQL Server Management Studio;
- установленная утилита `sqlcmd`, если используется скрипт импорта.

## Как запустить

### 1. Создать базу данных

Откройте SQL Server Management Studio, откройте файл:

```text
 database/sql-server/autoservice_sqlserver_2017.sql
```

и выполните его клавишей `F5`.

Скрипт создаёт базу:

```text
autoservice_db
```

### 2. Настроить подключение

В папке:

```text
backend/src/Autoservice.Api
```

создайте файл `appsettings.Development.json` на основе `appsettings.Development.example.json`.

Пример строки подключения:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=autoservice_db;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

### 3. Запустить программу

Через терминал:

```bash
dotnet run --project backend/src/Autoservice.Api/Autoservice.Api.csproj
```

Или через Visual Studio:

1. Открыть `backend/Autoservice.sln`.
2. Выбрать проект `Autoservice.Api`.
3. Запустить `F5`.

### 4. Открыть Swagger

После запуска открыть в браузере:

```text
https://localhost:7137/swagger
```

или адрес, который покажет Visual Studio в консоли запуска.

## Примеры API

Проверка работы:

```http
GET /api/health
```

Получить клиентов:

```http
GET /api/clients
```

Добавить клиента:

```http
POST /api/clients
Content-Type: application/json

{
  "clientType": "INDIVIDUAL",
  "displayName": "Иванов Иван",
  "firstName": "Иван",
  "lastName": "Иванов",
  "middleName": "Иванович",
  "phone": "+79990000000",
  "email": "ivanov@example.ru",
  "preferredChannel": "PHONE"
}
```

Создать заказ-наряд:

```http
POST /api/work-orders
Content-Type: application/json

{
  "clientId": 1,
  "vehicleId": 1,
  "serviceBayId": 1,
  "advisorUserId": 2,
  "openedByUserId": 2,
  "plannedStartAt": "2026-06-25T10:00:00",
  "plannedEndAt": "2026-06-25T12:00:00",
  "mileageKm": 85000,
  "complaint": "Плановое техническое обслуживание"
}
```

## Примечание

Это учебная версия программы. В ней реализована основная серверная логика, достаточная для демонстрации проекта: клиенты, автомобили, заказ-наряды и подключение к базе данных.
