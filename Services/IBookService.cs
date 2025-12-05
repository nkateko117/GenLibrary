using GenLibrary.Dtos;
using GenLibrary.Identity.Models;
using GenLibrary.Models.Dtos;

namespace GenLibrary.Services
{
    public interface IBookService
    {
        Task<List<DetailedBookDto>> GetDetailedBookListAsync();
        Task<List<BookCopyDetailedDto>> GetDetailedBookCopyListAsync(int? bookId);
    }
}
