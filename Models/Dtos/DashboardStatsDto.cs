namespace GenLibrary.Dtos
{
    public class DashboardStatsDto
    {
        public int TotalBooks { get; set; }
        public int TotalCopies { get; set; }
        public int AvailableCopies { get; set; }
        public int ActiveCheckouts { get; set; }
        public int OverdueCount { get; set; }
        public int TotalMembers { get; set; }

        public int CheckedOutCopies => TotalCopies - AvailableCopies;
    }
}
