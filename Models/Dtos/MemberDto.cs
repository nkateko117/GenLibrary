namespace GenLibrary.Dtos
{
    public class MemberDto
    {
        public Guid UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public int CurrentCheckouts { get; set; }

        public bool CanCheckoutMore => CurrentCheckouts < 5;
        public int RemainingCheckouts => 5 - CurrentCheckouts;
    }
}
