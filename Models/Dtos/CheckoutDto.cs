namespace GenLibrary.Dtos
{
    public class CheckoutDto
    {
        public int CheckoutId { get; set; }
        public int CopyId { get; set; }
        public int BookId { get; set; }
        public string BookTitle { get; set; }
        public Guid UserId { get; set; } // or string if Identity uses string id
        public DateTime CheckoutDate { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime? ReturnDate { get; set; }
        public bool IsOverdue => ReturnDate == null && DateTime.UtcNow > DueDate;
    }
}
