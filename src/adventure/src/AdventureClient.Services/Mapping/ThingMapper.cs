using AdventureClient.Services.Models;
using AdventureGrainInterfaces;

namespace AdventureClient.Services.Mapping;

public static class ThingMapper
{
    public static ThingDto ToThingDto(this Thing thing)
    {
        return new ThingDto
        {
            Id = thing.Id,
            Name = thing.Name,
            Category = thing.Category,
            FoundIn = thing.FoundIn
        };
    }
}