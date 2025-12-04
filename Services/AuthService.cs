using GenLibrary.Identity.Models;
using GenLibrary.Models.ViewModels;
using Microsoft.AspNetCore.Identity;

namespace GenLibrary.Services
{
    public class AuthService : IAuthService
    {
        private readonly SignInManager<AppUser> _signInManager;
        private readonly UserManager<AppUser> _userManager;

        public AuthService(
            SignInManager<AppUser> signInManager,
            UserManager<AppUser> userManager)
        {
            _signInManager = signInManager;
            _userManager = userManager;
        }

        public async Task<LoginResult> LoginAsync(string email, string password)
        {
            var user = await _userManager.FindByEmailAsync(email);

            if (user == null)
                return LoginResult.Fail("User not found");

            var result = await _signInManager.PasswordSignInAsync(
                user,
                password,
                isPersistent: false,
                lockoutOnFailure: false
            );

            if (result.Succeeded)
                return LoginResult.Success();

            return LoginResult.Fail("Invalid password");
        }

        public async Task LogoutAsync()
        {
            await _signInManager.SignOutAsync();
        }

        //public async Task<RegisterResult> RegisterAsync(RegisterVM model)
        //{
        //    var user = new AppUser
        //    {
        //        UserName = model.Email,
        //        Email = model.Email,
        //        FullName = model.FullName
        //    };

        //    var result = await _userManager.CreateAsync(user, model.Password);

        //    if (!result.Succeeded)
        //        return RegisterResult.Fail(result.Errors.Select(x => x.Description).ToList());

        //    return RegisterResult.Success();
        //}
    }

}
