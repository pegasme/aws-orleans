namespace AdventureServer.Cluster;

public class AdventureGameStartupTask : IStartupTask
{
    private readonly IGrainFactory _grainFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AdventureGameStartupTask> _logger;

    public AdventureGameStartupTask(IGrainFactory grainFactory, IConfiguration configuration,
        ILogger<AdventureGameStartupTask> logger)
    {
        _grainFactory = grainFactory;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task Execute(CancellationToken stoppingToken)
    {
         try
         {
            _logger.LogInformation("Starting game...");
             var adventureGame = new AdventureGame(_grainFactory);

            var currectDirectory = Directory.GetCurrentDirectory();
            var gameFile = Path.Combine(currectDirectory, _configuration["GameFile"] ?? "AdventureMap.json");
            await adventureGame.Configure(gameFile);
            _logger.LogInformation("Game started successfully.");
        }
        catch(Exception ex)
        {
            _logger.LogError(ex, "An error occurred in the game service.");
        }
    }
}
