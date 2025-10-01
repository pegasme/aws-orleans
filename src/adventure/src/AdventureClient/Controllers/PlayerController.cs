using System;
using System.Threading.Tasks;
using AdventureGrainInterfaces;
using Microsoft.AspNetCore.Mvc;

namespace AdventureClient.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PlayerController : ControllerBase
    {
        private readonly IGrainFactory _grainFactory;

        public PlayerController(IGrainFactory grainFactory) => _grainFactory = grainFactory;

        // TODO check that player does not exists
        [HttpPost("create")]
        public async Task<IActionResult> CreatePlayer([FromBody] PlayerDto player)
        {
            var playerGrain = _grainFactory.GetGrain<IPlayerGrain>(Guid.NewGuid());
            await playerGrain.SetName(player.Name);

            var room1 = _grainFactory.GetGrain<IRoomGrain>(0);
            await playerGrain.SetRoomGrain(room1);

            return Ok();
        }
    }

    public class PlayerDto
    {
        public string Name { get; set; }
    }
}
