using GenLibrary.Models;
using GenLibrary.Services;
using GenLibrary.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace GenLibrary.Controllers
{
    [Authorize]
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
                    .Where(b => b.ISBN != null && b.ISBN.Contains(isbn, StringComparison.OrdinalIgnoreCase))
                    .ToList();

            if (!string.IsNullOrWhiteSpace(author))
                books = books
                    .Where(b => b.Authors != null && b.Authors.Contains(author, StringComparison.OrdinalIgnoreCase))
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

        [AllowAnonymous]
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
