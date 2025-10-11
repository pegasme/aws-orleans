using AdventureClient.Services.Models;
using AdventureGrainInterfaces;

namespace AdventureClient.Services.Mapping;

public static class PlayerMapping
{
    public static PlayerDto ToPlayerDto(this IPlayerGrain playerGrain, Guid playerId, string name)
    {
        return new PlayerDto
        {
            Id = playerId,
            Name = name
        };
    }
}