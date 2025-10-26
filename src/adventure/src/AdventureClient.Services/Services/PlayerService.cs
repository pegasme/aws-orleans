using AdventureClient.Services.Interfaces;
using AdventureClient.Services.Mapping;
using AdventureClient.Services.Models;
using AdventureGrainInterfaces;

namespace AdventureClient.Services.Services;

public class PlayerService : IPlayerService
{
    private readonly IGrainFactory _grainFactory;
    private readonly IAuthorizationService _authorizationService;

    public PlayerService(IGrainFactory grainFactory, IAuthorizationService authorizationService) 
    {
        _grainFactory = grainFactory ?? throw new ArgumentNullException(nameof(grainFactory)); 
        _authorizationService = authorizationService ?? throw new ArgumentNullException(nameof(authorizationService));
    }

    public async Task<CreatePlayerResult> CreatePlayerAsync(CreatePlayerDto player)
    {
        var authorizedToken = _authorizationService.Authorize(player.Key, player.Name);
        
        var newId = Guid.NewGuid();
        var playerGrain = _grainFactory.GetGrain<IPlayerGrain>(newId);
        await playerGrain.SetName(player.Name);

        var room1 = _grainFactory.GetGrain<IRoomGrain>(0);
        await playerGrain.SetRoomGrain(room1);

        return new CreatePlayerResult
        {
            Id = newId,
            Name = player.Name,
            AuthToken = authorizedToken
        };
    }

    public async Task<PlayerDto?> GetPlayerAsync(Guid playerId)
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

    public async Task<InventoryDto> GetPlayerInventoryAsync(Guid playerId)
    {
        var playerGrain = _grainFactory.GetGrain<IPlayerGrain>(playerId);

        if (playerGrain == null)
        {
            return null;
        }

        var inventory = await playerGrain.GetInventoryAsync();
        return new InventoryDto
        {
            Id = playerId,
            Items = inventory.Select(i => i.ToThingDto()).ToList()
        };
    }
}