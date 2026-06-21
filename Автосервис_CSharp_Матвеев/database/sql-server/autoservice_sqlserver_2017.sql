-- ============================================================================
-- Информационная система управления автосервисом
-- Полная схема для Microsoft SQL Server 2017 (14.x), compatibility level 140
-- Автор комплекта: Матвеев Александр Алексеевич, УБВТ2402
--
-- ВНИМАНИЕ: скрипт полностью пересоздает базу [autoservice_db].
-- Запускайте весь файл в SQL Server Management Studio (SSMS), а не отдельный фрагмент.
-- ============================================================================

USE [master];
GO

IF DB_ID(N'autoservice_db') IS NOT NULL
BEGIN
    ALTER DATABASE [autoservice_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [autoservice_db];
END;
GO

CREATE DATABASE [autoservice_db] COLLATE Cyrillic_General_100_CI_AS;
GO

ALTER DATABASE [autoservice_db] SET COMPATIBILITY_LEVEL = 140;
GO

USE [autoservice_db];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

-- 1. Таблица [Users]
CREATE TABLE [dbo].[Users] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [email] NVARCHAR(254) NOT NULL,
    [employee_code] NVARCHAR(50) NULL,
    [first_name] NVARCHAR(100) NOT NULL,
    [last_name] NVARCHAR(100) NOT NULL,
    [middle_name] NVARCHAR(100) NULL,
    [phone] NVARCHAR(32) NULL,
    [password_hash] NVARCHAR(500) NOT NULL,
    [is_active] BIT NOT NULL DEFAULT (1),
    [must_change_password] BIT NOT NULL DEFAULT (1),
    [last_login_at] DATETIME2(6) NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_users_email] UNIQUE ([email]),
    CONSTRAINT [ck_users_email] CHECK ([email] LIKE N'%_@_%._%')
);
GO
CREATE UNIQUE INDEX [uq_users_employee_code] ON [dbo].[Users] ([employee_code]) WHERE [employee_code] IS NOT NULL;
GO
CREATE INDEX [ix_users_name] ON [dbo].[Users] ([last_name], [first_name]);
GO

-- 2. Таблица [Roles]
CREATE TABLE [dbo].[Roles] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [code] NVARCHAR(80) NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [description] NVARCHAR(500) NULL,
    [is_system] BIT NOT NULL DEFAULT (0),
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_roles_code] UNIQUE ([code])
);
GO

-- 3. Таблица [Permissions]
CREATE TABLE [dbo].[Permissions] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [code] NVARCHAR(120) NOT NULL,
    [name] NVARCHAR(180) NOT NULL,
    [description] NVARCHAR(500) NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_permissions_code] UNIQUE ([code])
);
GO

-- 4. Таблица [UserRoles]
CREATE TABLE [dbo].[UserRoles] (
    [user_id] BIGINT NOT NULL,
    [role_id] BIGINT NOT NULL,
    [assigned_by_user_id] BIGINT NULL,
    [assigned_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([user_id], [role_id]),
    CONSTRAINT [fk_userroles_user] FOREIGN KEY ([user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [fk_userroles_role] FOREIGN KEY ([role_id]) REFERENCES [dbo].[Roles] ([id]),
    CONSTRAINT [fk_userroles_assigned_by] FOREIGN KEY ([assigned_by_user_id]) REFERENCES [dbo].[Users] ([id])
);
GO
CREATE INDEX [ix_userroles_role] ON [dbo].[UserRoles] ([role_id]);
GO

-- 5. Таблица [RolePermissions]
CREATE TABLE [dbo].[RolePermissions] (
    [role_id] BIGINT NOT NULL,
    [permission_id] BIGINT NOT NULL,
    [assigned_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([role_id], [permission_id]),
    CONSTRAINT [fk_rolepermissions_role] FOREIGN KEY ([role_id]) REFERENCES [dbo].[Roles] ([id]),
    CONSTRAINT [fk_rolepermissions_permission] FOREIGN KEY ([permission_id]) REFERENCES [dbo].[Permissions] ([id])
);
GO
CREATE INDEX [ix_rolepermissions_permission] ON [dbo].[RolePermissions] ([permission_id]);
GO

-- 6. Таблица [RefreshTokens]
CREATE TABLE [dbo].[RefreshTokens] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [user_id] BIGINT NOT NULL,
    [token_hash] NCHAR(64) NOT NULL,
    [device_name] NVARCHAR(200) NULL,
    [ip_address] NVARCHAR(45) NULL,
    [expires_at] DATETIME2(6) NOT NULL,
    [revoked_at] DATETIME2(6) NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_refreshtokens_hash] UNIQUE ([token_hash]),
    CONSTRAINT [fk_refreshtokens_user] FOREIGN KEY ([user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_refreshtokens_dates] CHECK ([expires_at] > [created_at])
);
GO
CREATE INDEX [ix_refreshtokens_user_expires] ON [dbo].[RefreshTokens] ([user_id], [expires_at]);
GO

-- 7. Таблица [AuditEvents]
CREATE TABLE [dbo].[AuditEvents] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [user_id] BIGINT NULL,
    [event_type] NVARCHAR(100) NOT NULL,
    [entity_type] NVARCHAR(100) NULL,
    [entity_id] NVARCHAR(100) NULL,
    [ip_address] NVARCHAR(45) NULL,
    [user_agent] NVARCHAR(500) NULL,
    [correlation_id] NCHAR(36) NULL,
    [payload_json] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_auditevents_user] FOREIGN KEY ([user_id]) REFERENCES [dbo].[Users] ([id])
);
GO
ALTER TABLE [dbo].[AuditEvents] ADD CONSTRAINT [CK_AuditEvents_payload_json_IsJson] CHECK ([payload_json] IS NULL OR ISJSON([payload_json]) = 1);
GO
CREATE INDEX [ix_auditevents_user_created] ON [dbo].[AuditEvents] ([user_id], [created_at]);
GO
CREATE INDEX [ix_auditevents_entity] ON [dbo].[AuditEvents] ([entity_type], [entity_id]);
GO
CREATE INDEX [ix_auditevents_correlation] ON [dbo].[AuditEvents] ([correlation_id]);
GO

-- 8. Таблица [Clients]
CREATE TABLE [dbo].[Clients] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [client_type] NVARCHAR(20) NOT NULL DEFAULT (N'INDIVIDUAL'),
    [display_name] NVARCHAR(250) NOT NULL,
    [first_name] NVARCHAR(100) NULL,
    [last_name] NVARCHAR(100) NULL,
    [middle_name] NVARCHAR(100) NULL,
    [company_name] NVARCHAR(250) NULL,
    [tax_id] NVARCHAR(20) NULL,
    [birth_date] DATE NULL,
    [preferred_channel] NVARCHAR(20) NOT NULL DEFAULT (N'PHONE'),
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_by_user_id] BIGINT NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_clients_created_by] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_clients_type] CHECK ([client_type] IN (N'INDIVIDUAL', N'LEGAL')),
    CONSTRAINT [ck_clients_channel] CHECK ([preferred_channel] IN (N'PHONE', N'EMAIL', N'SMS', N'PUSH', N'TELEGRAM'))
);
GO
CREATE UNIQUE INDEX [uq_clients_tax_id] ON [dbo].[Clients] ([tax_id]) WHERE [tax_id] IS NOT NULL;
GO
CREATE INDEX [ix_clients_display_name] ON [dbo].[Clients] ([display_name]);
GO

-- 9. Таблица [ClientContacts]
CREATE TABLE [dbo].[ClientContacts] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [client_id] BIGINT NOT NULL,
    [contact_type] NVARCHAR(20) NOT NULL,
    [contact_value] NVARCHAR(254) NOT NULL,
    [label] NVARCHAR(100) NULL,
    [is_primary] BIT NOT NULL DEFAULT (0),
    [is_verified] BIT NOT NULL DEFAULT (0),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_clientcontacts_client_type_value] UNIQUE ([client_id], [contact_type], [contact_value]),
    CONSTRAINT [fk_clientcontacts_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [ck_clientcontacts_type] CHECK ([contact_type] IN (N'PHONE', N'EMAIL', N'TELEGRAM', N'ADDRESS'))
);
GO
CREATE INDEX [ix_clientcontacts_value] ON [dbo].[ClientContacts] ([contact_value]);
GO

-- 10. Таблица [ClientConsents]
CREATE TABLE [dbo].[ClientConsents] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [client_id] BIGINT NOT NULL,
    [consent_type] NVARCHAR(50) NOT NULL,
    [is_granted] BIT NOT NULL DEFAULT (1),
    [document_version] NVARCHAR(30) NULL,
    [granted_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [revoked_at] DATETIME2(6) NULL,
    [source] NVARCHAR(30) NOT NULL DEFAULT (N'OFFICE'),
    [created_by_user_id] BIGINT NULL,
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_clientconsents_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [fk_clientconsents_user] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_clientconsents_source] CHECK ([source] IN (N'OFFICE', N'WEB', N'MOBILE', N'PHONE')),
    CONSTRAINT [ck_clientconsents_dates] CHECK ([revoked_at] IS NULL OR [revoked_at] >= [granted_at])
);
GO
CREATE INDEX [ix_clientconsents_client_type] ON [dbo].[ClientConsents] ([client_id], [consent_type]);
GO

-- 11. Таблица [ClientNotes]
CREATE TABLE [dbo].[ClientNotes] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [client_id] BIGINT NOT NULL,
    [author_user_id] BIGINT NULL,
    [note_type] NVARCHAR(30) NOT NULL DEFAULT (N'GENERAL'),
    [note_text] NVARCHAR(MAX) NOT NULL,
    [is_private] BIT NOT NULL DEFAULT (0),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_clientnotes_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [fk_clientnotes_author] FOREIGN KEY ([author_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_clientnotes_type] CHECK ([note_type] IN (N'GENERAL', N'CALL', N'COMPLAINT', N'PREFERENCE', N'WARNING'))
);
GO
CREATE INDEX [ix_clientnotes_client_created] ON [dbo].[ClientNotes] ([client_id], [created_at]);
GO

