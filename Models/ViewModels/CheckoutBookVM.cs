using GenLibrary.Dtos;

namespace GenLibrary.ViewModels
{
    public class CheckoutBookVM
    {
        public int BookId { get; set; }
        public string BookTitle { get; set; } = string.Empty;
        public List<AvailableCopyDto> AvailableCopies { get; set; } = new();
        public List<MemberDto> Members { get; set; } = new();
        
        public int? SelectedCopyId { get; set; }
        public Guid? SelectedMemberId { get; set; }
    }
}
