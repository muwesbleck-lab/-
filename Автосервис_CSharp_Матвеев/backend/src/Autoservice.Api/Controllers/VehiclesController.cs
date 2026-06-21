using Autoservice.Api.DTOs;
using Autoservice.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autoservice.Api.Controllers;

[ApiController]
[Route("api/vehicles")]
public sealed class VehiclesController(IVehiclesRepository repository) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] long? clientId,
        [FromQuery] int limit = 50,
        CancellationToken cancellationToken = default)
        => Ok(await repository.GetAllAsync(clientId, limit, cancellationToken));

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateVehicleRequest request,
        CancellationToken cancellationToken)
    {
        if (request.ClientId <= 0 || request.ModelId <= 0)
            return BadRequest(new { error = "ClientId и ModelId должны быть положительными." });
        if (request.Vin is { Length: > 0 } && request.Vin.Trim().Length != 17)
            return BadRequest(new { error = "VIN должен содержать 17 символов." });

        var id = await repository.CreateAsync(request, cancellationToken);
        return Created($"/api/vehicles/{id}", new { id });
    }
}
