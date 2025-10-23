# Use the official .NET 9 SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY . .
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish ./AdventureServer/AdventureServer.csproj -c Release -o /app

# Use the official .NET 9 runtime image for the final container
FROM mcr.microsoft.com/dotnet/runtime:9.0 AS runtime
WORKDIR /app
COPY --from=build /app .
# Run the application
ENTRYPOINT ["dotnet", "AdventureServer.dll"]