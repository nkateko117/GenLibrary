using GenLibrary.Data;
using GenLibrary.Dtos;
using Microsoft.Data.SqlClient;
using System.Data;

namespace GenLibrary.Services
{
    public class LibraryService : ILibraryService
    {
        private readonly IDal _dal;
        private readonly string _conn;

        public LibraryService(IDal dal, IConfiguration config)
        {
            _dal = dal;
            _conn = config.GetConnectionString("DefaultConnection");
        }

        public async Task<DashboardStatsDto> GetDashboardStatsAsync()
        {
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetLibrarianDashboardStats");
            if (await reader.ReadAsync())
            {
                return new DashboardStatsDto
                {
                    TotalBooks = reader.GetInt32(reader.GetOrdinal("TotalBooks")),
                    TotalCopies = reader.GetInt32(reader.GetOrdinal("TotalCopies")),
                    AvailableCopies = reader.GetInt32(reader.GetOrdinal("AvailableCopies")),
                    ActiveCheckouts = reader.GetInt32(reader.GetOrdinal("ActiveCheckouts")),
                    OverdueCount = reader.GetInt32(reader.GetOrdinal("OverdueCount")),
                    TotalMembers = reader.GetInt32(reader.GetOrdinal("TotalMembers"))
                };
            }
            return new DashboardStatsDto();
        }

        public async Task<List<MemberDto>> GetAllMembersAsync()
        {
            var results = new List<MemberDto>();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetAllMembers");
            while (await reader.ReadAsync())
            {
                results.Add(new MemberDto
                {
                    UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
                    UserName = reader["UserName"]?.ToString() ?? string.Empty,
                    Email = reader["Email"]?.ToString() ?? string.Empty,
                    FullName = reader["FullName"]?.ToString() ?? string.Empty,
                    CurrentCheckouts = reader.GetInt32(reader.GetOrdinal("CurrentCheckouts"))
                });
            }
            return results;
        }

        public async Task<int> GetCurrentCheckoutCountAsync(Guid userId)
        {
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetCurrentCheckoutCount",
                new SqlParameter("@UserId", userId));
            if (await reader.ReadAsync())
            {
                return reader.GetInt32(reader.GetOrdinal("CurrentCount"));
            }
            return 0;
        }

