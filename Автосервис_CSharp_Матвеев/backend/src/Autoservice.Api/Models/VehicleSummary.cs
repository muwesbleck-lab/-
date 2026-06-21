namespace Autoservice.Api.Models;

public sealed record VehicleSummary(
    long Id,
    long ClientId,
    string ClientName,
    string Make,
    string Model,
    string? Generation,
    string? Vin,
    string? RegistrationNumber,
    short? ModelYear,
    int CurrentMileageKm,
    bool IsActive);
