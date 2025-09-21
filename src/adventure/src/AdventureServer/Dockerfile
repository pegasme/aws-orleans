FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS base
WORKDIR /app

EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build
WORKDIR /src
COPY ../. .
RUN dotnet restore
WORKDIR /src/AdventureServer
RUN dotnet publish -c Release -o /app --no-restore

# final stage/image
FROM base AS final
WORKDIR /app
COPY --from=build /app ./
ENTRYPOINT ["dotnet", "AdventureServer.dll"]