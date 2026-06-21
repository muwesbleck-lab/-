using System.Data;
using Microsoft.Data.SqlClient;

namespace Autoservice.Api.Data;

public sealed class SqlConnectionFactory(IConfiguration configuration) : ISqlConnectionFactory
{
    public IDbConnection CreateConnection()
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Строка подключения 'DefaultConnection' не настроена.");
        }

        return new SqlConnection(connectionString);
    }
}
