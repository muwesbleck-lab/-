using Autoservice.Api.DTOs;
using Autoservice.Api.Repositories;
using Autoservice.Api.Validation;
using Microsoft.AspNetCore.Mvc;

namespace Autoservice.Api.Controllers;

[ApiController]
[Route("api/clients")]
public sealed class ClientsController(IClientsRepository repository) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? search,
        [FromQuery] int limit = 50,
        CancellationToken cancellationToken = default)
        => Ok(await repository.GetAllAsync(search, limit, cancellationToken));

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id, CancellationToken cancellationToken)
    {
        var client = await repository.GetByIdAsync(id, cancellationToken);
        return client is null ? NotFound() : Ok(client);
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateClientRequest request,
        CancellationToken cancellationToken)
    {
        var errors = ClientInputValidator.Validate(request);
        if (errors.Count > 0)
            return ValidationProblem(new ValidationProblemDetails(errors));

        var id = await repository.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }
}
