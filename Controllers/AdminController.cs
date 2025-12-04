using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    public class AdminController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