        public async Task<List<MemberCheckoutDto>> GetCurrentCheckoutsByMemberAsync(Guid userId)
        {
            var results = new List<MemberCheckoutDto>();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetCurrentCheckoutsByMember",
                new SqlParameter("@UserId", userId));
            while (await reader.ReadAsync())
            {
                results.Add(new MemberCheckoutDto
                {
                    CheckoutId = reader.GetInt32(reader.GetOrdinal("CheckoutId")),
                    CopyId = reader.GetInt32(reader.GetOrdinal("CopyId")),
                    BookId = reader.GetInt32(reader.GetOrdinal("BookId")),
                    BookTitle = reader["BookTitle"]?.ToString() ?? string.Empty,
                    Barcode = reader["Barcode"]?.ToString() ?? string.Empty,
                    UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
                    CheckoutDate = reader.GetDateTime(reader.GetOrdinal("CheckoutDate")),
                    DueDate = reader.GetDateTime(reader.GetOrdinal("DueDate")),
                    ReturnDate = reader["ReturnDate"] != DBNull.Value ? reader.GetDateTime(reader.GetOrdinal("ReturnDate")) : null,
                    IsOverdue = reader.GetInt32(reader.GetOrdinal("IsOverdue")) == 1,
                    DaysLeft = reader["DaysLeft"] != DBNull.Value ? reader.GetInt32(reader.GetOrdinal("DaysLeft")) : null
                });
            }
            return results;
        }

        public async Task<List<CheckoutHistoryDto>> GetCheckoutHistoryByMemberAsync(Guid userId)
        {
            var results = new List<CheckoutHistoryDto>();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetCheckoutHistoryByMember",
                new SqlParameter("@UserId", userId));
            while (await reader.ReadAsync())
            {
                results.Add(new CheckoutHistoryDto
                {
                    CheckoutId = reader.GetInt32(reader.GetOrdinal("CheckoutId")),
                    CopyId = reader.GetInt32(reader.GetOrdinal("CopyId")),
                    BookId = reader.GetInt32(reader.GetOrdinal("BookId")),
                    BookTitle = reader["BookTitle"]?.ToString() ?? string.Empty,
                    Barcode = reader["Barcode"]?.ToString() ?? string.Empty,
                    UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
                    CheckoutDate = reader.GetDateTime(reader.GetOrdinal("CheckoutDate")),
                    DueDate = reader.GetDateTime(reader.GetOrdinal("DueDate")),
                    ReturnDate = reader["ReturnDate"] != DBNull.Value ? reader.GetDateTime(reader.GetOrdinal("ReturnDate")) : null,
                    WasOverdue = reader.GetInt32(reader.GetOrdinal("WasOverdue")) == 1
                });
            }
            return results;
        }

        public async Task<List<LibrarianCheckoutDto>> GetAllCurrentCheckoutsAsync()
        {
            var results = new List<LibrarianCheckoutDto>();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetAllCurrentCheckouts");
            while (await reader.ReadAsync())
            {
                results.Add(new LibrarianCheckoutDto
                {
                    CheckoutId = reader.GetInt32(reader.GetOrdinal("CheckoutId")),
                    CopyId = reader.GetInt32(reader.GetOrdinal("CopyId")),
                    BookId = reader.GetInt32(reader.GetOrdinal("BookId")),
                    BookTitle = reader["BookTitle"]?.ToString() ?? string.Empty,
                    Barcode = reader["Barcode"]?.ToString() ?? string.Empty,
                    UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
                    MemberName = reader["MemberName"]?.ToString() ?? string.Empty,
                    MemberEmail = reader["MemberEmail"]?.ToString() ?? string.Empty,
                    CheckoutDate = reader.GetDateTime(reader.GetOrdinal("CheckoutDate")),
                    DueDate = reader.GetDateTime(reader.GetOrdinal("DueDate")),
                    ReturnDate = reader["ReturnDate"] != DBNull.Value ? reader.GetDateTime(reader.GetOrdinal("ReturnDate")) : null,
                    IsOverdue = reader.GetInt32(reader.GetOrdinal("IsOverdue")) == 1,
                    DaysLeft = reader["DaysLeft"] != DBNull.Value ? reader.GetInt32(reader.GetOrdinal("DaysLeft")) : null
                });
            }
            return results;
        }

        public async Task<List<OverdueCheckoutDto>> GetOverdueCheckoutsAsync()
        {
            var results = new List<OverdueCheckoutDto>();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetOverdueCheckouts");
            while (await reader.ReadAsync())
            {
                results.Add(new OverdueCheckoutDto
                {
                    CheckoutId = reader.GetInt32(reader.GetOrdinal("CheckoutId")),
                    CopyId = reader.GetInt32(reader.GetOrdinal("CopyId")),
                    BookId = reader.GetInt32(reader.GetOrdinal("BookId")),
                    BookTitle = reader["BookTitle"]?.ToString() ?? string.Empty,
                    Barcode = reader["Barcode"]?.ToString() ?? string.Empty,
                    UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
                    MemberName = reader["MemberName"]?.ToString() ?? string.Empty,
                    MemberEmail = reader["MemberEmail"]?.ToString() ?? string.Empty,
                    CheckoutDate = reader.GetDateTime(reader.GetOrdinal("CheckoutDate")),
                    DueDate = reader.GetDateTime(reader.GetOrdinal("DueDate")),
                    DaysOverdue = reader.GetInt32(reader.GetOrdinal("DaysOverdue"))
                });
            }
            return results;
        }

        public async Task<List<AvailableCopyDto>> GetAvailableCopiesAsync(int bookId)
        {
            var results = new List<AvailableCopyDto>();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetAvailableCopies",
                new SqlParameter("@BookId", bookId));
            while (await reader.ReadAsync())
            {
                results.Add(new AvailableCopyDto
                {
                    CopyId = reader.GetInt32(reader.GetOrdinal("CopyId")),
                    BookId = reader.GetInt32(reader.GetOrdinal("BookId")),
                    Barcode = reader["Barcode"]?.ToString() ?? string.Empty,
                    Condition = reader["Condition"]?.ToString() ?? string.Empty,
                    Title = reader["Title"]?.ToString() ?? string.Empty
                });
            }
            return results;
        }

        public async Task<(bool Success, string Message)> CheckoutBookAsync(int copyId, Guid userId)
        {
            var successParam = new SqlParameter("@Success", SqlDbType.Bit) { Direction = ParameterDirection.Output };
            var messageParam = new SqlParameter("@Message", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

            await _dal.ExecuteNonQueryAsync(_conn, "PROC_CheckoutBook",
                new SqlParameter("@CopyId", copyId),
                new SqlParameter("@UserId", userId),
                successParam,
                messageParam);

            return ((bool)successParam.Value, messageParam.Value?.ToString() ?? string.Empty);
        }

        public async Task<(bool Success, string Message)> ReturnBookAsync(int checkoutId)
        {
            var successParam = new SqlParameter("@Success", SqlDbType.Bit) { Direction = ParameterDirection.Output };
            var messageParam = new SqlParameter("@Message", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

            await _dal.ExecuteNonQueryAsync(_conn, "PROC_ReturnBook",
                new SqlParameter("@CheckoutId", checkoutId),
                successParam,
                messageParam);

            return ((bool)successParam.Value, messageParam.Value?.ToString() ?? string.Empty);
        }

        public async Task<List<AuthorDto>> GetAllAuthorsAsync()
        {
            var results = new List<AuthorDto>();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_GetAllAuthors");
            while (await reader.ReadAsync())
            {
                results.Add(new AuthorDto
                {
                    AuthorId = reader.GetInt32(reader.GetOrdinal("AuthorId")),
                    FirstName = reader["FirstName"]?.ToString() ?? string.Empty,
                    LastName = reader["LastName"]?.ToString() ?? string.Empty
                });
            }
            return results;
        }
    }
}
