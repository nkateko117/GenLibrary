using GenLibrary.Dtos;
using GenLibrary.Identity.Models;

namespace GenLibrary.Services
{
    public interface ILibraryService
    {
        Task<IEnumerable<BookDto>> GetBooksAsync(int? authorId = null);
        Task<IEnumerable<AppUser>> GetMembersAsync();
        Task<IEnumerable<CheckoutDto>> GetCheckoutsByMemberAsync(int memberId);
        Task<bool> CheckoutBookAsync(int memberId, int bookId);
        Task<bool> ReturnBookAsync(int checkoutId);
    }
}
