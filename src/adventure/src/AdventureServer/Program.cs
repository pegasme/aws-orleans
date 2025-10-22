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

    builder.UseOrleans(siloBuilder =>
    {
        siloBuilder.AddDynamoDBGrainStorageAsDefault(options =>
            {
                options.AccessKey = builder.Configuration["AWS_ACCESS_KEY_ID"];
                options.SecretKey = builder.Configuration["AWS_SECRET_ACCESS_KEY"];
                options.TableName = builder.Configuration["GrainTableName"];
                options.TimeToLive = TimeSpan.FromDays(5);
                options.Service = builder.Configuration["AWS_REGION"];
                options.CreateIfNotExists = false;
            });

        if (isDevelopment)
        {
            siloBuilder.UseLocalhostClustering();
        }
        else
        {
            siloBuilder.UseDynamoDBClustering(options =>
            {
                options.AccessKey = builder.Configuration["AWS_ACCESS_KEY_ID"];
                options.SecretKey = builder.Configuration["AWS_SECRET_ACCESS_KEY"];
                options.TableName = builder.Configuration["ClusterTableName"];
                options.Service = builder.Configuration["AWS_REGION"];
                options.CreateIfNotExists = false;
            });
        }

        siloBuilder
            .ConfigureEndpoints(siloPort: 11111, gatewayPort: 30000)
            .Configure<ClusterOptions>(options =>
            {
                options.ClusterId = builder.Configuration["ORLEANS_CLUSTER_ID"] ?? "dev";
                options.ServiceId = builder.Configuration["ORLEANS_SERVICE_ID"] ?? "AdventureApp";
            })
            .ConfigureLogging(logging => logging.AddConsole());
    });

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