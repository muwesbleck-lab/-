namespace Autoservice.Api.DTOs;

public sealed record CreateWorkOrderRequest(
    long ClientId,
    long VehicleId,
    int? MileageKm,
    string? Complaint,
    DateTime? PlannedStartAt,
    DateTime? PlannedEndAt,
    long? ServiceBayId = null,
    long? AdvisorUserId = null,
    long? OpenedByUserId = null);