-- 12. Таблица [VehicleMakes]
CREATE TABLE [dbo].[VehicleMakes] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [name] NVARCHAR(120) NOT NULL,
    [country_code] NCHAR(2) NULL,
    [is_active] BIT NOT NULL DEFAULT (1),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_vehiclemakes_name] UNIQUE ([name])
);
GO

-- 13. Таблица [VehicleModels]
CREATE TABLE [dbo].[VehicleModels] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [make_id] BIGINT NOT NULL,
    [name] NVARCHAR(120) NOT NULL,
    [generation] NVARCHAR(100) NULL,
    [production_from] SMALLINT NULL,
    [production_to] SMALLINT NULL,
    [is_active] BIT NOT NULL DEFAULT (1),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_vehiclemodels_make] FOREIGN KEY ([make_id]) REFERENCES [dbo].[VehicleMakes] ([id]),
    CONSTRAINT [ck_vehiclemodels_years] CHECK ([production_to] IS NULL OR [production_from] IS NULL OR [production_to] >= [production_from])
);
GO
CREATE UNIQUE INDEX [uq_vehiclemodels_make_name_generation] ON [dbo].[VehicleModels] ([make_id], [name], [generation]) WHERE [generation] IS NOT NULL;
GO

-- 14. Таблица [Vehicles]
CREATE TABLE [dbo].[Vehicles] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [model_id] BIGINT NOT NULL,
    [vin] NCHAR(17) NULL,
    [registration_number] NVARCHAR(20) NULL,
    [model_year] SMALLINT NULL,
    [engine_code] NVARCHAR(50) NULL,
    [engine_volume_l] DECIMAL(4,2) NULL,
    [fuel_type] NVARCHAR(20) NULL,
    [transmission_type] NVARCHAR(20) NULL,
    [color] NVARCHAR(60) NULL,
    [current_mileage_km] INT NOT NULL DEFAULT (0),
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_vehicles_model] FOREIGN KEY ([model_id]) REFERENCES [dbo].[VehicleModels] ([id]),
    CONSTRAINT [ck_vehicles_vin_length] CHECK ([vin] IS NULL OR LEN([vin]) = 17),
    CONSTRAINT [ck_vehicles_fuel] CHECK ([fuel_type] IS NULL OR [fuel_type] IN (N'PETROL', N'DIESEL', N'HYBRID', N'ELECTRIC', N'LPG')),
    CONSTRAINT [ck_vehicles_transmission] CHECK ([transmission_type] IS NULL OR [transmission_type] IN (N'MANUAL', N'AUTOMATIC', N'CVT', N'ROBOT'))
);
GO
CREATE UNIQUE INDEX [uq_vehicles_vin] ON [dbo].[Vehicles] ([vin]) WHERE [vin] IS NOT NULL;
GO
CREATE UNIQUE INDEX [uq_vehicles_registration] ON [dbo].[Vehicles] ([registration_number]) WHERE [registration_number] IS NOT NULL;
GO
CREATE INDEX [ix_vehicles_model] ON [dbo].[Vehicles] ([model_id]);
GO

-- 15. Таблица [VehicleOwners]
CREATE TABLE [dbo].[VehicleOwners] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [vehicle_id] BIGINT NOT NULL,
    [client_id] BIGINT NOT NULL,
    [ownership_from] DATE NOT NULL,
    [ownership_to] DATE NULL,
    [is_primary] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_vehicleowners_vehicle] FOREIGN KEY ([vehicle_id]) REFERENCES [dbo].[Vehicles] ([id]),
    CONSTRAINT [fk_vehicleowners_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [ck_vehicleowners_dates] CHECK ([ownership_to] IS NULL OR [ownership_to] >= [ownership_from])
);
GO
CREATE INDEX [ix_vehicleowners_vehicle_dates] ON [dbo].[VehicleOwners] ([vehicle_id], [ownership_from], [ownership_to]);
GO
CREATE INDEX [ix_vehicleowners_client] ON [dbo].[VehicleOwners] ([client_id]);
GO

-- 16. Таблица [MileageReadings]
CREATE TABLE [dbo].[MileageReadings] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [vehicle_id] BIGINT NOT NULL,
    [mileage_km] INT NOT NULL,
    [reading_at] DATETIME2(6) NOT NULL,
    [source] NVARCHAR(30) NOT NULL DEFAULT (N'WORK_ORDER'),
    [work_order_id_external] BIGINT NULL,
    [created_by_user_id] BIGINT NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_mileagereadings_vehicle_date] UNIQUE ([vehicle_id], [reading_at]),
    CONSTRAINT [fk_mileagereadings_vehicle] FOREIGN KEY ([vehicle_id]) REFERENCES [dbo].[Vehicles] ([id]),
    CONSTRAINT [fk_mileagereadings_user] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_mileagereadings_source] CHECK ([source] IN (N'WORK_ORDER', N'CLIENT', N'INSPECTION', N'IMPORT'))
);
GO
CREATE INDEX [ix_mileagereadings_vehicle_mileage] ON [dbo].[MileageReadings] ([vehicle_id], [mileage_km]);
GO

-- 17. Таблица [ServiceBays]
CREATE TABLE [dbo].[ServiceBays] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [code] NVARCHAR(40) NOT NULL,
    [name] NVARCHAR(120) NOT NULL,
    [bay_type] NVARCHAR(30) NOT NULL DEFAULT (N'UNIVERSAL'),
    [capacity] TINYINT NOT NULL DEFAULT (1),
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_servicebays_code] UNIQUE ([code]),
    CONSTRAINT [ck_servicebays_capacity] CHECK ([capacity] > 0)
);
GO

-- 18. Таблица [EmployeeSchedules]
CREATE TABLE [dbo].[EmployeeSchedules] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [user_id] BIGINT NOT NULL,
    [work_date] DATE NOT NULL,
    [start_time] TIME(0) NOT NULL,
    [end_time] TIME(0) NOT NULL,
    [schedule_type] NVARCHAR(20) NOT NULL DEFAULT (N'WORK'),
    [comment] NVARCHAR(500) NULL,
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_employeeschedules_user_date_start] UNIQUE ([user_id], [work_date], [start_time]),
    CONSTRAINT [fk_employeeschedules_user] FOREIGN KEY ([user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_employeeschedules_time] CHECK ([end_time] > [start_time]),
    CONSTRAINT [ck_employeeschedules_type] CHECK ([schedule_type] IN (N'WORK', N'VACATION', N'SICK', N'TRAINING', N'DAY_OFF'))
);
GO
CREATE INDEX [ix_employeeschedules_date] ON [dbo].[EmployeeSchedules] ([work_date], [schedule_type]);
GO

-- 19. Таблица [Appointments]
CREATE TABLE [dbo].[Appointments] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [client_id] BIGINT NOT NULL,
    [vehicle_id] BIGINT NOT NULL,
    [service_bay_id] BIGINT NULL,
    [assigned_user_id] BIGINT NULL,
    [starts_at] DATETIME2(6) NOT NULL,
    [ends_at] DATETIME2(6) NOT NULL,
    [status] NVARCHAR(30) NOT NULL DEFAULT (N'PLANNED'),
    [reason] NVARCHAR(500) NOT NULL,
    [client_comment] NVARCHAR(MAX) NULL,
    [internal_comment] NVARCHAR(MAX) NULL,
    [created_by_user_id] BIGINT NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_appointments_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [fk_appointments_vehicle] FOREIGN KEY ([vehicle_id]) REFERENCES [dbo].[Vehicles] ([id]),
    CONSTRAINT [fk_appointments_bay] FOREIGN KEY ([service_bay_id]) REFERENCES [dbo].[ServiceBays] ([id]),
    CONSTRAINT [fk_appointments_assigned] FOREIGN KEY ([assigned_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [fk_appointments_created_by] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_appointments_dates] CHECK ([ends_at] > [starts_at]),
    CONSTRAINT [ck_appointments_status] CHECK ([status] IN (N'PLANNED', N'CONFIRMED', N'ARRIVED', N'IN_SERVICE', N'COMPLETED', N'CANCELLED', N'NO_SHOW'))
);
GO
CREATE INDEX [ix_appointments_period] ON [dbo].[Appointments] ([starts_at], [ends_at]);
GO
CREATE INDEX [ix_appointments_client] ON [dbo].[Appointments] ([client_id], [starts_at]);
GO
CREATE INDEX [ix_appointments_vehicle] ON [dbo].[Appointments] ([vehicle_id], [starts_at]);
GO
CREATE INDEX [ix_appointments_bay] ON [dbo].[Appointments] ([service_bay_id], [starts_at]);
GO

-- 20. Таблица [ServiceCatalog]
CREATE TABLE [dbo].[ServiceCatalog] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [code] NVARCHAR(50) NOT NULL,
    [name] NVARCHAR(250) NOT NULL,
    [category] NVARCHAR(120) NULL,
    [standard_hours] DECIMAL(6,2) NOT NULL DEFAULT (1.00),
    [base_price] DECIMAL(12,2) NOT NULL DEFAULT (0.00),
    [tax_rate_pct] DECIMAL(5,2) NOT NULL DEFAULT (20.00),
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_servicecatalog_code] UNIQUE ([code]),
    CONSTRAINT [ck_servicecatalog_hours] CHECK ([standard_hours] >= 0),
    CONSTRAINT [ck_servicecatalog_price] CHECK ([base_price] >= 0),
    CONSTRAINT [ck_servicecatalog_tax] CHECK ([tax_rate_pct] BETWEEN 0 AND 100)
);
GO
CREATE INDEX [ix_servicecatalog_name] ON [dbo].[ServiceCatalog] ([name]);
GO

-- 21. Таблица [PriceLists]
CREATE TABLE [dbo].[PriceLists] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [service_catalog_id] BIGINT NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [price] DECIMAL(12,2) NOT NULL,
    [valid_from] DATE NOT NULL,
    [valid_to] DATE NULL,
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_pricelists_service_name_from] UNIQUE ([service_catalog_id], [name], [valid_from]),
    CONSTRAINT [fk_pricelists_service] FOREIGN KEY ([service_catalog_id]) REFERENCES [dbo].[ServiceCatalog] ([id]),
    CONSTRAINT [ck_pricelists_price] CHECK ([price] >= 0),
    CONSTRAINT [ck_pricelists_dates] CHECK ([valid_to] IS NULL OR [valid_to] >= [valid_from])
);
GO
CREATE INDEX [ix_pricelists_validity] ON [dbo].[PriceLists] ([valid_from], [valid_to], [is_active]);
GO

