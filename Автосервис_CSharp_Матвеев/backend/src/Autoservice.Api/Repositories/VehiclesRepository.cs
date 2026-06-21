using Autoservice.Api.Data;
using Autoservice.Api.DTOs;
using Autoservice.Api.Models;
using Dapper;

namespace Autoservice.Api.Repositories;

public sealed class VehiclesRepository(ISqlConnectionFactory connectionFactory) : IVehiclesRepository
{
    public async Task<IReadOnlyList<VehicleSummary>> GetAllAsync(
        long? clientId,
        int limit,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                v.id AS Id,
                vo.client_id AS ClientId,
                c.display_name AS ClientName,
                vmk.name AS Make,
                vmd.name AS Model,
                vmd.generation AS Generation,
                RTRIM(v.vin) AS Vin,
                v.registration_number AS RegistrationNumber,
                v.model_year AS ModelYear,
                v.current_mileage_km AS CurrentMileageKm,
                v.is_active AS IsActive
            FROM dbo.Vehicles v
            INNER JOIN dbo.VehicleModels vmd ON vmd.id = v.model_id
            INNER JOIN dbo.VehicleMakes vmk ON vmk.id = vmd.make_id
            INNER JOIN dbo.VehicleOwners vo
                ON vo.vehicle_id = v.id AND vo.ownership_to IS NULL AND vo.is_primary = 1
            INNER JOIN dbo.Clients c ON c.id = vo.client_id
            WHERE (@ClientId IS NULL OR vo.client_id = @ClientId)
            ORDER BY c.display_name, vmk.name, vmd.name
            OFFSET 0 ROWS FETCH NEXT @Limit ROWS ONLY;
            """;

        using var connection = connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<VehicleSummary>(new CommandDefinition(
            sql,
            new { ClientId = clientId, Limit = Math.Clamp(limit, 1, 200) },
            cancellationToken: cancellationToken));
        return rows.AsList();
    }

    public async Task<long> CreateAsync(CreateVehicleRequest request, CancellationToken cancellationToken)
    {
        const string insertVehicle = """
            INSERT INTO dbo.Vehicles
                (model_id, vin, registration_number, model_year, engine_code,
                 engine_volume_l, fuel_type, transmission_type, color, current_mileage_km)
            OUTPUT INSERTED.id
            VALUES
                (@ModelId, @Vin, @RegistrationNumber, @ModelYear, @EngineCode,
                 @EngineVolumeL, @FuelType, @TransmissionType, @Color, @CurrentMileageKm);
            """;
        const string insertOwner = """
            INSERT INTO dbo.VehicleOwners
                (vehicle_id, client_id, ownership_from, is_primary)
            VALUES
                (@VehicleId, @ClientId, CAST(SYSUTCDATETIME() AS date), 1);
            """;

        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var vehicleId = await connection.ExecuteScalarAsync<long>(new CommandDefinition(
                insertVehicle,
                new
                {
                    request.ModelId,
                    Vin = request.Vin?.Trim().ToUpperInvariant(),
                    RegistrationNumber = request.RegistrationNumber?.Trim().ToUpperInvariant(),
                    request.ModelYear,
                    request.EngineCode,
                    request.EngineVolumeL,
                    FuelType = request.FuelType?.ToUpperInvariant(),
                    TransmissionType = request.TransmissionType?.ToUpperInvariant(),
                    request.Color,
                    CurrentMileageKm = Math.Max(0, request.CurrentMileageKm)
                },
                transaction,
                cancellationToken: cancellationToken));

            await connection.ExecuteAsync(new CommandDefinition(
                insertOwner,
                new { VehicleId = vehicleId, request.ClientId },
                transaction,
                cancellationToken: cancellationToken));

            transaction.Commit();
            return vehicleId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }
}
