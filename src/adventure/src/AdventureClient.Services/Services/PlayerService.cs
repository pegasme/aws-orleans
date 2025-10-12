using AdventureClient.Services.Interfaces;
using AdventureClient.Services.Mapping;
using AdventureClient.Services.Models;
using AdventureGrainInterfaces;

namespace AdventureClient.Services.Services;

public class PlayerService : IPlayerService
{
    private readonly IGrainFactory _grainFactory;

    public PlayerService(IGrainFactory grainFactory) => _grainFactory = grainFactory;

    public async Task<PlayerDto> CreatePlayer(CreatePlayerDto player)
    {
        var newId = Guid.NewGuid();
        var playerGrain = _grainFactory.GetGrain<IPlayerGrain>(newId);
        await playerGrain.SetName(player.Name);

        var room1 = _grainFactory.GetGrain<IRoomGrain>(0);
        await playerGrain.SetRoomGrain(room1);

        return playerGrain.ToPlayerDto(newId, player.Name);
    }

    public async Task<PlayerDto?> GetPlayer(Guid playerId)
    {
        var playerGrain = _grainFactory.GetGrain<IPlayerGrain>(playerId);

        if (playerGrain == null)
        {
            return null;
        }

        var name = await playerGrain.Name();
        return new PlayerDto
        {
            Id = playerId,
            Name = name
        };
    }
}