-- 22. Таблица [Discounts]
CREATE TABLE [dbo].[Discounts] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [code] NVARCHAR(50) NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [discount_type] NVARCHAR(20) NOT NULL DEFAULT (N'PERCENT'),
    [value] DECIMAL(12,2) NOT NULL,
    [valid_from] DATETIME2(6) NULL,
    [valid_to] DATETIME2(6) NULL,
    [client_id] BIGINT NULL,
    [minimum_amount] DECIMAL(12,2) NOT NULL DEFAULT (0.00),
    [is_active] BIT NOT NULL DEFAULT (1),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_discounts_code] UNIQUE ([code]),
    CONSTRAINT [fk_discounts_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [ck_discounts_type] CHECK ([discount_type] IN (N'PERCENT', N'FIXED')),
    CONSTRAINT [ck_discounts_value] CHECK ([value] >= 0),
    CONSTRAINT [ck_discounts_minimum] CHECK ([minimum_amount] >= 0),
    CONSTRAINT [ck_discounts_dates] CHECK ([valid_to] IS NULL OR [valid_from] IS NULL OR [valid_to] >= [valid_from])
);
GO
CREATE INDEX [ix_discounts_client] ON [dbo].[Discounts] ([client_id], [is_active]);
GO

-- 23. Таблица [WorkOrders]
CREATE TABLE [dbo].[WorkOrders] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [order_number] NVARCHAR(30) NOT NULL,
    [appointment_id] BIGINT NULL,
    [client_id] BIGINT NOT NULL,
    [vehicle_id] BIGINT NOT NULL,
    [service_bay_id] BIGINT NULL,
    [advisor_user_id] BIGINT NULL,
    [opened_by_user_id] BIGINT NULL,
    [status] NVARCHAR(30) NOT NULL DEFAULT (N'DRAFT'),
    [opened_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [planned_start_at] DATETIME2(6) NULL,
    [planned_end_at] DATETIME2(6) NULL,
    [actual_start_at] DATETIME2(6) NULL,
    [actual_end_at] DATETIME2(6) NULL,
    [mileage_km] INT NULL,
    [complaint] NVARCHAR(MAX) NULL,
    [diagnosis] NVARCHAR(MAX) NULL,
    [recommendations_text] NVARCHAR(MAX) NULL,
    [currency_code] NCHAR(3) NOT NULL DEFAULT (N'RUB'),
    [manual_discount_amount] DECIMAL(12,2) NOT NULL DEFAULT (0.00),
    [closed_at] DATETIME2(6) NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_workorders_number] UNIQUE ([order_number]),
    CONSTRAINT [fk_workorders_appointment] FOREIGN KEY ([appointment_id]) REFERENCES [dbo].[Appointments] ([id]),
    CONSTRAINT [fk_workorders_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [fk_workorders_vehicle] FOREIGN KEY ([vehicle_id]) REFERENCES [dbo].[Vehicles] ([id]),
    CONSTRAINT [fk_workorders_bay] FOREIGN KEY ([service_bay_id]) REFERENCES [dbo].[ServiceBays] ([id]),
    CONSTRAINT [fk_workorders_advisor] FOREIGN KEY ([advisor_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [fk_workorders_opened_by] FOREIGN KEY ([opened_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_workorders_status] CHECK ([status] IN (N'DRAFT', N'AWAITING_APPROVAL', N'APPROVED', N'IN_PROGRESS', N'QUALITY_CHECK', N'READY', N'COMPLETED', N'CANCELLED')),
    CONSTRAINT [ck_workorders_plan_dates] CHECK ([planned_end_at] IS NULL OR [planned_start_at] IS NULL OR [planned_end_at] >= [planned_start_at]),
    CONSTRAINT [ck_workorders_actual_dates] CHECK ([actual_end_at] IS NULL OR [actual_start_at] IS NULL OR [actual_end_at] >= [actual_start_at]),
    CONSTRAINT [ck_workorders_discount] CHECK ([manual_discount_amount] >= 0)
);
GO
CREATE UNIQUE INDEX [uq_workorders_appointment] ON [dbo].[WorkOrders] ([appointment_id]) WHERE [appointment_id] IS NOT NULL;
GO
CREATE INDEX [ix_workorders_status_opened] ON [dbo].[WorkOrders] ([status], [opened_at]);
GO
CREATE INDEX [ix_workorders_client] ON [dbo].[WorkOrders] ([client_id], [opened_at]);
GO
CREATE INDEX [ix_workorders_vehicle] ON [dbo].[WorkOrders] ([vehicle_id], [opened_at]);
GO

-- 24. Таблица [OrderStatusHistory]
CREATE TABLE [dbo].[OrderStatusHistory] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [work_order_id] BIGINT NOT NULL,
    [from_status] NVARCHAR(30) NULL,
    [to_status] NVARCHAR(30) NOT NULL,
    [changed_by_user_id] BIGINT NULL,
    [comment] NVARCHAR(1000) NULL,
    [changed_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_orderstatushistory_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_orderstatushistory_user] FOREIGN KEY ([changed_by_user_id]) REFERENCES [dbo].[Users] ([id])
);
GO
CREATE INDEX [ix_orderstatushistory_order_date] ON [dbo].[OrderStatusHistory] ([work_order_id], [changed_at]);
GO

-- 25. Таблица [OrderJobs]
CREATE TABLE [dbo].[OrderJobs] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [work_order_id] BIGINT NOT NULL,
    [service_catalog_id] BIGINT NOT NULL,
    [price_list_id] BIGINT NULL,
    [description] NVARCHAR(500) NULL,
    [quantity] DECIMAL(10,2) NOT NULL DEFAULT (1.00),
    [unit_price] DECIMAL(12,2) NOT NULL,
    [discount_pct] DECIMAL(5,2) NOT NULL DEFAULT (0.00),
    [status] NVARCHAR(30) NOT NULL DEFAULT (N'PLANNED'),
    [planned_hours] DECIMAL(6,2) NULL,
    [actual_hours] DECIMAL(6,2) NULL,
    [started_at] DATETIME2(6) NULL,
    [completed_at] DATETIME2(6) NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_orderjobs_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_orderjobs_service] FOREIGN KEY ([service_catalog_id]) REFERENCES [dbo].[ServiceCatalog] ([id]),
    CONSTRAINT [fk_orderjobs_pricelist] FOREIGN KEY ([price_list_id]) REFERENCES [dbo].[PriceLists] ([id]),
    CONSTRAINT [ck_orderjobs_quantity] CHECK ([quantity] > 0),
    CONSTRAINT [ck_orderjobs_price] CHECK ([unit_price] >= 0),
    CONSTRAINT [ck_orderjobs_discount] CHECK ([discount_pct] BETWEEN 0 AND 100),
    CONSTRAINT [ck_orderjobs_status] CHECK ([status] IN (N'PLANNED', N'APPROVED', N'IN_PROGRESS', N'PAUSED', N'COMPLETED', N'CANCELLED'))
);
GO
CREATE INDEX [ix_orderjobs_order_status] ON [dbo].[OrderJobs] ([work_order_id], [status]);
GO
CREATE INDEX [ix_orderjobs_service] ON [dbo].[OrderJobs] ([service_catalog_id]);
GO

-- 26. Таблица [JobAssignments]
CREATE TABLE [dbo].[JobAssignments] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [order_job_id] BIGINT NOT NULL,
    [user_id] BIGINT NOT NULL,
    [assigned_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [started_at] DATETIME2(6) NULL,
    [completed_at] DATETIME2(6) NULL,
    [labor_hours] DECIMAL(6,2) NULL,
    [assignment_status] NVARCHAR(20) NOT NULL DEFAULT (N'ASSIGNED'),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_jobassignments_job_user] UNIQUE ([order_job_id], [user_id]),
    CONSTRAINT [fk_jobassignments_job] FOREIGN KEY ([order_job_id]) REFERENCES [dbo].[OrderJobs] ([id]),
    CONSTRAINT [fk_jobassignments_user] FOREIGN KEY ([user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_jobassignments_hours] CHECK ([labor_hours] IS NULL OR [labor_hours] >= 0),
    CONSTRAINT [ck_jobassignments_status] CHECK ([assignment_status] IN (N'ASSIGNED', N'ACCEPTED', N'IN_PROGRESS', N'COMPLETED', N'DECLINED'))
);
GO
CREATE INDEX [ix_jobassignments_user_status] ON [dbo].[JobAssignments] ([user_id], [assignment_status]);
GO

-- 27. Таблица [Approvals]
CREATE TABLE [dbo].[Approvals] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [work_order_id] BIGINT NOT NULL,
    [approval_type] NVARCHAR(30) NOT NULL DEFAULT (N'ESTIMATE'),
    [status] NVARCHAR(20) NOT NULL DEFAULT (N'PENDING'),
    [requested_amount] DECIMAL(12,2) NULL,
    [requested_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [responded_at] DATETIME2(6) NULL,
    [response_channel] NVARCHAR(20) NULL,
    [client_comment] NVARCHAR(MAX) NULL,
    [approved_by_client_id] BIGINT NULL,
    [created_by_user_id] BIGINT NULL,
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_approvals_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_approvals_client] FOREIGN KEY ([approved_by_client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [fk_approvals_user] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_approvals_type] CHECK ([approval_type] IN (N'ESTIMATE', N'ADDITIONAL_WORK', N'PART_REPLACEMENT', N'FINAL_AMOUNT')),
    CONSTRAINT [ck_approvals_status] CHECK ([status] IN (N'PENDING', N'APPROVED', N'REJECTED', N'EXPIRED', N'CANCELLED')),
    CONSTRAINT [ck_approvals_amount] CHECK ([requested_amount] IS NULL OR [requested_amount] >= 0)
);
GO
CREATE INDEX [ix_approvals_order_status] ON [dbo].[Approvals] ([work_order_id], [status]);
GO

