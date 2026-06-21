using Autoservice.Api.DTOs;
using Autoservice.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autoservice.Api.Controllers;

[ApiController]
[Route("api/work-orders")]
public sealed class WorkOrdersController(IWorkOrdersRepository repository) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? status,
        [FromQuery] int limit = 50,
        CancellationToken cancellationToken = default)
        => Ok(await repository.GetAllAsync(status, limit, cancellationToken));

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id, CancellationToken cancellationToken)
    {
        var order = await repository.GetByIdAsync(id, cancellationToken);
        return order is null ? NotFound() : Ok(order);
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateWorkOrderRequest request,
        CancellationToken cancellationToken)
    {
        if (request.ClientId <= 0 || request.VehicleId <= 0)
            return BadRequest(new { error = "ClientId и VehicleId должны быть положительными." });
        if (request.PlannedStartAt.HasValue && request.PlannedEndAt < request.PlannedStartAt)
            return BadRequest(new { error = "Окончание не может быть раньше начала." });

        var orderNumber = $"WO-{DateTime.UtcNow:yyyyMMdd-HHmmss}-{Random.Shared.Next(1000, 9999)}";
        var id = await repository.CreateAsync(orderNumber, request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id }, new { id, orderNumber });
    }
}
