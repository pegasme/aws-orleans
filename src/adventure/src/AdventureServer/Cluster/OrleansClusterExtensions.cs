using System.Net;
using AWSECS.ContainerMetadata.Contracts;
using Orleans.Configuration;
using Orleans.Hosting;
using Serilog;

namespace AdventureServer.Cluster;

public static class OrleansClusterExtensions
{
    public static IHostApplicationBuilder ConfigureCluster(this IHostApplicationBuilder builder, bool isDevelopment = false)
    {
        builder.UseOrleans(siloBuilder =>
        {
            siloBuilder.AddDynamoDBGrainStorageAsDefault(options =>
                {
                    options.TableName = builder.Configuration["GRAIN_TABLE_NAME"];
                    options.TimeToLive = TimeSpan.FromDays(5);
                    options.Service = builder.Configuration["AWS_REGION"];
                    options.CreateIfNotExists = false;
                });

                siloBuilder
                    .Configure<EndpointOptions>(options =>
                    {
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
                        options.TableName = builder.Configuration["CLUSTER_TABLE_NAME"];
                        options.Service = builder.Configuration["AWS_REGION"];
                        options.CreateIfNotExists = false;
                    });
                }

                siloBuilder.AddStartupTask<AdventureGameStartupTask>();
            });
        return builder;
    }
}