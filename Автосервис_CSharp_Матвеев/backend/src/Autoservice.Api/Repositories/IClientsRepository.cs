using Autoservice.Api.DTOs;
using Autoservice.Api.Models;

namespace Autoservice.Api.Repositories;

public interface IClientsRepository
{
    Task<IReadOnlyList<Client>> GetAllAsync(string? search, int limit, CancellationToken cancellationToken);
    Task<Client?> GetByIdAsync(long id, CancellationToken cancellationToken);
    Task<long> CreateAsync(CreateClientRequest request, CancellationToken cancellationToken);
}
