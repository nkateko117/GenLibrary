namespace GenLibrary.Dtos
{
    public class AvailableCopyDto
    {
        public int CopyId { get; set; }
        public int BookId { get; set; }
        public string Barcode { get; set; } = string.Empty;
        public string Condition { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
    }
}
