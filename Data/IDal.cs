using Microsoft.Data.SqlClient;
using System.Data;

namespace GenLibrary.Data
{
    public interface IDal
    {
        Task<IDataReader> ExecuteReaderAsync(string connectionString, string storedProc, params SqlParameter[] parameters);
        Task<int> ExecuteNonQueryAsync(string connectionString, string storedProc, params SqlParameter[] parameters);
        Task<object> ExecuteScalarAsync(string connectionString, string storedProc, params SqlParameter[] parameters);
    }

}
