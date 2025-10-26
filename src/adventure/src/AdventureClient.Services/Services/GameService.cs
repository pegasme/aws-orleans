using AdventureGrainInterfaces;
using AdventureClient.Services.Mapping;
using AdventureClient.Services.Models;
using AdventureClient.Services.Interfaces;

namespace AdventureClient.Services.Services;

public class GameService : IGameService
{
    private readonly IGrainFactory _grainFactory;

    public GameService(IGrainFactory grainFactory) => _grainFactory = grainFactory;

    public async Task<GameStateDto> GoAsync(Guid playerId, string direction)
    {
        var room1 = _grainFactory.GetGrain<IRoomGrain>(0);
        // await player.SetRoomGrain(room1);

        var playerGrain = _grainFactory.GetGrain<IPlayerGrain>(playerId);

        return new GameStateDto();
    }

    public async Task KillAsync()
    {
        throw new NotImplementedException();
    }

    public async Task TakeAsync()
    {

    }
}