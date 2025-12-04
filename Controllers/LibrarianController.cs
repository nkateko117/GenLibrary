using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    public class LibrarianController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
