namespace AdventureClient.Services.Models;

public class CreatePlayerResult
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public string AuthToken { get; set; }
}