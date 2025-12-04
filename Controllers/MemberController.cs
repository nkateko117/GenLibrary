using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    public class MemberController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
