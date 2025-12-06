namespace GenLibrary.Dtos
{
    public class OverdueCheckoutDto
    {
        public int CheckoutId { get; set; }
        public int CopyId { get; set; }
        public int BookId { get; set; }
        public string BookTitle { get; set; } = string.Empty;
        public string Barcode { get; set; } = string.Empty;
        public Guid UserId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public string MemberEmail { get; set; } = string.Empty;
        public DateTime CheckoutDate { get; set; }
        public DateTime DueDate { get; set; }
        public int DaysOverdue { get; set; }
    }
}
