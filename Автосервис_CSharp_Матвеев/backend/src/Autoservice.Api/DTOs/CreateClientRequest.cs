namespace Autoservice.Api.DTOs;

public sealed record CreateClientRequest(
    string ClientType,
    string DisplayName,
    string? FirstName,
    string? LastName,
    string? MiddleName,
    string? Phone,
    string? Email,
    string PreferredChannel = "PHONE");
