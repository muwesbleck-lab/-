namespace Autoservice.Api.Models;

public sealed record WorkOrderSummary(
    long Id,
    string OrderNumber,
    long ClientId,
    string ClientName,
    long VehicleId,
    string Vehicle,
    string Status,
    DateTime OpenedAt,
    DateTime? PlannedStartAt,
    DateTime? PlannedEndAt,
    int? MileageKm,
    string? Complaint);
