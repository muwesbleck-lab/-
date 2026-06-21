using Autoservice.Api.Data;
using Autoservice.Api.DTOs;
using Autoservice.Api.Models;
using Dapper;

namespace Autoservice.Api.Repositories;

public sealed class WorkOrdersRepository(ISqlConnectionFactory connectionFactory) : IWorkOrdersRepository
{
    private const string SelectSql = """
        SELECT
            wo.id AS Id,
            wo.order_number AS OrderNumber,
            wo.client_id AS ClientId,
            c.display_name AS ClientName,
            wo.vehicle_id AS VehicleId,
            CONCAT(vmk.name, N' ', vmd.name, N' ', COALESCE(v.registration_number, N'')) AS Vehicle,
            wo.status AS Status,
            wo.opened_at AS OpenedAt,
            wo.planned_start_at AS PlannedStartAt,
            wo.planned_end_at AS PlannedEndAt,
            wo.mileage_km AS MileageKm,
            wo.complaint AS Complaint
        FROM dbo.WorkOrders wo
        INNER JOIN dbo.Clients c ON c.id = wo.client_id
        INNER JOIN dbo.Vehicles v ON v.id = wo.vehicle_id
        INNER JOIN dbo.VehicleModels vmd ON vmd.id = v.model_id
        INNER JOIN dbo.VehicleMakes vmk ON vmk.id = vmd.make_id
        """;

    public async Task<IReadOnlyList<WorkOrderSummary>> GetAllAsync(
        string? status,
        int limit,
        CancellationToken cancellationToken)
    {
        var sql = SelectSql + """
            WHERE (@Status IS NULL OR wo.status = @Status)
            ORDER BY wo.opened_at DESC
            OFFSET 0 ROWS FETCH NEXT @Limit ROWS ONLY;
            """;
        using var connection = connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<WorkOrderSummary>(new CommandDefinition(
            sql,
            new
            {
                Status = string.IsNullOrWhiteSpace(status) ? null : status.Trim().ToUpperInvariant(),
                Limit = Math.Clamp(limit, 1, 200)
            },
            cancellationToken: cancellationToken));
        return rows.AsList();
    }

    public async Task<WorkOrderSummary?> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var sql = SelectSql + " WHERE wo.id = @Id;";
        using var connection = connectionFactory.CreateConnection();
        return await connection.QuerySingleOrDefaultAsync<WorkOrderSummary>(new CommandDefinition(
            sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(
        string orderNumber,
        CreateWorkOrderRequest request,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO dbo.WorkOrders
                (order_number, client_id, vehicle_id, service_bay_id, advisor_user_id,
                 opened_by_user_id, status, planned_start_at, planned_end_at,
                 mileage_km, complaint)
            OUTPUT INSERTED.id
            VALUES
                (@OrderNumber, @ClientId, @VehicleId, @ServiceBayId, @AdvisorUserId,
                 @OpenedByUserId, N'DRAFT', @PlannedStartAt, @PlannedEndAt,
                 @MileageKm, @Complaint);
            """;

        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<long>(new CommandDefinition(
            sql,
            new
            {
                OrderNumber = orderNumber,
                request.ClientId,
                request.VehicleId,
                request.ServiceBayId,
                request.AdvisorUserId,
                request.OpenedByUserId,
                request.PlannedStartAt,
                request.PlannedEndAt,
                request.MileageKm,
                request.Complaint
            },
            cancellationToken: cancellationToken));
    }
}
