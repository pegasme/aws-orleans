namespace AdventureClient.Services.Interfaces;

public interface IGameAuthorizationService
{
    bool IsAuthorized(string key);

    string Authorize(string key, Guid id);
}