using GenLibrary.Services;
using GenLibrary.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GenLibrary.Controllers
{
    [Authorize(Roles = "Member")]
    public class MemberController : Controller
    {
        private readonly ILibraryService _libraryService;
        private readonly IBookService _bookService;

        public MemberController(ILibraryService libraryService, IBookService bookService)
        {
            _libraryService = libraryService;
            _bookService = bookService;
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdClaim, out var userId) ? userId : Guid.Empty;
        }

        public async Task<IActionResult> Index()
        {
            return RedirectToAction(nameof(MyBooks));
        }

        public async Task<IActionResult> MyBooks()
        {
            var userId = GetCurrentUserId();
            var currentCheckouts = await _libraryService.GetCurrentCheckoutsByMemberAsync(userId);
            var history = await _libraryService.GetCheckoutHistoryByMemberAsync(userId);

            var vm = new MemberMyBooksVM
            {
                CurrentCheckouts = currentCheckouts,
                History = history,
                CurrentCount = currentCheckouts.Count
            };

            return View(vm);
        }

        public async Task<IActionResult> History()
        {
            var userId = GetCurrentUserId();
            var history = await _libraryService.GetCheckoutHistoryByMemberAsync(userId);
            return View(history);
        }

        [HttpGet]
        public async Task<IActionResult> Checkout(int bookId)
        {
            var userId = GetCurrentUserId();
            var currentCount = await _libraryService.GetCurrentCheckoutCountAsync(userId);
            var availableCopies = await _libraryService.GetAvailableCopiesAsync(bookId);

            var books = await _bookService.GetDetailedBookListAsync();
            var book = books.FirstOrDefault(b => b.BookId == bookId);

            var vm = new MemberCheckoutVM
            {
                Book = book,
                AvailableCopies = availableCopies,
                CurrentCheckoutCount = currentCount
            };

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [ActionName("Checkout")]
        public async Task<IActionResult> CheckoutConfirm(int copyId)
        {
            var userId = GetCurrentUserId();
            var (success, message) = await _libraryService.CheckoutBookAsync(copyId, userId);

            TempData["Message"] = message;
            TempData["Success"] = success;

            if (success)
                return RedirectToAction(nameof(MyBooks));

            return RedirectToAction("Index", "Books");
        }

        public async Task<IActionResult> BrowseBooks(string? title, string? isbn, string? author, bool availableOnly = false)
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
    }
}
