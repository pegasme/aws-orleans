using AdventureClient.Services.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;

namespace AdventureClient.Services.Services;

public class GameAuthorizationService : IGameAuthorizationService
{
    private readonly IConfiguration _configuration;
    private readonly IMemoryCache _cache;

    public GameAuthorizationService(IConfiguration configuration, IMemoryCache cache)
    {
        _configuration = configuration;
        _cache = cache;
    }

    public bool IsAuthorized(string token)
    {
        var isAuthorised = _cache.TryGetValue<Guid>(token, out var authorizedKey);
        return isAuthorised && authorizedKey != Guid.Empty;
    }

    private bool IsKeyCorrect(string key)
    {
        var authorizedKey = _configuration["AUTHORIZATION_KEY"];
        return key == authorizedKey;
    }

    public string Authorize(string key, Guid id)
    {
        if (!IsKeyCorrect(key))
        {
            throw new UnauthorizedAccessException("Invalid authorization key.");
        }

        var token = Guid.NewGuid().ToString();
        _cache.Set(token, id, TimeSpan.FromHours(1)); // Cache the token with a 1-hour expiration
        return token;
    }
}