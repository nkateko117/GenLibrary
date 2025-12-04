using GenLibrary.Models.ViewModels;

namespace GenLibrary.Services
{
    public interface IAuthService
    {
        Task<LoginResult> LoginAsync(string email, string password);
        Task LogoutAsync();
        //Task<RegisterResult> RegisterAsync(RegisterVM model);
    }

}
