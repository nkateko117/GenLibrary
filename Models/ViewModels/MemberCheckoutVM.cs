using GenLibrary.Dtos;

namespace GenLibrary.ViewModels
{
    public class MemberCheckoutVM
    {
        public DetailedBookDto Book { get; set; }
        public List<AvailableCopyDto> AvailableCopies { get; set; } = new();
        public int CurrentCheckoutCount { get; set; }
        public bool CanCheckout => CurrentCheckoutCount < 5 && AvailableCopies.Count > 0;
        public int RemainingCheckouts => 5 - CurrentCheckoutCount;
    }
}
