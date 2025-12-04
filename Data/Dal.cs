using Microsoft.Data.SqlClient;
using System.Data;

namespace GenLibrary.Data
{
    public class Dal : IDal
    {
        public async Task<IDataReader> ExecuteReaderAsync(string connectionString, string storedProc, params SqlParameter[] parameters)
        {
            var conn = new SqlConnection(connectionString);
            var cmd = new SqlCommand(storedProc, conn) { CommandType = CommandType.StoredProcedure };
            if (parameters != null) cmd.Parameters.AddRange(parameters);
            await conn.OpenAsync();
            // DO NOT dispose connection here — caller must Dispose the IDataReader which will own the connection.
            var reader = await cmd.ExecuteReaderAsync(CommandBehavior.CloseConnection);
            return reader; // caller should using(var r = await dal.ExecuteReaderAsync(...)) { ... }
        }

        public async Task<int> ExecuteNonQueryAsync(string connectionString, string storedProc, params SqlParameter[] parameters)
        {
            using var conn = new SqlConnection(connectionString);
            using var cmd = new SqlCommand(storedProc, conn) { CommandType = CommandType.StoredProcedure };
            if (parameters != null) cmd.Parameters.AddRange(parameters);
            await conn.OpenAsync();
            return await cmd.ExecuteNonQueryAsync();
        }

        public async Task<object> ExecuteScalarAsync(string connectionString, string storedProc, params SqlParameter[] parameters)
        {
            using var conn = new SqlConnection(connectionString);
            using var cmd = new SqlCommand(storedProc, conn) { CommandType = CommandType.StoredProcedure };
            if (parameters != null) cmd.Parameters.AddRange(parameters);
            await conn.OpenAsync();
            return await cmd.ExecuteScalarAsync();
        }
    }

}
