using GenLibrary.Services;
using GenLibrary.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    public class BooksController : Controller
    {
        private readonly IBookService _bookServices;

        public BooksController(IBookService bookServices)
        {
            _bookServices = bookServices;
        }

        public async Task<IActionResult> Index(string? title, string? isbn, string? author, bool availableOnly = false)
        {
            var books = await _bookServices.GetDetailedBookListAsync();

            // Filtering Logic
            if (!string.IsNullOrWhiteSpace(title))
                books = books
                    .Where(b => b.Title.Contains(title, StringComparison.OrdinalIgnoreCase))
                    .ToList();

            if (!string.IsNullOrWhiteSpace(isbn))
                books = books
                    .Where(b => b.ISBN.Contains(isbn, StringComparison.OrdinalIgnoreCase))
                    .ToList();

            if (!string.IsNullOrWhiteSpace(author))
                books = books
                    .Where(b => b.Authors.Contains(author, StringComparison.OrdinalIgnoreCase))
                    .ToList();

            if (availableOnly)
                books = books
                    .Where(b => b.AvailableCopies > 0)
                    .ToList();

            var vm = new BooksViewModel
            {
                Books = books,
                Title = title,
                ISBN = isbn,
                Author = author,
                AvailableOnly = availableOnly
            };

            return View(vm);
        }

        public async Task<IActionResult> Copies(int bookId, string title)
        {
            var copies = await _bookServices.GetDetailedBookCopyListAsync(bookId);
            ViewBag.BookTitle = title;
            return View(copies);
        }
    }
}
