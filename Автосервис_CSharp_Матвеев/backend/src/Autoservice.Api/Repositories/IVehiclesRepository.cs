using Autoservice.Api.DTOs;
using Autoservice.Api.Models;

namespace Autoservice.Api.Repositories;

public interface IVehiclesRepository
{
    Task<IReadOnlyList<VehicleSummary>> GetAllAsync(long? clientId, int limit, CancellationToken cancellationToken);
    Task<long> CreateAsync(CreateVehicleRequest request, CancellationToken cancellationToken);
}
