namespace AdventureClient.Services.Models;

public class InventoryDto
{
    public Guid Id { get; set; }
    public List<ThingDto> Items { get; set; } = new();
}