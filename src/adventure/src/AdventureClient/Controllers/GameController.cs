using System;
using System.Threading.Tasks;
using AdventureGrainInterfaces;
using Microsoft.AspNetCore.Mvc;
using AdventureClient.Services.Models;
using AdventureClient.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;

namespace AdventureClient.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class GameController : ControllerBase
{
    private readonly IGameService _gameService;

    public GameController(IGameService gameService)
    {
        _gameService = gameService;
    }

    [HttpPost("go/{playerId}/{direction}")]
    public async Task<IActionResult> Go(Guid playerId, string direction)
    {
        var gameState = await _gameService.GoAsync(playerId, direction);
        return Ok(gameState);
    }

    [HttpPost("kill")]
    public async Task<IActionResult> Kill(Guid playerId)
    {
        await _gameService.KillAsync();
        return Ok();
    }

    [HttpPost("take")]
    public async Task<IActionResult> Take(Guid playerId)
    {
        await _gameService.TakeAsync();
        return Ok();
    }
}