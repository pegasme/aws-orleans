using System.Net;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Orleans.Configuration;
using Orleans.Hosting;
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Compact;
using AdventureGrainInterfaces;
using AdventureGrains;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

Log.Information("Starting up!");

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
        siloBuilder.AddDynamoDBGrainStorage(
            name: builder.Configuration["GrainStorage"],
            configureOptions: options =>
            {
                options.AccessKey = builder.Configuration["AWS_ACCESS_KEY_ID"];
                options.SecretKey = builder.Configuration["AWS_SECRET_ACCESS_KEY"];
                options.TableName = builder.Configuration["GrainTableName"];
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
            options.CreateIfNotExists = false;
        });
        }
    });

    builder.Services.AddTransient<IPlayerGrain, PlayerGrain>();
    builder.Services.AddTransient<IRoomGrain, RoomGrain>();
    builder.Services.AddTransient<IMonsterGrain, MonsterGrain>();

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