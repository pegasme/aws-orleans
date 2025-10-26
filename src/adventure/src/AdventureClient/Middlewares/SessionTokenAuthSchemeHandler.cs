using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Text.Encodings.Web;
using AdventureClient.Services.Interfaces;

namespace AdventureClient.Middlewares;

public class SessionTokenAuthSchemeHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private readonly IGameAuthorizationService _authorizationService;

    public SessionTokenAuthSchemeHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IGameAuthorizationService authorizationService)
        : base(options, logger, encoder)
    {
        _authorizationService = authorizationService ?? throw new ArgumentNullException(nameof(authorizationService));
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var endpoint = Context.GetEndpoint();
        if (endpoint?.Metadata?.GetMetadata<IAllowAnonymous>() != null)
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var token = Request.Headers["Authorization"].FirstOrDefault()?.Trim();

        if (string.IsNullOrEmpty(token))
        {
            return Task.FromResult(AuthenticateResult.Fail("Missing Authorization Header"));
        }
        
        var user = _authorizationService.IsAuthorized(token);

        if (user == null)
        {
            return Task.FromResult(AuthenticateResult.Fail("Unauthorized"));
        }

        var claims = new[] { new Claim(ClaimTypes.Name, "User") };
        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, this.Scheme.Name);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}