-- 28. Таблица [QualityChecks]
CREATE TABLE [dbo].[QualityChecks] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [work_order_id] BIGINT NOT NULL,
    [inspector_user_id] BIGINT NULL,
    [check_type] NVARCHAR(30) NOT NULL DEFAULT (N'FINAL'),
    [result] NVARCHAR(20) NOT NULL,
    [checklist_json] NVARCHAR(MAX) NULL,
    [comment] NVARCHAR(MAX) NULL,
    [checked_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_qualitychecks_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_qualitychecks_user] FOREIGN KEY ([inspector_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_qualitychecks_type] CHECK ([check_type] IN (N'INTERMEDIATE', N'FINAL', N'ROAD_TEST')),
    CONSTRAINT [ck_qualitychecks_result] CHECK ([result] IN (N'PASSED', N'FAILED', N'CONDITIONAL'))
);
GO
ALTER TABLE [dbo].[QualityChecks] ADD CONSTRAINT [CK_QualityChecks_checklist_json_IsJson] CHECK ([checklist_json] IS NULL OR ISJSON([checklist_json]) = 1);
GO
CREATE INDEX [ix_qualitychecks_order_date] ON [dbo].[QualityChecks] ([work_order_id], [checked_at]);
GO

-- 29. Таблица [Attachments]
CREATE TABLE [dbo].[Attachments] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [work_order_id] BIGINT NULL,
    [client_id] BIGINT NULL,
    [vehicle_id] BIGINT NULL,
    [uploaded_by_user_id] BIGINT NULL,
    [file_name] NVARCHAR(255) NOT NULL,
    [content_type] NVARCHAR(150) NOT NULL,
    [storage_key] NVARCHAR(500) NOT NULL,
    [file_size_bytes] BIGINT NOT NULL,
    [sha256] NCHAR(64) NULL,
    [attachment_type] NVARCHAR(30) NOT NULL DEFAULT (N'OTHER'),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_attachments_storage_key] UNIQUE ([storage_key]),
    CONSTRAINT [fk_attachments_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_attachments_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [fk_attachments_vehicle] FOREIGN KEY ([vehicle_id]) REFERENCES [dbo].[Vehicles] ([id]),
    CONSTRAINT [fk_attachments_user] FOREIGN KEY ([uploaded_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_attachments_size] CHECK ([file_size_bytes] > 0),
    CONSTRAINT [ck_attachments_type] CHECK ([attachment_type] IN (N'PHOTO_BEFORE', N'PHOTO_AFTER', N'DOCUMENT', N'INVOICE', N'ACT', N'OTHER')),
    CONSTRAINT [ck_attachments_parent] CHECK ([work_order_id] IS NOT NULL OR [client_id] IS NOT NULL OR [vehicle_id] IS NOT NULL)
);
GO
CREATE INDEX [ix_attachments_order] ON [dbo].[Attachments] ([work_order_id]);
GO

-- 30. Таблица [Suppliers]
CREATE TABLE [dbo].[Suppliers] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [name] NVARCHAR(250) NOT NULL,
    [tax_id] NVARCHAR(20) NULL,
    [phone] NVARCHAR(32) NULL,
    [email] NVARCHAR(254) NULL,
    [address] NVARCHAR(500) NULL,
    [contact_person] NVARCHAR(200) NULL,
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id])
);
GO
CREATE UNIQUE INDEX [uq_suppliers_tax_id] ON [dbo].[Suppliers] ([tax_id]) WHERE [tax_id] IS NOT NULL;
GO
CREATE INDEX [ix_suppliers_name] ON [dbo].[Suppliers] ([name]);
GO

-- 31. Таблица [Parts]
CREATE TABLE [dbo].[Parts] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [sku] NVARCHAR(80) NOT NULL,
    [oem_number] NVARCHAR(100) NULL,
    [name] NVARCHAR(250) NOT NULL,
    [manufacturer] NVARCHAR(150) NULL,
    [unit] NVARCHAR(20) NOT NULL DEFAULT (N'PCS'),
    [purchase_price] DECIMAL(12,2) NOT NULL DEFAULT (0.00),
    [sale_price] DECIMAL(12,2) NOT NULL DEFAULT (0.00),
    [tax_rate_pct] DECIMAL(5,2) NOT NULL DEFAULT (20.00),
    [minimum_stock] DECIMAL(12,3) NOT NULL DEFAULT (0.000),
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_parts_sku] UNIQUE ([sku]),
    CONSTRAINT [ck_parts_prices] CHECK ([purchase_price] >= 0 AND [sale_price] >= 0),
    CONSTRAINT [ck_parts_tax] CHECK ([tax_rate_pct] BETWEEN 0 AND 100),
    CONSTRAINT [ck_parts_minimum] CHECK ([minimum_stock] >= 0)
);
GO
CREATE INDEX [ix_parts_oem] ON [dbo].[Parts] ([oem_number]);
GO
CREATE INDEX [ix_parts_name] ON [dbo].[Parts] ([name]);
GO

-- 32. Таблица [Warehouses]
CREATE TABLE [dbo].[Warehouses] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [code] NVARCHAR(40) NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [address] NVARCHAR(500) NULL,
    [responsible_user_id] BIGINT NULL,
    [is_active] BIT NOT NULL DEFAULT (1),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_warehouses_code] UNIQUE ([code]),
    CONSTRAINT [fk_warehouses_user] FOREIGN KEY ([responsible_user_id]) REFERENCES [dbo].[Users] ([id])
);
GO

-- 33. Таблица [StockItems]
CREATE TABLE [dbo].[StockItems] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [warehouse_id] BIGINT NOT NULL,
    [part_id] BIGINT NOT NULL,
    [quantity_on_hand] DECIMAL(12,3) NOT NULL DEFAULT (0.000),
    [reserved_quantity] DECIMAL(12,3) NOT NULL DEFAULT (0.000),
    [average_cost] DECIMAL(12,2) NOT NULL DEFAULT (0.00),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_stockitems_warehouse_part] UNIQUE ([warehouse_id], [part_id]),
    CONSTRAINT [fk_stockitems_warehouse] FOREIGN KEY ([warehouse_id]) REFERENCES [dbo].[Warehouses] ([id]),
    CONSTRAINT [fk_stockitems_part] FOREIGN KEY ([part_id]) REFERENCES [dbo].[Parts] ([id]),
    CONSTRAINT [ck_stockitems_quantities] CHECK ([quantity_on_hand] >= 0 AND [reserved_quantity] >= 0 AND [reserved_quantity] <= [quantity_on_hand]),
    CONSTRAINT [ck_stockitems_cost] CHECK ([average_cost] >= 0)
);
GO
CREATE INDEX [ix_stockitems_part] ON [dbo].[StockItems] ([part_id]);
GO

-- 34. Таблица [StockMovements]
CREATE TABLE [dbo].[StockMovements] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [stock_item_id] BIGINT NOT NULL,
    [movement_type] NVARCHAR(20) NOT NULL,
    [quantity_delta] DECIMAL(12,3) NOT NULL,
    [unit_cost] DECIMAL(12,2) NULL,
    [work_order_id] BIGINT NULL,
    [supplier_id] BIGINT NULL,
    [document_number] NVARCHAR(100) NULL,
    [comment] NVARCHAR(500) NULL,
    [created_by_user_id] BIGINT NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_stockmovements_item] FOREIGN KEY ([stock_item_id]) REFERENCES [dbo].[StockItems] ([id]),
    CONSTRAINT [fk_stockmovements_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_stockmovements_supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([id]),
    CONSTRAINT [fk_stockmovements_user] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_stockmovements_type] CHECK ([movement_type] IN (N'RECEIPT', N'ISSUE', N'RETURN', N'ADJUSTMENT', N'WRITE_OFF')),
    CONSTRAINT [ck_stockmovements_delta] CHECK ([quantity_delta] <> 0),
    CONSTRAINT [ck_stockmovements_cost] CHECK ([unit_cost] IS NULL OR [unit_cost] >= 0)
);
GO
CREATE INDEX [ix_stockmovements_item_date] ON [dbo].[StockMovements] ([stock_item_id], [created_at]);
GO
CREATE INDEX [ix_stockmovements_order] ON [dbo].[StockMovements] ([work_order_id]);
GO

-- 35. Таблица [Reservations]
CREATE TABLE [dbo].[Reservations] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [stock_item_id] BIGINT NOT NULL,
    [work_order_id] BIGINT NOT NULL,
    [order_job_id] BIGINT NULL,
    [quantity] DECIMAL(12,3) NOT NULL,
    [status] NVARCHAR(20) NOT NULL DEFAULT (N'ACTIVE'),
    [reserved_by_user_id] BIGINT NULL,
    [reserved_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [released_at] DATETIME2(6) NULL,
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_reservations_item] FOREIGN KEY ([stock_item_id]) REFERENCES [dbo].[StockItems] ([id]),
    CONSTRAINT [fk_reservations_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_reservations_job] FOREIGN KEY ([order_job_id]) REFERENCES [dbo].[OrderJobs] ([id]),
    CONSTRAINT [fk_reservations_user] FOREIGN KEY ([reserved_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_reservations_quantity] CHECK ([quantity] > 0),
    CONSTRAINT [ck_reservations_status] CHECK ([status] IN (N'ACTIVE', N'ISSUED', N'RELEASED', N'CANCELLED'))
);
GO
CREATE INDEX [ix_reservations_item_status] ON [dbo].[Reservations] ([stock_item_id], [status]);
GO
CREATE INDEX [ix_reservations_order] ON [dbo].[Reservations] ([work_order_id]);
GO

