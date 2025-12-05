using GenLibrary.Services;
using GenLibrary.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    public class BooksController : Controller
    {
        private readonly IBookServices _bookServices;

        public BooksController(IBookServices bookServices)
        {
            _bookServices = bookServices;
        }

        public async Task<IActionResult> Index()
        {
            var allBooks = await _bookServices.GetDetailedBookListAsync();

            var vm = new BooksViewModel
            {
                Books = allBooks
            };

            return View(vm);
        }

        [HttpPost]
        public async Task<IActionResult> Filter(string? title, string? author)
        {
            var books = await _bookServices.GetDetailedBookListAsync();

            // Filtering Logic
            if (!string.IsNullOrWhiteSpace(title))
                books = books
                    .Where(b => b.Title.Contains(title, StringComparison.OrdinalIgnoreCase))
                    .ToList();

            if (!string.IsNullOrWhiteSpace(author))
                books = books
                    .Where(b => b.Authors.Contains(author, StringComparison.OrdinalIgnoreCase))
                    .ToList();

            return PartialView("_BookTable", books);
        }
    }
}
