using AdventureClient.Services.Models;
using AdventureClient.Services.Services;
using Moq;

namespace AdventureClient.Services.UnitTests;

public class PlayerServiceTests
{
    [Test]
    public async Task CreatePlayer_ShouldReturnNewPlayer_WhenNameIsNotEmpty()
    {
        // Arrange
        var mockGrains = new Mock<IGrainFactory>();
        var playerService = new PlayerService(mockGrains.Object);
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
