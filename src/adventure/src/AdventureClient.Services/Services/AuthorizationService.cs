using AdventureClient.Services.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;

namespace AdventureClient.Services.Services;

public class AuthorizationService : IAuthorizationService
{
    private readonly IConfiguration _configuration;
    private readonly IMemoryCache _cache;

    public AuthorizationService(IConfiguration configuration, IMemoryCache cache)
    {
        _configuration = configuration;
        _cache = cache;
    }

    public bool IsAuthorized(string key)
    {
        var authorizedKey = _configuration["AUTHORIZATION_KEY"];
        return key == authorizedKey;
    }

    public string Authorize(string key, string name)
    {
        if (!IsAuthorized(key))
        {
            throw new UnauthorizedAccessException("Invalid authorization key.");
        }

        var token = Guid.NewGuid().ToString();
        _cache.Set(token, name, TimeSpan.FromHours(1)); // Cache the token with a 1-hour expiration
        return token;
    }
}