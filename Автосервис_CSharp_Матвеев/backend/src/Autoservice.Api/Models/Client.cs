namespace Autoservice.Api.Models;

public sealed record Client(
    long Id,
    string ClientType,
    string DisplayName,
    string? FirstName,
    string? LastName,
    string? MiddleName,
    string PreferredChannel,
    bool IsActive,
    DateTime CreatedAt,
    string? Phone,
    string? Email);
