using AdventureClient.Services.Models;

namespace AdventureClient.Services.Interfaces;

public interface IPlayerService
{
    Task<CreatePlayerResult> CreatePlayerAsync(CreatePlayerDto player);

    Task<PlayerDto?> GetPlayerAsync(Guid playerId);
    
    Task<InventoryDto> GetPlayerInventoryAsync(Guid playerId);
}