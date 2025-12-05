using GenLibrary.Dtos;

namespace GenLibrary.ViewModels
{
    public class BooksViewModel
    {
        public string? Title { get; set; }
        public string? Author { get; set; }

        public List<DetailedBookDto> Books { get; set; } = new();
    }
}
