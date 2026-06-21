using Autoservice.Api.DTOs;
using System.Net.Mail;

namespace Autoservice.Api.Validation;

public static class ClientInputValidator
{
    private static readonly HashSet<string> ClientTypes = ["INDIVIDUAL", "LEGAL"];
    private static readonly HashSet<string> Channels = ["PHONE", "EMAIL", "SMS", "PUSH", "TELEGRAM"];

    public static IReadOnlyDictionary<string, string[]> Validate(CreateClientRequest request)
    {
        var errors = new Dictionary<string, string[]>();

        if (string.IsNullOrWhiteSpace(request.DisplayName))
            errors[nameof(request.DisplayName)] = ["Наименование клиента обязательно."];

        if (!ClientTypes.Contains(request.ClientType?.ToUpperInvariant() ?? string.Empty))
            errors[nameof(request.ClientType)] = ["Допустимые значения: INDIVIDUAL, LEGAL."];

        if (!Channels.Contains(request.PreferredChannel?.ToUpperInvariant() ?? string.Empty))
            errors[nameof(request.PreferredChannel)] = ["Недопустимый канал связи."];

        if (!string.IsNullOrWhiteSpace(request.Email))
        {
            try { _ = new MailAddress(request.Email); }
            catch { errors[nameof(request.Email)] = ["Некорректный email."]; }
        }

        return errors;
    }
}
