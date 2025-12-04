namespace GenLibrary.Models.ViewModels
{
    public class LoginResult
    {
        public bool Succeeded { get; set; }
        public string Error { get; set; }

        public static LoginResult Success() =>
            new LoginResult { Succeeded = true };

        public static LoginResult Fail(string error) =>
            new LoginResult { Succeeded = false, Error = error };
    }

}
