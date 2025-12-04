using GenLibrary.Identity.Models;
using GenLibrary.Models.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    [AllowAnonymous]
    public class AccountController : Controller
    {
        private readonly SignInManager<AppUser> _signInManager;
        private readonly UserManager<AppUser> _userManager;

        public AccountController(SignInManager<AppUser> signInManager, UserManager<AppUser> userManager)
        {
            _signInManager = signInManager;
            _userManager = userManager;
        }

        [HttpGet] public IActionResult Login(string returnUrl = null) => View(new LoginVM { ReturnUrl = returnUrl });

        [HttpPost]
        public async Task<IActionResult> Login(LoginVM vm)
        {
            if (!ModelState.IsValid) return View(vm);
            var user = await _userManager.FindByNameAsync(vm.Username.ToUpperInvariant());
            if (user == null) { ModelState.AddModelError("", "Invalid credentials"); return View(vm); }

            var result = await _signInManager.PasswordSignInAsync(user, vm.Password, vm.RememberMe, lockoutOnFailure: false);
            if (result.Succeeded) return Redirect(vm.ReturnUrl ?? "/");
            ModelState.AddModelError("", "Invalid credentials");
            return View(vm);
        }

        [HttpPost] public async Task<IActionResult> Logout() { await _signInManager.SignOutAsync(); return Redirect("/"); }
    }

}
