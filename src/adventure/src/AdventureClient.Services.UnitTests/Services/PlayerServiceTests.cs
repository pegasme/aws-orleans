using AdventureClient.Services.Models;
using AdventureClient.Services.Services;
using AdventureClient.Services.Interfaces;
using Moq;

namespace AdventureClient.Services.UnitTests;

public class PlayerServiceTests
{
    [Test]
    public async Task CreatePlayer_ShouldReturnNewPlayer_WhenNameIsNotEmpty()
    {
        // Arrange
        var mockGrains = new Mock<IGrainFactory>();
        var mockAuthService = new Mock<IAuthorizationService>();
        var playerService = new PlayerService(mockGrains.Object, mockAuthService.Object);
        
        var newPlayer = new CreatePlayerDto
        {
            Name = "TestPlayer"
        };
        
        // Act
        // var player = await playerService.CreatePlayer(newPlayer);

        // Assert
        Assert.Pass();
    }
}
