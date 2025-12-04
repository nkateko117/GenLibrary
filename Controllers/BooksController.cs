using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    public class BooksController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