-- 36. Таблица [PurchaseRequests]
CREATE TABLE [dbo].[PurchaseRequests] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [request_number] NVARCHAR(40) NOT NULL,
    [part_id] BIGINT NOT NULL,
    [warehouse_id] BIGINT NOT NULL,
    [supplier_id] BIGINT NULL,
    [requested_quantity] DECIMAL(12,3) NOT NULL,
    [approved_quantity] DECIMAL(12,3) NULL,
    [expected_unit_cost] DECIMAL(12,2) NULL,
    [status] NVARCHAR(20) NOT NULL DEFAULT (N'DRAFT'),
    [requested_by_user_id] BIGINT NULL,
    [approved_by_user_id] BIGINT NULL,
    [requested_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [approved_at] DATETIME2(6) NULL,
    [expected_at] DATE NULL,
    [comment] NVARCHAR(1000) NULL,
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_purchaserequests_number] UNIQUE ([request_number]),
    CONSTRAINT [fk_purchaserequests_part] FOREIGN KEY ([part_id]) REFERENCES [dbo].[Parts] ([id]),
    CONSTRAINT [fk_purchaserequests_warehouse] FOREIGN KEY ([warehouse_id]) REFERENCES [dbo].[Warehouses] ([id]),
    CONSTRAINT [fk_purchaserequests_supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([id]),
    CONSTRAINT [fk_purchaserequests_requested_by] FOREIGN KEY ([requested_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [fk_purchaserequests_approved_by] FOREIGN KEY ([approved_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_purchaserequests_quantity] CHECK ([requested_quantity] > 0 AND ([approved_quantity] IS NULL OR [approved_quantity] >= 0)),
    CONSTRAINT [ck_purchaserequests_cost] CHECK ([expected_unit_cost] IS NULL OR [expected_unit_cost] >= 0),
    CONSTRAINT [ck_purchaserequests_status] CHECK ([status] IN (N'DRAFT', N'SUBMITTED', N'APPROVED', N'ORDERED', N'PARTIALLY_RECEIVED', N'RECEIVED', N'REJECTED', N'CANCELLED'))
);
GO
CREATE INDEX [ix_purchaserequests_status_date] ON [dbo].[PurchaseRequests] ([status], [requested_at]);
GO

-- 37. Таблица [Payments]
CREATE TABLE [dbo].[Payments] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [work_order_id] BIGINT NOT NULL,
    [payment_number] NVARCHAR(50) NOT NULL,
    [payment_method] NVARCHAR(20) NOT NULL,
    [amount] DECIMAL(12,2) NOT NULL,
    [currency_code] NCHAR(3) NOT NULL DEFAULT (N'RUB'),
    [status] NVARCHAR(20) NOT NULL DEFAULT (N'COMPLETED'),
    [external_reference] NVARCHAR(150) NULL,
    [paid_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [received_by_user_id] BIGINT NULL,
    [comment] NVARCHAR(500) NULL,
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_payments_number] UNIQUE ([payment_number]),
    CONSTRAINT [fk_payments_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_payments_user] FOREIGN KEY ([received_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_payments_amount] CHECK ([amount] > 0),
    CONSTRAINT [ck_payments_method] CHECK ([payment_method] IN (N'CASH', N'CARD', N'BANK_TRANSFER', N'ONLINE')),
    CONSTRAINT [ck_payments_status] CHECK ([status] IN (N'PENDING', N'COMPLETED', N'FAILED', N'CANCELLED'))
);
GO
CREATE INDEX [ix_payments_order_status] ON [dbo].[Payments] ([work_order_id], [status]);
GO

-- 38. Таблица [Refunds]
CREATE TABLE [dbo].[Refunds] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [payment_id] BIGINT NOT NULL,
    [refund_number] NVARCHAR(50) NOT NULL,
    [amount] DECIMAL(12,2) NOT NULL,
    [reason] NVARCHAR(500) NOT NULL,
    [status] NVARCHAR(20) NOT NULL DEFAULT (N'COMPLETED'),
    [external_reference] NVARCHAR(150) NULL,
    [refunded_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [processed_by_user_id] BIGINT NULL,
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_refunds_number] UNIQUE ([refund_number]),
    CONSTRAINT [fk_refunds_payment] FOREIGN KEY ([payment_id]) REFERENCES [dbo].[Payments] ([id]),
    CONSTRAINT [fk_refunds_user] FOREIGN KEY ([processed_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [ck_refunds_amount] CHECK ([amount] > 0),
    CONSTRAINT [ck_refunds_status] CHECK ([status] IN (N'PENDING', N'COMPLETED', N'FAILED', N'CANCELLED'))
);
GO
CREATE INDEX [ix_refunds_payment_status] ON [dbo].[Refunds] ([payment_id], [status]);
GO

-- 39. Таблица [MaintenanceTypes]
CREATE TABLE [dbo].[MaintenanceTypes] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [code] NVARCHAR(50) NOT NULL,
    [name] NVARCHAR(200) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [is_active] BIT NOT NULL DEFAULT (1),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_maintenancetypes_code] UNIQUE ([code])
);
GO

-- 40. Таблица [MaintenanceRules]
CREATE TABLE [dbo].[MaintenanceRules] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [maintenance_type_id] BIGINT NOT NULL,
    [vehicle_model_id] BIGINT NULL,
    [rule_name] NVARCHAR(250) NOT NULL,
    [interval_km] INT NULL,
    [interval_months] SMALLINT NULL,
    [warning_km] INT NOT NULL DEFAULT (1000),
    [warning_days] SMALLINT NOT NULL DEFAULT (30),
    [service_catalog_id] BIGINT NULL,
    [is_active] BIT NOT NULL DEFAULT (1),
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_maintenancerules_type] FOREIGN KEY ([maintenance_type_id]) REFERENCES [dbo].[MaintenanceTypes] ([id]),
    CONSTRAINT [fk_maintenancerules_model] FOREIGN KEY ([vehicle_model_id]) REFERENCES [dbo].[VehicleModels] ([id]),
    CONSTRAINT [fk_maintenancerules_service] FOREIGN KEY ([service_catalog_id]) REFERENCES [dbo].[ServiceCatalog] ([id]),
    CONSTRAINT [ck_maintenancerules_interval] CHECK ([interval_km] IS NOT NULL OR [interval_months] IS NOT NULL),
    CONSTRAINT [ck_maintenancerules_values] CHECK (([interval_km] IS NULL OR [interval_km] > 0) AND ([interval_months] IS NULL OR [interval_months] > 0))
);
GO
CREATE INDEX [ix_maintenancerules_model_type] ON [dbo].[MaintenanceRules] ([vehicle_model_id], [maintenance_type_id]);
GO

