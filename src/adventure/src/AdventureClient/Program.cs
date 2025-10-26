using Amazon.DynamoDBv2;
using AdventureClient.Services.Interfaces;
using AdventureClient.Services.Services;
using AdventureClient.Middlewares;
using AdventureClient.Utilities;
using AdventureGrainInterfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Orleans.Configuration;
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Compact;
using Swashbuckle.AspNetCore;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

Log.Information("Starting up!");

bool isDevelopment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development";

var orleansClusterId = Environment.GetEnvironmentVariable("ORLEANS_CLUSTER_ID") ?? throw new Exception("ORLEANS_CLUSTER_ID configuration is missing");
Log.Information($"Using Orleans Cluster: {orleansClusterId}"); 

var orleansServiceId = Environment.GetEnvironmentVariable("ORLEANS_SERVICE_ID") ?? throw new Exception("ORLEANS_SERVICE_ID configuration is missing");
Log.Information($"Using Orleans Service: {orleansServiceId}");

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.Services.AddHealthChecks();
    builder.Services.AddSwaggerGen(c => {
        c.OperationFilter<HeaderSwaggerAttribute>();
    });

    builder.Services.AddAuthentication("SessionTokens").AddScheme<AuthenticationSchemeOptions, SessionTokenAuthSchemeHandler>(
       "SessionTokens",
       opts => {}
   );
    builder.Services.AddAuthorization();

    builder.Services.AddControllers();
    builder.Services.AddEndpointsApiExplorer();

    builder.Services.AddMemoryCache();

    builder.Services.AddSingleton<IPlayerService, PlayerService>();
    builder.Services.AddSingleton<IGameAuthorizationService, GameAuthorizationService>();
    builder.Services.AddSingleton<IPlayerService, PlayerService>();


    builder.UseOrleansClient(clientBuilder =>
    {
        clientBuilder.Configure<ClusterOptions>(options =>
        {
            options.ClusterId = orleansClusterId;
            options.ServiceId = orleansServiceId;
        });

        if (isDevelopment)
        {
            clientBuilder.UseLocalhostClustering(30000);
        }

        else
        {
            clientBuilder.UseDynamoDBClustering(options =>
            {
                options.TableName = Environment.GetEnvironmentVariable("CLUSTER_TABLE_NAME") ?? throw new Exception("CLUSTER_TABLE_NAME configuration is missing");
                options.Service = Environment.GetEnvironmentVariable("AWS_REGION") ?? throw new Exception("AWS_REGION configuration is missing");
                options.CreateIfNotExists = false;
            });
        }
    });

    using var app = builder.Build();

    app.MapHealthChecks("/health");
    app.MapControllers();

    app.UseCors();

    // Configure the HTTP request pipeline.
    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }

    app.UseAuthentication();
    app.UseAuthorization();
    // Start the host
    await app.RunAsync();

    Log.Information("Stopped cleanly");
}
catch (Exception ex)
{
    Log.Fatal(ex, "An unhandled exception occurred during bootstrapping");
}
finally
{
    Log.CloseAndFlush();
}
