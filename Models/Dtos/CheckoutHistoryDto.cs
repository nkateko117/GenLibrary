namespace GenLibrary.Dtos
{
    public class CheckoutHistoryDto
    {
        public int CheckoutId { get; set; }
        public int CopyId { get; set; }
        public int BookId { get; set; }
        public string BookTitle { get; set; } = string.Empty;
        public string Barcode { get; set; } = string.Empty;
        public Guid UserId { get; set; }
        public DateTime CheckoutDate { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime? ReturnDate { get; set; }
        public bool WasOverdue { get; set; }
    }
}
