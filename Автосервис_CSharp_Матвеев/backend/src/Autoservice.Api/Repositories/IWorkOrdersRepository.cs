using Autoservice.Api.DTOs;
using Autoservice.Api.Models;

namespace Autoservice.Api.Repositories;

public interface IWorkOrdersRepository
{
    Task<IReadOnlyList<WorkOrderSummary>> GetAllAsync(string? status, int limit, CancellationToken cancellationToken);
    Task<WorkOrderSummary?> GetByIdAsync(long id, CancellationToken cancellationToken);
    Task<long> CreateAsync(string orderNumber, CreateWorkOrderRequest request, CancellationToken cancellationToken);
}
