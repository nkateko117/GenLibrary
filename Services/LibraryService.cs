using GenLibrary.Data;

namespace GenLibrary.Services
{
    public class LibraryService : ILibraryService
    {
        private readonly IDal _dal;

        public LibraryService(IDal dal)
        {
            _dal = dal;
        }

        public async Task<IEnumerable<Book>> GetBooksAsync(int? authorId = null)
        {
            var parameters = authorId.HasValue
                ? new SqlParameter[] { new SqlParameter("@AuthorId", authorId.Value) }
                : Array.Empty<SqlParameter>();

            using var reader = await _dal.ExecuteReaderAsync("PROC_GET_BOOKS", parameters);
            var books = new List<Book>();

            while (await reader.ReadAsync())
            {
                books.Add(new Book
                {
                    BookId = (int)reader["BookId"],
                    Title = reader["Title"].ToString(),
                    AuthorId = (int)reader["AuthorId"],
                    AuthorName = reader["AuthorName"].ToString(),
                    IsAvailable = (bool)reader["IsAvailable"],
                    DueDate = reader["DueDate"] != DBNull.Value ? (DateTime?)reader["DueDate"] : null
                });
            }

            return books;
        }

        public async Task<bool> CheckoutBookAsync(int memberId, int bookId)
        {
            // 1. Check current checkout count
            using var reader = await _dal.ExecuteReaderAsync(
                "PROC_GET_CURRENT_CHECKOUT_COUNT",
                new SqlParameter("@MemberId", memberId)
            );
            int currentCount = 0;
            if (await reader.ReadAsync())
                currentCount = (int)reader[0];

            if (currentCount >= 5)
                return false; // cannot checkout more than 5

            // 2. Call stored procedure to checkout
            await _dal.ExecuteReaderAsync(
                "PROC_CHECKOUT_BOOK",
                new SqlParameter("@MemberId", memberId),
                new SqlParameter("@BookId", bookId)
            );

            return true;
        }

        public async Task<bool> ReturnBookAsync(int checkoutId)
        {
            await _dal.ExecuteReaderAsync(
                "PROC_RETURN_BOOK",
                new SqlParameter("@CheckoutId", checkoutId)
            );
            return true;
        }

        public async Task<IEnumerable<Checkout>> GetCheckoutsByMemberAsync(int memberId)
        {
            using var reader = await _dal.ExecuteReaderAsync(
                "PROC_GET_CHECKOUTS_BY_MEMBER",
                new SqlParameter("@MemberId", memberId)
            );

            var list = new List<Checkout>();
            while (await reader.ReadAsync())
            {
                list.Add(new Checkout
                {
                    CheckoutId = (int)reader["CheckoutId"],
                    BookId = (int)reader["BookId"],
                    MemberId = (int)reader["MemberId"],
                    CheckoutDate = (DateTime)reader["CheckoutDate"],
                    DueDate = (DateTime)reader["DueDate"],
                    ReturnDate = reader["ReturnDate"] != DBNull.Value ? (DateTime?)reader["ReturnDate"] : null
                });
            }
            return list;
        }

        public async Task<IEnumerable<Member>> GetMembersAsync()
        {
            using var reader = await _dal.ExecuteReaderAsync("PROC_GET_MEMBERS");
            var members = new List<Member>();
            while (await reader.ReadAsync())
            {
                members.Add(new Member
                {
                    MemberId = (int)reader["MemberId"],
                    FullName = reader["FullName"].ToString(),
                    Email = reader["Email"].ToString()
                });
            }
            return members;
        }
    }
}
