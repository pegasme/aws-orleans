FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app

# Use the official .NET 9 SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY . .
RUN dotnet restore
RUN dotnet publish ./AdventureServer/AdventureServer.csproj -c Release -r linux-x64 -o /app/publish

# Environment variables for Orleans (can be overridden at runtime)
ENV ORLEANS_SILO_PORT=11111
ENV ORLEANS_GATEWAY_PORT=30000
ENV ORLEANS_DASHBOARD_PORT=8080
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

# Expose the ports
EXPOSE 11111 30000 8080

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "AdventureServer.dll"]