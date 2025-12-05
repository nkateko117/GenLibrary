namespace GenLibrary.Dtos
{
    public record DetailedBookDto
    {
        public int BookId { get; init; }
        public required string Title { get; init; }
        public string? ISBN { get; init; }
        public string?  Summary { get; init; }
        public int?  PublishedYear { get; init; }
        public int? TotalPages { get; init; }
        public DateTime CreatedAt { get; init; }
        public bool Active { get; init; }
        public string?  Authors { get; init; }
        public int TotalCopies { get; init; }
        public int AvailableCopies { get; init; }
    }
}
