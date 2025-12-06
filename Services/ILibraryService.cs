using GenLibrary.Dtos;

namespace GenLibrary.Services
{
    public interface ILibraryService
    {
        // Dashboard & Stats
        Task<DashboardStatsDto> GetDashboardStatsAsync();

        // Member operations
        Task<List<MemberDto>> GetAllMembersAsync();
        Task<int> GetCurrentCheckoutCountAsync(Guid userId);

        // Checkout operations
        Task<List<MemberCheckoutDto>> GetCurrentCheckoutsByMemberAsync(Guid userId);
        Task<List<CheckoutHistoryDto>> GetCheckoutHistoryByMemberAsync(Guid userId);
        Task<List<LibrarianCheckoutDto>> GetAllCurrentCheckoutsAsync();
        Task<List<OverdueCheckoutDto>> GetOverdueCheckoutsAsync();

        // Book copy operations
        Task<List<AvailableCopyDto>> GetAvailableCopiesAsync(int bookId);

        // Checkout/Return actions
        Task<(bool Success, string Message)> CheckoutBookAsync(int copyId, Guid userId);
        Task<(bool Success, string Message)> ReturnBookAsync(int checkoutId);

        // Author operations
        Task<List<AuthorDto>> GetAllAuthorsAsync();
    }
}
