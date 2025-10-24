using System.Net;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Orleans.Configuration;
using Orleans.Hosting;
using Orleans.Serialization;
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Compact;
using AdventureGrainInterfaces;
using AdventureGrains;
using AWSECS.ContainerMetadata.Extensions;
using Microsoft.CodeAnalysis.Options;
using AWSECS.ContainerMetadata.Contracts;
using AdventureServer.Extensions;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

Log.Information($"Starting up! {Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")}");

bool isDevelopment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development";

try
{
    // Configure the host
    var builder = WebApplication.CreateBuilder(args);

    builder.Services.AddSerilog((services, lc) => lc
        .ReadFrom.Configuration(builder.Configuration)
        .Enrich.FromLogContext()
        .WriteTo.Console(new CompactJsonFormatter()));

    builder.ConfigureCluster(isDevelopment);

    builder.Services.AddAWSContainerMetadataService();
    builder.Services.AddSerializer(serializerBuilder => serializerBuilder.AddNewtonsoftJsonSerializer(type => type.Namespace.StartsWith("AdventureGrains")));

    var app = builder.Build();
    app.UseSerilogRequestLogging();

    // Start the host
    app.Run();

    Log.Information("Stopped cleanly");
    return 0;
}
catch (Exception ex)
{
    Log.Fatal(ex, "An unhandled exception occurred during bootstrapping");
    return 1;
}
finally
{
    Log.CloseAndFlush();
}