-- 41. Таблица [MaintenanceSchedules]
CREATE TABLE [dbo].[MaintenanceSchedules] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [vehicle_id] BIGINT NOT NULL,
    [maintenance_rule_id] BIGINT NOT NULL,
    [last_service_date] DATE NULL,
    [last_service_mileage_km] INT NULL,
    [next_due_date] DATE NULL,
    [next_due_mileage_km] INT NULL,
    [status] NVARCHAR(20) NOT NULL DEFAULT (N'PLANNED'),
    [source_work_order_id] BIGINT NULL,
    [updated_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_maintenanceschedules_vehicle_rule] UNIQUE ([vehicle_id], [maintenance_rule_id]),
    CONSTRAINT [fk_maintenanceschedules_vehicle] FOREIGN KEY ([vehicle_id]) REFERENCES [dbo].[Vehicles] ([id]),
    CONSTRAINT [fk_maintenanceschedules_rule] FOREIGN KEY ([maintenance_rule_id]) REFERENCES [dbo].[MaintenanceRules] ([id]),
    CONSTRAINT [fk_maintenanceschedules_order] FOREIGN KEY ([source_work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [ck_maintenanceschedules_status] CHECK ([status] IN (N'PLANNED', N'DUE_SOON', N'OVERDUE', N'COMPLETED', N'SKIPPED'))
);
GO
CREATE INDEX [ix_maintenanceschedules_due_date] ON [dbo].[MaintenanceSchedules] ([status], [next_due_date]);
GO
CREATE INDEX [ix_maintenanceschedules_due_mileage] ON [dbo].[MaintenanceSchedules] ([status], [next_due_mileage_km]);
GO

-- 42. Таблица [Recommendations]
CREATE TABLE [dbo].[Recommendations] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [vehicle_id] BIGINT NOT NULL,
    [work_order_id] BIGINT NULL,
    [maintenance_schedule_id] BIGINT NULL,
    [title] NVARCHAR(250) NOT NULL,
    [description] NVARCHAR(MAX) NOT NULL,
    [priority] NVARCHAR(20) NOT NULL DEFAULT (N'MEDIUM'),
    [status] NVARCHAR(20) NOT NULL DEFAULT (N'OPEN'),
    [recommended_by_user_id] BIGINT NULL,
    [recommended_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [due_date] DATE NULL,
    [due_mileage_km] INT NULL,
    [resolved_work_order_id] BIGINT NULL,
    [resolved_at] DATETIME2(6) NULL,
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_recommendations_vehicle] FOREIGN KEY ([vehicle_id]) REFERENCES [dbo].[Vehicles] ([id]),
    CONSTRAINT [fk_recommendations_order] FOREIGN KEY ([work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [fk_recommendations_schedule] FOREIGN KEY ([maintenance_schedule_id]) REFERENCES [dbo].[MaintenanceSchedules] ([id]),
    CONSTRAINT [fk_recommendations_user] FOREIGN KEY ([recommended_by_user_id]) REFERENCES [dbo].[Users] ([id]),
    CONSTRAINT [fk_recommendations_resolved_order] FOREIGN KEY ([resolved_work_order_id]) REFERENCES [dbo].[WorkOrders] ([id]),
    CONSTRAINT [ck_recommendations_priority] CHECK ([priority] IN (N'LOW', N'MEDIUM', N'HIGH', N'CRITICAL')),
    CONSTRAINT [ck_recommendations_status] CHECK ([status] IN (N'OPEN', N'ACCEPTED', N'DECLINED', N'COMPLETED', N'EXPIRED'))
);
GO
CREATE INDEX [ix_recommendations_vehicle_status] ON [dbo].[Recommendations] ([vehicle_id], [status]);
GO
CREATE INDEX [ix_recommendations_due] ON [dbo].[Recommendations] ([status], [due_date], [due_mileage_km]);
GO

-- 43. Таблица [Notifications]
CREATE TABLE [dbo].[Notifications] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [client_id] BIGINT NOT NULL,
    [recommendation_id] BIGINT NULL,
    [maintenance_schedule_id] BIGINT NULL,
    [channel] NVARCHAR(20) NOT NULL,
    [recipient] NVARCHAR(254) NOT NULL,
    [subject] NVARCHAR(250) NULL,
    [body] NVARCHAR(MAX) NOT NULL,
    [status] NVARCHAR(20) NOT NULL DEFAULT (N'PENDING'),
    [scheduled_at] DATETIME2(6) NOT NULL,
    [sent_at] DATETIME2(6) NULL,
    [created_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [fk_notifications_client] FOREIGN KEY ([client_id]) REFERENCES [dbo].[Clients] ([id]),
    CONSTRAINT [fk_notifications_recommendation] FOREIGN KEY ([recommendation_id]) REFERENCES [dbo].[Recommendations] ([id]),
    CONSTRAINT [fk_notifications_schedule] FOREIGN KEY ([maintenance_schedule_id]) REFERENCES [dbo].[MaintenanceSchedules] ([id]),
    CONSTRAINT [ck_notifications_channel] CHECK ([channel] IN (N'EMAIL', N'SMS', N'PUSH', N'TELEGRAM')),
    CONSTRAINT [ck_notifications_status] CHECK ([status] IN (N'PENDING', N'PROCESSING', N'SENT', N'FAILED', N'CANCELLED'))
);
GO
CREATE INDEX [ix_notifications_status_schedule] ON [dbo].[Notifications] ([status], [scheduled_at]);
GO
CREATE INDEX [ix_notifications_client] ON [dbo].[Notifications] ([client_id], [created_at]);
GO

-- 44. Таблица [NotificationAttempts]
CREATE TABLE [dbo].[NotificationAttempts] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [notification_id] BIGINT NOT NULL,
    [attempt_number] SMALLINT NOT NULL,
    [provider] NVARCHAR(80) NULL,
    [status] NVARCHAR(20) NOT NULL,
    [provider_message_id] NVARCHAR(150) NULL,
    [error_code] NVARCHAR(100) NULL,
    [error_message] NVARCHAR(1000) NULL,
    [attempted_at] DATETIME2(6) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PRIMARY KEY ([id]),
    CONSTRAINT [uq_notificationattempts_notification_number] UNIQUE ([notification_id], [attempt_number]),
    CONSTRAINT [fk_notificationattempts_notification] FOREIGN KEY ([notification_id]) REFERENCES [dbo].[Notifications] ([id]),
    CONSTRAINT [ck_notificationattempts_number] CHECK ([attempt_number] > 0),
    CONSTRAINT [ck_notificationattempts_status] CHECK ([status] IN (N'SENT', N'FAILED', N'TIMEOUT'))
);
GO

-- ============================================================================
-- ТРИГГЕРЫ СКЛАДСКОГО УЧЕТА
-- В SQL Server триггеры работают на набор строк, поэтому используются inserted/deleted.
-- Каждый CREATE TRIGGER находится в отдельном пакете GO.
-- ============================================================================

CREATE TRIGGER [dbo].[trg_stockmovements_insert]
ON [dbo].[StockMovements]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT [stock_item_id], SUM([quantity_delta]) AS [delta_total]
            FROM inserted
            GROUP BY [stock_item_id]
        ) mt
        JOIN [dbo].[StockItems] si WITH (UPDLOCK, HOLDLOCK)
          ON si.[id] = mt.[stock_item_id]
        WHERE si.[quantity_on_hand] + mt.[delta_total] < 0
    )
        THROW 50001, N'Недостаточно фактического остатка для складского движения', 1;

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT [stock_item_id], SUM([quantity_delta]) AS [delta_total]
            FROM inserted
            GROUP BY [stock_item_id]
        ) mt
        JOIN [dbo].[StockItems] si WITH (UPDLOCK, HOLDLOCK)
          ON si.[id] = mt.[stock_item_id]
        WHERE si.[quantity_on_hand] + mt.[delta_total] < si.[reserved_quantity]
    )
        THROW 50002, N'После движения остаток станет меньше зарезервированного количества', 1;

    ;WITH MovementTotals AS (
        SELECT
            [stock_item_id],
            SUM([quantity_delta]) AS [delta_total],
            SUM(CASE WHEN [quantity_delta] > 0 AND [unit_cost] IS NOT NULL
                     THEN [quantity_delta] ELSE 0 END) AS [receipt_qty],
            SUM(CASE WHEN [quantity_delta] > 0 AND [unit_cost] IS NOT NULL
                     THEN [quantity_delta] * [unit_cost] ELSE 0 END) AS [receipt_value]
        FROM inserted
        GROUP BY [stock_item_id]
    )
    UPDATE si
       SET si.[average_cost] = CASE
            WHEN mt.[receipt_qty] > 0
              THEN ((si.[quantity_on_hand] * si.[average_cost]) + mt.[receipt_value])
                   / NULLIF(si.[quantity_on_hand] + mt.[receipt_qty], 0)
            ELSE si.[average_cost]
           END,
           si.[quantity_on_hand] = si.[quantity_on_hand] + mt.[delta_total]
    FROM [dbo].[StockItems] si
    JOIN MovementTotals mt ON mt.[stock_item_id] = si.[id];
END;
GO

CREATE TRIGGER [dbo].[trg_reservations_insert]
ON [dbo].[Reservations]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT [stock_item_id], SUM([quantity]) AS [qty]
            FROM inserted
            WHERE [status] = N'ACTIVE'
            GROUP BY [stock_item_id]
        ) r
        JOIN [dbo].[StockItems] si WITH (UPDLOCK, HOLDLOCK)
          ON si.[id] = r.[stock_item_id]
        WHERE si.[quantity_on_hand] - si.[reserved_quantity] < r.[qty]
    )
        THROW 50003, N'Недостаточно свободного остатка для резервирования', 1;

    ;WITH Requested AS (
        SELECT [stock_item_id], SUM([quantity]) AS [qty]
        FROM inserted
        WHERE [status] = N'ACTIVE'
        GROUP BY [stock_item_id]
    )
    UPDATE si
       SET si.[reserved_quantity] = si.[reserved_quantity] + r.[qty]
    FROM [dbo].[StockItems] si
    JOIN Requested r ON r.[stock_item_id] = si.[id];
END;
GO

CREATE TRIGGER [dbo].[trg_reservations_update]
ON [dbo].[Reservations]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT [stock_item_id], SUM([qty_change]) AS [qty_change]
            FROM (
                SELECT [stock_item_id],
                       CASE WHEN [status] = N'ACTIVE' THEN -[quantity] ELSE 0 END AS [qty_change]
                FROM deleted
                UNION ALL
                SELECT [stock_item_id],
                       CASE WHEN [status] = N'ACTIVE' THEN [quantity] ELSE 0 END AS [qty_change]
                FROM inserted
            ) x
            GROUP BY [stock_item_id]
        ) c
        JOIN [dbo].[StockItems] si WITH (UPDLOCK, HOLDLOCK)
          ON si.[id] = c.[stock_item_id]
        WHERE si.[reserved_quantity] + c.[qty_change] < 0
           OR si.[reserved_quantity] + c.[qty_change] > si.[quantity_on_hand]
    )
        THROW 50004, N'Недостаточно свободного остатка для изменения резерва', 1;

    ;WITH Changes AS (
        SELECT [stock_item_id], SUM([qty_change]) AS [qty_change]
        FROM (
            SELECT [stock_item_id],
                   CASE WHEN [status] = N'ACTIVE' THEN -[quantity] ELSE 0 END AS [qty_change]
            FROM deleted
            UNION ALL
            SELECT [stock_item_id],
                   CASE WHEN [status] = N'ACTIVE' THEN [quantity] ELSE 0 END AS [qty_change]
            FROM inserted
        ) x
        GROUP BY [stock_item_id]
    )
    UPDATE si
       SET si.[reserved_quantity] = si.[reserved_quantity] + c.[qty_change]
    FROM [dbo].[StockItems] si
    JOIN Changes c ON c.[stock_item_id] = si.[id]
    WHERE c.[qty_change] <> 0;
END;
GO

CREATE TRIGGER [dbo].[trg_reservations_delete]
ON [dbo].[Reservations]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Released AS (
        SELECT [stock_item_id], SUM([quantity]) AS [qty]
        FROM deleted
        WHERE [status] = N'ACTIVE'
        GROUP BY [stock_item_id]
    )
    UPDATE si
       SET si.[reserved_quantity] = si.[reserved_quantity] - r.[qty]
    FROM [dbo].[StockItems] si
    JOIN Released r ON r.[stock_item_id] = si.[id];
END;
GO

CREATE TRIGGER [dbo].[trg_workorders_status_history]
ON [dbo].[WorkOrders]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[OrderStatusHistory]
        ([work_order_id], [from_status], [to_status], [changed_by_user_id], [comment])
    SELECT
        i.[id], d.[status], i.[status], i.[advisor_user_id],
        N'Автоматическая запись изменения статуса'
    FROM inserted i
    JOIN deleted d ON d.[id] = i.[id]
    WHERE ISNULL(i.[status], N'') <> ISNULL(d.[status], N'');
END;
GO

-- ============================================================================
-- ПРЕДСТАВЛЕНИЯ
-- ============================================================================

CREATE VIEW [dbo].[v_WorkOrderTotals]
AS
SELECT
    wo.[id] AS [work_order_id],
    wo.[order_number],
    COALESCE(j.[labor_amount], 0.00) AS [labor_amount],
    COALESCE(p.[parts_amount], 0.00) AS [parts_amount],
    wo.[manual_discount_amount],
    CASE
      WHEN COALESCE(j.[labor_amount], 0.00) + COALESCE(p.[parts_amount], 0.00) - wo.[manual_discount_amount] > 0
      THEN COALESCE(j.[labor_amount], 0.00) + COALESCE(p.[parts_amount], 0.00) - wo.[manual_discount_amount]
      ELSE 0.00
    END AS [total_amount],
    COALESCE(pay.[paid_amount], 0.00) - COALESCE(ref.[refunded_amount], 0.00) AS [net_paid_amount],
    CASE
      WHEN COALESCE(j.[labor_amount], 0.00) + COALESCE(p.[parts_amount], 0.00) - wo.[manual_discount_amount]
           - (COALESCE(pay.[paid_amount], 0.00) - COALESCE(ref.[refunded_amount], 0.00)) > 0
      THEN COALESCE(j.[labor_amount], 0.00) + COALESCE(p.[parts_amount], 0.00) - wo.[manual_discount_amount]
           - (COALESCE(pay.[paid_amount], 0.00) - COALESCE(ref.[refunded_amount], 0.00))
      ELSE 0.00
    END AS [balance_due]
