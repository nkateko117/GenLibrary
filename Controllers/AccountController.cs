using GenLibrary.Identity.Models;
using GenLibrary.Models.ViewModels;
using GenLibrary.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    [AllowAnonymous]
    public class AccountController : Controller
    {
        private readonly IAuthService _authService;

        public AccountController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpGet] public IActionResult Login(string returnUrl = null) => View(new LoginVM { ReturnUrl = returnUrl });

        [HttpPost]
        public async Task<IActionResult> Login(LoginVM model)
        {
            var result = await _authService.LoginAsync(model.Email, model.Password);

            if (!result.Succeeded)
            {
                ModelState.AddModelError("", result.Error);
                return View(model);
            }

            // Redirect based on role
            return RedirectToAction("RedirectByRole");
        }

        [Authorize]
        public async Task<IActionResult> RedirectByRole()
        {
            if (User.IsInRole("Librarian"))
                return RedirectToAction("Dashboard", "Librarian");
            
            if (User.IsInRole("Member"))
                return RedirectToAction("MyBooks", "Member");
            
            // Default fallback
            return RedirectToAction("Index", "Books");
        }

        [HttpPost] public async Task<IActionResult> Logout() { await _authService.LogoutAsync(); return Redirect("/"); }

        public IActionResult Register()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Register(RegisterVM model)
        {
            if (ModelState.IsValid)
            {
                
                ViewBag.Message = "Registration successful!";
                return View("RegistrationSuccess");
            }
            return View(model);
        }

        [HttpGet]
        public IActionResult AccessDenied()
        {
            return View();
        }
    }

}
