using System;
using System.Threading.Tasks;
using AdventureGrainInterfaces;
using Microsoft.AspNetCore.Mvc;
using AdventureClient.Services.Models;
using AdventureClient.Services.Interfaces;

namespace AdventureClient.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PlayerController : ControllerBase
    {
        private readonly IPlayerService _playerService;

        public PlayerController(IPlayerService playerService) => _playerService = playerService;

        // TODO check that player does not exists
        [HttpPost("create")]
        public async Task<IActionResult> CreatePlayer([FromBody]CreatePlayerDto player)
        {
            var newPlayer = await _playerService.CreatePlayer(player);
            return Ok(newPlayer);
        }

        [HttpGet("{playerId}")]
        public async Task<IActionResult> GetPlayer(Guid playerId)
        { 
            var player = await _playerService.GetPlayer(playerId);

            if (player == null)
            {
                return NotFound();
            }

            return Ok(player);
        }
    }
}