FROM [dbo].[WorkOrders] wo
LEFT JOIN (
    SELECT [work_order_id], SUM([quantity] * [unit_price] * (1 - [discount_pct] / 100.0)) AS [labor_amount]
    FROM [dbo].[OrderJobs]
    WHERE [status] <> N'CANCELLED'
    GROUP BY [work_order_id]
) j ON j.[work_order_id] = wo.[id]
LEFT JOIN (
    SELECT r.[work_order_id], SUM(r.[quantity] * pt.[sale_price]) AS [parts_amount]
    FROM [dbo].[Reservations] r
    JOIN [dbo].[StockItems] si ON si.[id] = r.[stock_item_id]
    JOIN [dbo].[Parts] pt ON pt.[id] = si.[part_id]
    WHERE r.[status] IN (N'ACTIVE', N'ISSUED')
    GROUP BY r.[work_order_id]
) p ON p.[work_order_id] = wo.[id]
LEFT JOIN (
    SELECT [work_order_id], SUM([amount]) AS [paid_amount]
    FROM [dbo].[Payments]
    WHERE [status] = N'COMPLETED'
    GROUP BY [work_order_id]
) pay ON pay.[work_order_id] = wo.[id]
LEFT JOIN (
    SELECT py.[work_order_id], SUM(rf.[amount]) AS [refunded_amount]
    FROM [dbo].[Refunds] rf
    JOIN [dbo].[Payments] py ON py.[id] = rf.[payment_id]
    WHERE rf.[status] = N'COMPLETED'
    GROUP BY py.[work_order_id]
) ref ON ref.[work_order_id] = wo.[id];
GO

CREATE VIEW [dbo].[v_LowStock]
AS
SELECT
    si.[id] AS [stock_item_id],
    w.[code] AS [warehouse_code],
    w.[name] AS [warehouse_name],
    p.[sku],
    p.[name] AS [part_name],
    si.[quantity_on_hand],
    si.[reserved_quantity],
    si.[quantity_on_hand] - si.[reserved_quantity] AS [available_quantity],
    p.[minimum_stock]
FROM [dbo].[StockItems] si
JOIN [dbo].[Warehouses] w ON w.[id] = si.[warehouse_id]
JOIN [dbo].[Parts] p ON p.[id] = si.[part_id]
WHERE si.[quantity_on_hand] - si.[reserved_quantity] <= p.[minimum_stock];
GO

CREATE VIEW [dbo].[v_DueMaintenance]
AS
SELECT
    ms.[id] AS [schedule_id],
    ms.[vehicle_id],
    vmk.[name] AS [make_name],
    vmd.[name] AS [model_name],
    v.[registration_number],
    v.[current_mileage_km],
    mt.[name] AS [maintenance_type],
    mr.[rule_name],
    ms.[next_due_date],
    ms.[next_due_mileage_km],
    CASE
      WHEN ms.[next_due_date] IS NOT NULL AND ms.[next_due_date] < CONVERT(date, GETDATE()) THEN N'OVERDUE'
      WHEN ms.[next_due_mileage_km] IS NOT NULL AND ms.[next_due_mileage_km] <= v.[current_mileage_km] THEN N'OVERDUE'
      WHEN ms.[next_due_date] IS NOT NULL AND ms.[next_due_date] <= DATEADD(DAY, mr.[warning_days], CONVERT(date, GETDATE())) THEN N'DUE_SOON'
      WHEN ms.[next_due_mileage_km] IS NOT NULL AND ms.[next_due_mileage_km] <= v.[current_mileage_km] + mr.[warning_km] THEN N'DUE_SOON'
      ELSE N'PLANNED'
    END AS [calculated_status]
FROM [dbo].[MaintenanceSchedules] ms
JOIN [dbo].[Vehicles] v ON v.[id] = ms.[vehicle_id]
JOIN [dbo].[VehicleModels] vmd ON vmd.[id] = v.[model_id]
JOIN [dbo].[VehicleMakes] vmk ON vmk.[id] = vmd.[make_id]
JOIN [dbo].[MaintenanceRules] mr ON mr.[id] = ms.[maintenance_rule_id]
JOIN [dbo].[MaintenanceTypes] mt ON mt.[id] = mr.[maintenance_type_id]
WHERE ms.[status] NOT IN (N'COMPLETED', N'SKIPPED');
GO

CREATE VIEW [dbo].[v_CurrentVehicleOwners]
AS
SELECT
    vo.[vehicle_id],
    vo.[client_id],
    c.[display_name] AS [client_name],
    vo.[is_primary],
    vo.[ownership_from]
FROM [dbo].[VehicleOwners] vo
JOIN [dbo].[Clients] c ON c.[id] = vo.[client_id]
WHERE vo.[ownership_to] IS NULL;
GO

