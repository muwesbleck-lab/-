using Autoservice.Api.Data;
using Autoservice.Api.DTOs;
using Autoservice.Api.Models;
using Dapper;

namespace Autoservice.Api.Repositories;

public sealed class ClientsRepository(ISqlConnectionFactory connectionFactory) : IClientsRepository
{
    private const string SelectColumns = """
        SELECT
            c.id AS Id,
            c.client_type AS ClientType,
            c.display_name AS DisplayName,
            c.first_name AS FirstName,
            c.last_name AS LastName,
            c.middle_name AS MiddleName,
            c.preferred_channel AS PreferredChannel,
            c.is_active AS IsActive,
            c.created_at AS CreatedAt,
            MAX(CASE WHEN cc.contact_type = N'PHONE' AND cc.is_primary = 1 THEN cc.contact_value END) AS Phone,
            MAX(CASE WHEN cc.contact_type = N'EMAIL' AND cc.is_primary = 1 THEN cc.contact_value END) AS Email
        FROM dbo.Clients c
        LEFT JOIN dbo.ClientContacts cc ON cc.client_id = c.id
        """;

    public async Task<IReadOnlyList<Client>> GetAllAsync(
        string? search,
        int limit,
        CancellationToken cancellationToken)
    {
        var safeLimit = Math.Clamp(limit, 1, 200);
        var sql = SelectColumns + """
            WHERE (@Search IS NULL OR c.display_name LIKE N'%' + @Search + N'%')
            GROUP BY c.id, c.client_type, c.display_name, c.first_name, c.last_name,
                     c.middle_name, c.preferred_channel, c.is_active, c.created_at
            ORDER BY c.display_name
            OFFSET 0 ROWS FETCH NEXT @Limit ROWS ONLY;
            """;

        using var connection = connectionFactory.CreateConnection();
        var command = new CommandDefinition(
            sql,
            new { Search = string.IsNullOrWhiteSpace(search) ? null : search.Trim(), Limit = safeLimit },
            cancellationToken: cancellationToken);
        var rows = await connection.QueryAsync<Client>(command);
        return rows.AsList();
    }

    public async Task<Client?> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var sql = SelectColumns + """
            WHERE c.id = @Id
            GROUP BY c.id, c.client_type, c.display_name, c.first_name, c.last_name,
                     c.middle_name, c.preferred_channel, c.is_active, c.created_at;
            """;

        using var connection = connectionFactory.CreateConnection();
        return await connection.QuerySingleOrDefaultAsync<Client>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(CreateClientRequest request, CancellationToken cancellationToken)
    {
        const string insertClient = """
            INSERT INTO dbo.Clients
                (client_type, display_name, first_name, last_name, middle_name, preferred_channel)
            OUTPUT INSERTED.id
            VALUES
                (@ClientType, @DisplayName, @FirstName, @LastName, @MiddleName, @PreferredChannel);
            """;
        const string insertContact = """
            INSERT INTO dbo.ClientContacts
                (client_id, contact_type, contact_value, label, is_primary, is_verified)
            VALUES
                (@ClientId, @ContactType, @ContactValue, @Label, 1, 0);
            """;

        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var id = await connection.ExecuteScalarAsync<long>(new CommandDefinition(
                insertClient,
                new
                {
                    ClientType = request.ClientType.ToUpperInvariant(),
                    DisplayName = request.DisplayName.Trim(),
                    FirstName = request.FirstName?.Trim(),
                    LastName = request.LastName?.Trim(),
                    MiddleName = request.MiddleName?.Trim(),
                    PreferredChannel = request.PreferredChannel.ToUpperInvariant()
                },
                transaction,
                cancellationToken: cancellationToken));

            if (!string.IsNullOrWhiteSpace(request.Phone))
            {
                await connection.ExecuteAsync(new CommandDefinition(
                    insertContact,
                    new { ClientId = id, ContactType = "PHONE", ContactValue = request.Phone.Trim(), Label = "Основной" },
                    transaction,
                    cancellationToken: cancellationToken));
            }

            if (!string.IsNullOrWhiteSpace(request.Email))
            {
                await connection.ExecuteAsync(new CommandDefinition(
                    insertContact,
                    new { ClientId = id, ContactType = "EMAIL", ContactValue = request.Email.Trim(), Label = "Основной" },
                    transaction,
                    cancellationToken: cancellationToken));
            }

            transaction.Commit();
            return id;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }
}
