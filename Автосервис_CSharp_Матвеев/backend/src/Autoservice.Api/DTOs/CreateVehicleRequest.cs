namespace Autoservice.Api.DTOs;

public sealed record CreateVehicleRequest(
    long ClientId,
    long ModelId,
    string? Vin,
    string? RegistrationNumber,
    short? ModelYear,
    int CurrentMileageKm = 0,
    string? EngineCode = null,
    decimal? EngineVolumeL = null,
    string? FuelType = null,
    string? TransmissionType = null,
    string? Color = null);
