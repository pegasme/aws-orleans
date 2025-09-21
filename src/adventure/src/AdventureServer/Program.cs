using System.Net;
using System.Reflection;
using AdventureSetup;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Microsoft.Orleans.Clustering.DynamoDB;
using Orleans.Configuration;


// Configure the host
using var host = Host.CreateDefaultBuilder(args)
    .ConfigureWebHostDefaults(webBuilder =>
    {
        webBuilder.UseStartup<Startup>();
    })
    .UseOrleans(siloBuilder =>
    {
        siloBuilder.UseDynamoDBClustering(options =>
        {
            options.Services = "http://localhost:4566";
        });
        siloBuilder.AddDynamoDBGrainStorageAsDefault(options =>
        {
            options.Services = "http://localhost:4566";
            options.UseJson = true;
        });

        siloBuilder.Configure<EndpointOptions>(options =>
        {
            options.AdvertisedIPAddress = IPAddress.Loopback;
            options.GatewayListeningEndpoint = new IPEndPoint(IPAddress.Any, EndpointOptions.DEFAULT_GATEWAY_PORT);
            options.SiloListeningEndpoint = new IPEndPoint(IPAddress.Any, EndpointOptions.DEFAULT_SILO_PORT);
        });
    })
    .Build();

// Start the host
await host.StartAsync();


// Initialize the game world
var client = host.Services.GetRequiredService<IGrainFactory>();
var adventure = new AdventureGame(client);
await adventure.Configure(mapFileName);

Console.WriteLine("Setup completed.");
Console.WriteLine("Now you can launch the client.");

// Exit when any key is pressed
Console.WriteLine("Press any key to exit.");
Console.ReadKey();
await host.StopAsync();

return 0;