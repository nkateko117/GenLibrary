using GenLibrary.Services;
using GenLibrary.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GenLibrary.Controllers
{
    [Authorize(Roles = "Librarian")]
    public class LibrarianController : Controller
    {
        private readonly ILibraryService _libraryService;
        private readonly IBookService _bookService;

        public LibrarianController(ILibraryService libraryService, IBookService bookService)
        {
            _libraryService = libraryService;
            _bookService = bookService;
        }

        public async Task<IActionResult> Index()
        {
            return RedirectToAction(nameof(Dashboard));
        }

        public async Task<IActionResult> Dashboard()
        {
            var stats = await _libraryService.GetDashboardStatsAsync();
            var overdue = await _libraryService.GetOverdueCheckoutsAsync();

            var vm = new LibrarianDashboardVM
            {
                Stats = stats,
                RecentOverdue = overdue.Take(5).ToList()
            };

            return View(vm);
        }

        public async Task<IActionResult> ManageBooks(string? title, string? isbn, string? author, bool availableOnly = false)
        {
            var books = await _bookService.GetDetailedBookListAsync();

            if (!string.IsNullOrWhiteSpace(title))
                books = books.Where(b => b.Title.Contains(title, StringComparison.OrdinalIgnoreCase)).ToList();

            if (!string.IsNullOrWhiteSpace(isbn))
                books = books.Where(b => b.ISBN?.Contains(isbn, StringComparison.OrdinalIgnoreCase) == true).ToList();

            if (!string.IsNullOrWhiteSpace(author))
                books = books.Where(b => b.Authors?.Contains(author, StringComparison.OrdinalIgnoreCase) == true).ToList();

            if (availableOnly)
                books = books.Where(b => b.AvailableCopies > 0).ToList();

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

        public async Task<IActionResult> Checkouts()
        {
            var checkouts = await _libraryService.GetAllCurrentCheckoutsAsync();
            return View(checkouts);
        }

        public async Task<IActionResult> Returns()
        {
            var checkouts = await _libraryService.GetAllCurrentCheckoutsAsync();
            return View(checkouts);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> MarkReturned(int checkoutId)
        {
            var (success, message) = await _libraryService.ReturnBookAsync(checkoutId);
            TempData["Message"] = message;
            TempData["Success"] = success;
            return RedirectToAction(nameof(Returns));
        }

        public async Task<IActionResult> Overdue()
        {
            var overdueCheckouts = await _libraryService.GetOverdueCheckoutsAsync();
            return View(overdueCheckouts);
        }

        public async Task<IActionResult> CheckoutBook(int? bookId)
        {
            var members = await _libraryService.GetAllMembersAsync();

            var vm = new CheckoutBookVM
            {
                Members = members
            };

            if (bookId.HasValue)
            {
                var copies = await _libraryService.GetAvailableCopiesAsync(bookId.Value);
                vm.BookId = bookId.Value;
                vm.BookTitle = copies.FirstOrDefault()?.Title ?? string.Empty;
                vm.AvailableCopies = copies;
            }

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CheckoutBook(int copyId, Guid memberId)
        {
            var (success, message) = await _libraryService.CheckoutBookAsync(copyId, memberId);
            TempData["Message"] = message;
            TempData["Success"] = success;

            if (success)
                return RedirectToAction(nameof(Checkouts));

            return RedirectToAction(nameof(CheckoutBook));
        }

        [HttpGet]
        public async Task<IActionResult> GetAvailableCopies(int bookId)
        {
            var copies = await _libraryService.GetAvailableCopiesAsync(bookId);
            return Json(copies);
        }

        public async Task<IActionResult> Members()
        {
            var members = await _libraryService.GetAllMembersAsync();
            return View(members);
        }
    }
}
