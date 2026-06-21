using Autoservice.Api.DTOs;
using Autoservice.Api.Validation;

namespace Autoservice.Api.Tests;

public sealed class ClientInputValidatorTests
{
    [Fact]
    public void Validate_ReturnsError_WhenDisplayNameIsEmpty()
    {
        var request = new CreateClientRequest(
            "INDIVIDUAL", "", null, null, null, null, null, "PHONE");

        var errors = ClientInputValidator.Validate(request);

        Assert.Contains(nameof(request.DisplayName), errors.Keys);
    }

    [Fact]
    public void Validate_ReturnsNoErrors_ForValidRequest()
    {
        var request = new CreateClientRequest(
            "INDIVIDUAL", "Иванов Иван", "Иван", "Иванов", null,
            "+79990000000", "client@example.test", "PHONE");

        var errors = ClientInputValidator.Validate(request);

        Assert.Empty(errors);
    }
}
