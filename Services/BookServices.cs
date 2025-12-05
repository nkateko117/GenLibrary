using GenLibrary.Data;
using GenLibrary.Dtos;
using GenLibrary.Identity.Models;
using Microsoft.Data.SqlClient;

namespace GenLibrary.Services
{
    public class BookServices : IBookServices
    {
        private readonly IDal _dal;
        private readonly string _conn;
        public BookServices(IDal dal, IConfiguration config) 
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
    }
}
