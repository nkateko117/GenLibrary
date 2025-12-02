namespace GenLibrary.Dtos
{
    public class BookCopyDto
    {
        public int CopyId { get; set; }
        public int BookId { get; set; }
        public string Barcode { get; set; }
        public int Status { get; set; } // 0=Available
    }
}
