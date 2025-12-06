using GenLibrary.Dtos;

namespace GenLibrary.ViewModels
{
    public class MemberMyBooksVM
    {
        public List<MemberCheckoutDto> CurrentCheckouts { get; set; } = new();
        public List<CheckoutHistoryDto> History { get; set; } = new();
        public int CurrentCount { get; set; }
        public int RemainingCheckouts => 5 - CurrentCount;
    }
}
