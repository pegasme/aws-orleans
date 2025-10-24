using System.Net;
using AWSECS.ContainerMetadata.Contracts;
using Orleans.Configuration;
using Orleans.Hosting;
using Serilog;

namespace AdventureServer.Extensions;

public static class OrleansClusterExtensions
{
    public static IHostApplicationBuilder ConfigureCluster(this IHostApplicationBuilder builder, bool isDevelopment = false)
    {
        builder.UseOrleans(siloBuilder =>
        {
            siloBuilder.AddDynamoDBGrainStorageAsDefault(options =>
                {
                    options.TableName = builder.Configuration["GrainTableName"];
                    options.TimeToLive = TimeSpan.FromDays(5);
                    options.Service = builder.Configuration["AWS_REGION"];
                    options.CreateIfNotExists = false;
                });

                siloBuilder
                    .Configure<EndpointOptions>(options =>
                    {
                        var awsContainerMetadataService= builder.Services.BuildServiceProvider().GetRequiredService<IAWSContainerMetadata>();

                        var awsContainerMetadata = awsContainerMetadataService.GetContainerMetadata();
                        var siloPort = awsContainerMetadata?.Ports?.FirstOrDefault(p => p.ContainerPort == EndpointOptions.DEFAULT_SILO_PORT)?.HostPort ?? EndpointOptions.DEFAULT_SILO_PORT;
                        var gatewayPort = awsContainerMetadata?.Ports?.FirstOrDefault(p => p.ContainerPort == EndpointOptions.DEFAULT_GATEWAY_PORT)?.HostPort ?? EndpointOptions.DEFAULT_GATEWAY_PORT;
                        var advertisedIPAddress = awsContainerMetadataService.GetHostPrivateIPv4Address() ?? Dns.GetHostAddresses(Dns.GetHostName()).First();
                
                        options.SiloPort = 11111;
                        options.GatewayPort = 30000;
                        options.GatewayListeningEndpoint = new IPEndPoint(IPAddress.Any, EndpointOptions.DEFAULT_GATEWAY_PORT);
                        options.SiloListeningEndpoint = new IPEndPoint(IPAddress.Any, EndpointOptions.DEFAULT_SILO_PORT);
                    })
                    .Configure<ClusterOptions>(options =>
                    {
                        options.ClusterId = builder.Configuration["ORLEANS_CLUSTER_ID"] ?? "dev";
                        options.ServiceId = builder.Configuration["ORLEANS_SERVICE_ID"] ?? "AdventureApp";
                    })
                    .ConfigureLogging(logging => logging.AddConsole());

                if (isDevelopment)
                {
                    siloBuilder.UseLocalhostClustering();
                }
                else
                {
                    siloBuilder.UseDynamoDBClustering(options =>
                    {
                        options.TableName = builder.Configuration["ClusterTableName"];
                        options.Service = builder.Configuration["AWS_REGION"];
                        options.CreateIfNotExists = false;
                    });
                }
            });
        return builder;
    }
}