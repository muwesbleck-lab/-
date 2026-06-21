using System.Data;

namespace Autoservice.Api.Data;

public interface ISqlConnectionFactory
{
    IDbConnection CreateConnection();
}
