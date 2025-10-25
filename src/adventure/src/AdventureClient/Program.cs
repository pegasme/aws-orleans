using Amazon.DynamoDBv2;
using AdventureClient.Services.Interfaces;
using AdventureClient.Services.Services;
using AdventureGrainInterfaces;
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

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.Services.AddHealthChecks();
    builder.Services.AddControllers();
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen();

    builder.Services.AddSingleton<IPlayerService, PlayerService>();

    var orleansClusterId = builder.Configuration["ORLEANS_CLUSTER_ID"] ?? throw new Exception("ORLEANS_CLUSTER_ID configuration is missing");
    Log.Information($"Using Orleans Cluster: {orleansClusterId}"); 

    var orleansServiceId = builder.Configuration["ORLEANS_SERVICE_ID"] ?? throw new Exception("ORLEANS_SERVICE_ID configuration is missing");
    Log.Information($"Using Orleans Service: {orleansServiceId}");

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
                options.TableName = builder.Configuration["CLUSTER_TABLE_NAME"];
                options.Service = builder.Configuration["AWS_REGION"];
                options.CreateIfNotExists = false;
            });
        }
    });

    builder.Services.AddAWSLambdaHosting(LambdaEventSource.RestApi);

    using var app = builder.Build();

    app.MapHealthChecks("/health");
    app.MapControllers();

    // Configure the HTTP request pipeline.
    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }

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


// var client = host.Services.GetRequiredService<IClusterClient>();
// var player = client.GetGrain<IPlayerGrain>(Guid.NewGuid());
// await player.SetName(name);

// var room1 = client.GetGrain<IRoomGrain>(0);
// await player.SetRoomGrain(room1);

// Console.WriteLine(await player.Play("look"));

// var result = "Start";
// try
// {
//     while (result is not "")
//     {
//         var command = Console.ReadLine()!;

//         result = await player.Play(command);
//         Console.WriteLine(result);
//     }
// }
// finally
// {
//     await player.Die();
//     Console.WriteLine("Game over!");
//     await host.StopAsync();
// }

