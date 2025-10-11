using AdventureClient.Services.Models;

namespace AdventureClient.Services.Interfaces;

public interface IPlayerService
{
    Task<PlayerDto> CreatePlayer(CreatePlayerDto player);
    
    Task<PlayerDto?> GetPlayer(Guid playerId);
}