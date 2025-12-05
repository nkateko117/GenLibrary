using GenLibrary.Data;
using GenLibrary.Dtos;
using GenLibrary.Identity.Models;
using GenLibrary.Models.Dtos;
using Microsoft.Data.SqlClient;

namespace GenLibrary.Services
{
    public class BookService : IBookService
    {
        private readonly IDal _dal;
        private readonly string _conn;
        public BookService(IDal dal, IConfiguration config) 
        {
            _dal = dal;
            _conn = config.GetConnectionString("DefaultConnection");
        }

        public async Task<List<DetailedBookDto>> GetDetailedBookListAsync()
        {
            var results = new List<DetailedBookDto>();

            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetDetailedBooks");
            while (await reader.ReadAsync())
            {
                var dto = MapDetailedBook(reader);
                results.Add(dto);
            }

            return results;
        }

        public async Task<DetailedBookDto> GetDetailedBookById(int bookId)
        {
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetDetailedBook_ById", new SqlParameter("@BookId", bookId));
            if (await reader.ReadAsync())
            {
                return MapDetailedBook(reader);
            }

            return null;
        }

        public async Task<List<BookCopyDetailedDto>> GetDetailedBookCopyListAsync(int? bookId)
        {
            var results = new List<BookCopyDetailedDto>();

            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetBookCopies", new SqlParameter("@BookId", bookId));
            while (await reader.ReadAsync())
            {
                var dto = MapBookCopy(reader);
                results.Add(dto);
            }

            return results;
        }

        private DetailedBookDto MapDetailedBook(SqlDataReader reader)
        {
            var book = new DetailedBookDto
            {
                BookId = int.Parse(reader["BookId"].ToString()),
                Title = reader["Title"]?.ToString(),
                ISBN = reader["ISBN"]?.ToString(),
                Summary = reader["Summary"]?.ToString(),
                PublishedYear = int.Parse(reader["PublishedYear"].ToString()),
                TotalPages = int.Parse(reader["TotalPages"].ToString()),
                CreatedAt = DateTime.Parse(reader["CreatedAt"].ToString()),
                Authors = reader["Authors"]?.ToString(),
                TotalCopies = int.Parse(reader["TotalCopies"].ToString()),
                AvailableCopies = int.Parse(reader["AvailableCopies"].ToString())
            };
            return book;
        }

        private BookCopyDetailedDto MapBookCopy(SqlDataReader reader)
        {
            int? defInt = null;
            DateTime? defDate = null;
            bool? defBool = null;
            Guid? defGuid = null;

            var copy = new BookCopyDetailedDto
            {
                CopyId = int.Parse(reader["CopyId"].ToString()),
                BookId = int.Parse(reader["BookId"].ToString()),
                Barcode = reader["Barcode"]?.ToString() ?? string.Empty,
                AcquisitionDate = DateTime.Parse(reader["AcquisitionDate"].ToString()),
                Condition = reader["Condition"]?.ToString() ?? string.Empty,
                Status = int.Parse(reader["Status"].ToString()),
                StatusName = reader["StatusName"]?.ToString() ?? string.Empty,
                Title = reader["Title"]?.ToString() ?? string.Empty,

                CheckoutDate = reader["CheckoutDate"] != DBNull.Value ? DateTime.Parse(reader["CheckoutDate"].ToString()) : defDate,
                DueDate = reader["DueDate"] != DBNull.Value ? DateTime.Parse(reader["DueDate"].ToString()) : defDate,
                IsMarkedReturned = reader["IsMarkedReturned"] != DBNull.Value ? bool.Parse(reader["IsMarkedReturned"].ToString()) : defBool,

                UserId = reader["UserId"] != DBNull.Value ? Guid.Parse(reader["UserId"].ToString()) : defGuid,
                UserFullName = reader["MemberFullName"] != DBNull.Value ? reader["MemberFullName"].ToString() : string.Empty,

                DaysLeft = reader["DaysLeft"] != DBNull.Value ? int.Parse(reader["DaysLeft"].ToString()) : defInt
            };

            return copy;
        }
    }
}
