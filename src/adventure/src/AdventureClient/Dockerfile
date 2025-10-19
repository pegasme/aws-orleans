# Use the official .NET 9 SDK image to build the app
FROM public.ecr.aws/lambda/dotnet:9 as base
ENV DOTNET_EnableWriteXorExecute=0
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
# Copy csproj and restore as distinct layers
COPY . .
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet build ./AdventureClient/AdventureClient.csproj -c Release -o out

FROM build AS publish
RUN dotnet publish ./AdventureClient/AdventureClient.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /var/task
COPY --from=publish /app/publish .

# Run the application
CMD ["AdventureClient"]