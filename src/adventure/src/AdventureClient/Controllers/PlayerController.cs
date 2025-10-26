using System;
using System.Threading.Tasks;
using AdventureGrainInterfaces;
using Microsoft.AspNetCore.Mvc;
using AdventureClient.Services.Models;
using AdventureClient.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;

namespace AdventureClient.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class PlayerController : ControllerBase
    {
        private readonly IPlayerService _playerService;

        public PlayerController(IPlayerService playerService) 
        {
            _playerService = playerService;
        }

        [HttpPost("create")]
        [AllowAnonymous]
        public async Task<IActionResult> CreatePlayerAsync([FromBody]CreatePlayerDto player)
        {
            var newPlayer = await _playerService.CreatePlayerAsync(player);
            return Ok(newPlayer);
        }

        [HttpGet("get/{playerId}")]
        public async Task<IActionResult> GetPlayerAsync(Guid playerId)
        {
            var player = await _playerService.GetPlayerAsync(playerId);

            if (player == null)
            {
                return NotFound();
            }

            return Ok(player);
        }
        
        [HttpGet("inventory/{playerId}")]
        public async Task<IActionResult> GetPlayerInventoryAsync(Guid playerId)
        { 
            var inventory = await _playerService.GetPlayerInventoryAsync(playerId);

            if (inventory == null)
            {
                return NotFound();
            }

            return Ok(inventory);
        }
    }
}
