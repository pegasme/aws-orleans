using System.Net;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Orleans.Configuration;
using Orleans.Hosting;
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Compact;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

Log.Information("Starting up!");

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
        siloBuilder.UseDynamoDBClustering(options =>
        {
            options.AccessKey = builder.Configuration["AWS_ACCESS_KEY_ID"];
            options.SecretKey = builder.Configuration["AWS_SECRET_ACCESS_KEY"];
            options.TableName = builder.Configuration["DynamoDbTableName"];
            options.CreateIfNotExists = false;
        });

        siloBuilder.AddDynamoDBGrainStorage(
            name: "AdventureStore",
            configureOptions: options =>
            {
                options.AccessKey = builder.Configuration["AWS_ACCESS_KEY_ID"];
                options.SecretKey = builder.Configuration["AWS_SECRET_ACCESS_KEY"];
                options.TableName = builder.Configuration["DynamoDbTableName"];
            });
    });

    await using var app = builder.Build();
    app.UseSerilogRequestLogging();
    // Start the host
    await app.StartAsync();

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