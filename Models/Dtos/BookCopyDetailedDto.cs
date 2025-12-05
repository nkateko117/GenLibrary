namespace GenLibrary.Models.Dtos
{
    public class BookCopyDetailedDto
    {
        public int CopyId { get; set; }
        public int BookId { get; set; }
        public string Barcode { get; set; }
        public DateTime AcquisitionDate { get; set; }
        public string Condition { get; set; }
        public int Status { get; set; }         // 1 = Available, 0 = Checked Out, -1 = Out of Commission
        public string StatusName { get; set; }  // "Available", "Checked Out", "Out of Commission"
        public string Title { get; set; }

        public DateTime? CheckoutDate { get; set; }
        public DateTime? DueDate { get; set; }
        public bool? IsMarkedReturned { get; set; }

        // Member info
        public Guid? UserId { get; set; }          // null if copy is available
        public string UserFullName { get; set; }   // null or empty if copy is available

        // Convenience properties
        public bool IsAvailable => Status == 1;
        public int? DaysLeft { get; set; }         // null if not checked out
    }
}
