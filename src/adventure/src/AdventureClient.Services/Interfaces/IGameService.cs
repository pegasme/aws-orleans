using AdventureClient.Services.Models;

namespace AdventureClient.Services.Interfaces;

public interface IGameService
{
    Task<GameStateDto> GoAsync(Guid playerId, string direction);
    Task KillAsync();
    Task TakeAsync();
}