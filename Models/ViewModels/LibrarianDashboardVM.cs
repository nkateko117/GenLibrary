using GenLibrary.Dtos;

namespace GenLibrary.ViewModels
{
    public class LibrarianDashboardVM
    {
        public DashboardStatsDto Stats { get; set; } = new();
        public List<OverdueCheckoutDto> RecentOverdue { get; set; } = new();
    }
}
