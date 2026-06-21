#!/usr/bin/env bash
set -e
export ASPNETCORE_ENVIRONMENT=Development
dotnet run --project ../backend/src/Autoservice.Api/Autoservice.Api.csproj