-- ============================================================================
-- ДЕМОНСТРАЦИОННЫЕ ДАННЫЕ
-- ============================================================================

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO [dbo].[Roles] ([code], [name], [description], [is_system]) VALUES
      (N'ADMIN', N'Администратор', N'Полный доступ к системе', 1),
      (N'MANAGER', N'Руководитель', N'Контроль работы автосервиса и отчеты', 1),
      (N'SERVICE_ADVISOR', N'Мастер-приемщик', N'Клиенты, запись, заказ-наряды и согласования', 1),
      (N'MECHANIC', N'Механик', N'Выполнение назначенных работ', 1),
      (N'STOREKEEPER', N'Кладовщик', N'Складской учет и закупки', 1),
      (N'CASHIER', N'Кассир', N'Платежи и возвраты', 1);

    INSERT INTO [dbo].[Permissions] ([code], [name]) VALUES
      (N'clients.read', N'Просмотр клиентов'),
      (N'clients.write', N'Изменение клиентов'),
      (N'vehicles.read', N'Просмотр автомобилей'),
      (N'vehicles.write', N'Изменение автомобилей'),
      (N'appointments.manage', N'Управление записью'),
      (N'orders.read', N'Просмотр заказ-нарядов'),
      (N'orders.create', N'Создание заказ-нарядов'),
      (N'orders.update', N'Изменение заказ-нарядов'),
      (N'orders.approve', N'Согласование заказ-нарядов'),
      (N'jobs.execute', N'Выполнение работ'),
      (N'stock.read', N'Просмотр склада'),
      (N'stock.manage', N'Управление складом'),
      (N'payments.manage', N'Управление платежами'),
      (N'maintenance.manage', N'Управление регламентами ТО'),
      (N'reports.read', N'Просмотр отчетов'),
      (N'users.manage', N'Управление пользователями и ролями');

    INSERT INTO [dbo].[Users]
      ([email], [employee_code], [first_name], [last_name], [middle_name], [phone], [password_hash], [must_change_password])
    VALUES
      (N'admin@autoservice.local', N'ADM-001', N'Системный', N'Администратор', NULL, N'+70000000000', N'REPLACE_WITH_BCRYPT_OR_ASPNET_IDENTITY_HASH', 1),
      (N'advisor@autoservice.local', N'ADV-001', N'Алексей', N'Приемов', N'Игоревич', N'+79990000001', N'REPLACE_WITH_BCRYPT_OR_ASPNET_IDENTITY_HASH', 1),
      (N'mechanic@autoservice.local', N'MEC-001', N'Иван', N'Механиков', N'Сергеевич', N'+79990000002', N'REPLACE_WITH_BCRYPT_OR_ASPNET_IDENTITY_HASH', 1),
      (N'store@autoservice.local', N'STO-001', N'Олег', N'Кладовщиков', N'Петрович', N'+79990000003', N'REPLACE_WITH_BCRYPT_OR_ASPNET_IDENTITY_HASH', 1);

    INSERT INTO [dbo].[UserRoles] ([user_id], [role_id], [assigned_by_user_id])
    SELECT u.[id], r.[id], 1
    FROM [dbo].[Users] u
    JOIN [dbo].[Roles] r ON
      (u.[employee_code] = N'ADM-001' AND r.[code] = N'ADMIN') OR
      (u.[employee_code] = N'ADV-001' AND r.[code] = N'SERVICE_ADVISOR') OR
      (u.[employee_code] = N'MEC-001' AND r.[code] = N'MECHANIC') OR
      (u.[employee_code] = N'STO-001' AND r.[code] = N'STOREKEEPER');

    INSERT INTO [dbo].[RolePermissions] ([role_id], [permission_id])
    SELECT r.[id], p.[id]
    FROM [dbo].[Roles] r
    CROSS JOIN [dbo].[Permissions] p
    WHERE r.[code] = N'ADMIN';

    INSERT INTO [dbo].[RolePermissions] ([role_id], [permission_id])
    SELECT r.[id], p.[id]
    FROM [dbo].[Roles] r
    JOIN [dbo].[Permissions] p ON p.[code] IN (
      N'clients.read', N'clients.write', N'vehicles.read', N'vehicles.write',
      N'appointments.manage', N'orders.read', N'orders.create', N'orders.update',
      N'orders.approve', N'stock.read', N'maintenance.manage', N'reports.read'
    )
    WHERE r.[code] = N'SERVICE_ADVISOR';

    INSERT INTO [dbo].[RolePermissions] ([role_id], [permission_id])
    SELECT r.[id], p.[id]
    FROM [dbo].[Roles] r
    JOIN [dbo].[Permissions] p ON p.[code] IN (N'orders.read', N'orders.update', N'jobs.execute', N'stock.read')
    WHERE r.[code] = N'MECHANIC';

    INSERT INTO [dbo].[RolePermissions] ([role_id], [permission_id])
    SELECT r.[id], p.[id]
    FROM [dbo].[Roles] r
    JOIN [dbo].[Permissions] p ON p.[code] IN (N'stock.read', N'stock.manage', N'orders.read')
    WHERE r.[code] = N'STOREKEEPER';

    INSERT INTO [dbo].[Clients]
      ([client_type], [display_name], [first_name], [last_name], [middle_name], [preferred_channel], [created_by_user_id])
    VALUES
      (N'INDIVIDUAL', N'Иванов Иван Иванович', N'Иван', N'Иванов', N'Иванович', N'PHONE', 2);

    INSERT INTO [dbo].[ClientContacts] ([client_id], [contact_type], [contact_value], [label], [is_primary], [is_verified]) VALUES
      (1, N'PHONE', N'+79991234567', N'Мобильный', 1, 1),
      (1, N'EMAIL', N'ivanov@example.local', N'Личный', 1, 1);

    INSERT INTO [dbo].[ClientConsents] ([client_id], [consent_type], [document_version], [source], [created_by_user_id]) VALUES
      (1, N'PERSONAL_DATA', N'1.0', N'OFFICE', 2),
      (1, N'SERVICE_NOTIFICATIONS', N'1.0', N'OFFICE', 2);

    INSERT INTO [dbo].[VehicleMakes] ([name], [country_code]) VALUES
      (N'Toyota', N'JP'),
      (N'LADA', N'RU'),
      (N'Hyundai', N'KR');

    INSERT INTO [dbo].[VehicleModels] ([make_id], [name], [generation], [production_from], [production_to]) VALUES
      (1, N'Corolla', N'E210', 2018, NULL),
      (2, N'Vesta', N'I', 2015, 2023),
      (3, N'Solaris', N'II', 2017, 2022);

    INSERT INTO [dbo].[Vehicles]
      ([model_id], [vin], [registration_number], [model_year], [engine_volume_l], [fuel_type], [transmission_type], [color], [current_mileage_km])
    VALUES
      (1, N'JTDBR32E720123456', N'А123ВС197', 2020, 1.60, N'PETROL', N'AUTOMATIC', N'Белый', 74500);

    INSERT INTO [dbo].[VehicleOwners] ([vehicle_id], [client_id], [ownership_from], [is_primary]) VALUES
      (1, 1, N'2020-06-15', 1);

    INSERT INTO [dbo].[MileageReadings] ([vehicle_id], [mileage_km], [reading_at], [source], [created_by_user_id]) VALUES
      (1, 74500, SYSUTCDATETIME(), N'INSPECTION', 2);

    INSERT INTO [dbo].[ServiceBays] ([code], [name], [bay_type]) VALUES
      (N'POST-01', N'Пост № 1', N'UNIVERSAL'),
      (N'POST-02', N'Пост № 2', N'LIFT'),
      (N'DIAG-01', N'Диагностический пост', N'DIAGNOSTIC');

    INSERT INTO [dbo].[EmployeeSchedules] ([user_id], [work_date], [start_time], [end_time], [schedule_type]) VALUES
      (2, CONVERT(date, GETDATE()), N'09:00:00', N'18:00:00', N'WORK'),
      (3, CONVERT(date, GETDATE()), N'09:00:00', N'18:00:00', N'WORK'),
      (4, CONVERT(date, GETDATE()), N'09:00:00', N'18:00:00', N'WORK');

    INSERT INTO [dbo].[ServiceCatalog] ([code], [name], [category], [standard_hours], [base_price]) VALUES
      (N'OIL-CHANGE', N'Замена моторного масла и масляного фильтра', N'Техническое обслуживание', 1.00, 2500.00),
      (N'DIAGNOSTICS', N'Компьютерная диагностика', N'Диагностика', 1.00, 2000.00),
      (N'BRAKE-PADS-F', N'Замена передних тормозных колодок', N'Тормозная система', 1.50, 4500.00);

    INSERT INTO [dbo].[PriceLists] ([service_catalog_id], [name], [price], [valid_from]) VALUES
      (1, N'Основной прайс', 2500.00, N'2026-01-01'),
      (2, N'Основной прайс', 2000.00, N'2026-01-01'),
      (3, N'Основной прайс', 4500.00, N'2026-01-01');

    INSERT INTO [dbo].[Appointments]
      ([client_id], [vehicle_id], [service_bay_id], [assigned_user_id], [starts_at], [ends_at], [status], [reason], [created_by_user_id])
    VALUES
      (1, 1, 1, 2, DATEADD(DAY, 1, SYSUTCDATETIME()), DATEADD(DAY, 2, SYSUTCDATETIME()), N'CONFIRMED', N'Плановое ТО: замена масла', 2);

    INSERT INTO [dbo].[WorkOrders]
      ([order_number], [appointment_id], [client_id], [vehicle_id], [service_bay_id], [advisor_user_id], [opened_by_user_id], [status], [mileage_km], [complaint])
    VALUES
      (N'WO-2026-000001', 1, 1, 1, 1, 2, 2, N'APPROVED', 74500, N'Провести плановое техническое обслуживание');

    INSERT INTO [dbo].[OrderStatusHistory] ([work_order_id], [from_status], [to_status], [changed_by_user_id], [comment]) VALUES
      (1, NULL, N'DRAFT', 2, N'Заказ-наряд создан'),
      (1, N'DRAFT', N'AWAITING_APPROVAL', 2, N'Стоимость направлена клиенту'),
      (1, N'AWAITING_APPROVAL', N'APPROVED', 2, N'Клиент согласовал работы');

    INSERT INTO [dbo].[OrderJobs]
      ([work_order_id], [service_catalog_id], [price_list_id], [quantity], [unit_price], [status], [planned_hours])
    VALUES
      (1, 1, 1, 1.00, 2500.00, N'APPROVED', 1.00);

    INSERT INTO [dbo].[JobAssignments] ([order_job_id], [user_id], [assignment_status]) VALUES
      (1, 3, N'ACCEPTED');

    INSERT INTO [dbo].[Approvals]
      ([work_order_id], [approval_type], [status], [requested_amount], [responded_at], [response_channel], [approved_by_client_id], [created_by_user_id])
    VALUES
      (1, N'ESTIMATE', N'APPROVED', 5500.00, SYSUTCDATETIME(), N'PHONE', 1, 2);

    INSERT INTO [dbo].[Suppliers] ([name], [tax_id], [phone], [email], [contact_person]) VALUES
      (N'ООО Автодеталь', N'7700000001', N'+74950000001', N'supply@autodetal.example.local', N'Петров Петр');

    INSERT INTO [dbo].[Parts]
      ([sku], [oem_number], [name], [manufacturer], [unit], [purchase_price], [sale_price], [minimum_stock])
    VALUES
      (N'OIL-5W30-4L', N'08880-80845', N'Моторное масло 5W-30, 4 л', N'Toyota', N'PCS', 2800.00, 3500.00, 2.000),
      (N'FILTER-OIL-001', N'90915-YZZE1', N'Фильтр масляный', N'Toyota', N'PCS', 450.00, 750.00, 5.000);

    INSERT INTO [dbo].[Warehouses] ([code], [name], [responsible_user_id]) VALUES
      (N'MAIN', N'Основной склад', 4);

    INSERT INTO [dbo].[StockItems] ([warehouse_id], [part_id], [quantity_on_hand], [reserved_quantity], [average_cost]) VALUES
      (1, 1, 0.000, 0.000, 0.00),
      (1, 2, 0.000, 0.000, 0.00);

    INSERT INTO [dbo].[StockMovements]
      ([stock_item_id], [movement_type], [quantity_delta], [unit_cost], [supplier_id], [document_number], [created_by_user_id])
    VALUES
      (1, N'RECEIPT', 10.000, 2800.00, 1, N'IN-2026-0001', 4),
      (2, N'RECEIPT', 20.000, 450.00, 1, N'IN-2026-0001', 4);

    INSERT INTO [dbo].[Reservations] ([stock_item_id], [work_order_id], [order_job_id], [quantity], [reserved_by_user_id]) VALUES
      (1, 1, 1, 1.000, 4),
      (2, 1, 1, 1.000, 4);

    INSERT INTO [dbo].[MaintenanceTypes] ([code], [name], [description]) VALUES
      (N'ENGINE_OIL', N'Замена моторного масла', N'Регулярная замена масла и масляного фильтра'),
      (N'BRAKE_SERVICE', N'Обслуживание тормозной системы', N'Осмотр и замена компонентов тормозной системы');

    INSERT INTO [dbo].[MaintenanceRules]
      ([maintenance_type_id], [vehicle_model_id], [rule_name], [interval_km], [interval_months], [warning_km], [warning_days], [service_catalog_id])
    VALUES
      (1, 1, N'Toyota Corolla E210: масло каждые 10 000 км или 12 месяцев', 10000, 12, 1000, 30, 1);

    INSERT INTO [dbo].[MaintenanceSchedules]
      ([vehicle_id], [maintenance_rule_id], [last_service_date], [last_service_mileage_km], [next_due_date], [next_due_mileage_km], [status])
    VALUES
      (1, 1, N'2025-07-01', 65000, N'2026-07-01', 75000, N'DUE_SOON');

    INSERT INTO [dbo].[Recommendations]
      ([vehicle_id], [work_order_id], [maintenance_schedule_id], [title], [description], [priority], [status], [recommended_by_user_id], [due_date], [due_mileage_km])
    VALUES
      (1, 1, 1, N'Плановая замена масла', N'Выполнить замену масла и масляного фильтра не позднее указанного срока.', N'HIGH', N'ACCEPTED', 2, N'2026-07-01', 75000);

    INSERT INTO [dbo].[Notifications]
      ([client_id], [recommendation_id], [maintenance_schedule_id], [channel], [recipient], [subject], [body], [status], [scheduled_at])
    VALUES
      (1, 1, 1, N'EMAIL', N'ivanov@example.local', N'Напоминание о техническом обслуживании', N'Для автомобиля Toyota Corolla приближается срок замены моторного масла.', N'PENDING', SYSUTCDATETIME());

    INSERT INTO [dbo].[AuditEvents] ([user_id], [event_type], [entity_type], [entity_id], [payload_json]) VALUES
      (1, N'DATABASE_SEEDED', N'SYSTEM', N'autoservice_db', N'{"version":"1.0","tables":44}');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- ============================================================================
-- КОНТРОЛЬНЫЕ ЗАПРОСЫ
-- ============================================================================

SELECT COUNT(*) AS [table_count]
FROM sys.tables
WHERE [is_ms_shipped] = 0;

SELECT * FROM [dbo].[v_WorkOrderTotals];
SELECT * FROM [dbo].[v_LowStock];
SELECT * FROM [dbo].[v_DueMaintenance];
GO

-- Конец файла.
