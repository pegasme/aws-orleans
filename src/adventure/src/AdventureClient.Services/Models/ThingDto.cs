namespace AdventureClient.Services.Models;

public class ThingDto
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public long FoundIn { get; set; }
}