namespace AdventureClient.Services.Interfaces;

public interface IAuthorizationService
{
    bool IsAuthorized(string key);

    string Authorize(string key, string name);
}