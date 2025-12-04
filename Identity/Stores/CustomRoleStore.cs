using GenLibrary.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.SqlClient;
using System.Data;

namespace GenLibrary.Identity.Stores
{
    public class CustomRoleStore : IRoleStore<IdentityRole<Guid>>
    {
        private readonly IDal _dal;
        private readonly string _conn;

        public CustomRoleStore(IDal dal, IConfiguration config)
        {
            _dal = dal;
            _conn = config.GetConnectionString("DefaultConnection");
        }

        public void Dispose() { }

        public async Task<IdentityResult> CreateAsync(IdentityRole<Guid> role, CancellationToken cancellationToken)
        {
            var pId = new SqlParameter("@Id", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output };
            await _dal.ExecuteNonQueryAsync(_conn, "PROC_ID_CreateRole", pId, new SqlParameter("@Name", role.Name), new SqlParameter("@NormalizedName", role.NormalizedName));
            role.Id = (Guid)pId.Value;
            return IdentityResult.Success;
        }

        public async Task<IdentityResult> UpdateAsync(IdentityRole<Guid> role, CancellationToken cancellationToken)
        {
            return IdentityResult.Success;
        }

        public async Task<IdentityResult> DeleteAsync(IdentityRole<Guid> role, CancellationToken cancellationToken)
        {
            return IdentityResult.Success;
        }

        public async Task<IdentityRole<Guid>> FindByIdAsync(string roleId, CancellationToken cancellationToken)
        {
            if (!Guid.TryParse(roleId, out var gid)) return null;

            using var r = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_GetRoleById", new SqlParameter("@Id", gid));
            if (await r.ReadAsync(cancellationToken))
            {
                return new IdentityRole<Guid> { Id = r.GetGuid(r.GetOrdinal("Id")), Name = r["Name"].ToString(), NormalizedName = r["NormalizedName"].ToString() };
            }
            return null;
        }

        public async Task<IdentityRole<Guid>> FindByNameAsync(string normalizedRoleName, CancellationToken cancellationToken)
        {
            using var r = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_GetRoleByNormalizedName", new SqlParameter("@NormalizedName", normalizedRoleName));
            if (await r.ReadAsync(cancellationToken))
            {
                return new IdentityRole<Guid> { Id = r.GetGuid(r.GetOrdinal("Id")), Name = r["Name"].ToString(), NormalizedName = r["NormalizedName"].ToString() };
            }
            return null;
        }

        public Task<string> GetRoleIdAsync(IdentityRole<Guid> role, CancellationToken cancellationToken) => Task.FromResult(role.Id.ToString());
        public Task<string> GetRoleNameAsync(IdentityRole<Guid> role, CancellationToken cancellationToken) => Task.FromResult(role.Name);
        public Task SetRoleNameAsync(IdentityRole<Guid> role, string roleName, CancellationToken cancellationToken) { role.Name = roleName; return Task.CompletedTask; }
        public Task<string> GetNormalizedRoleNameAsync(IdentityRole<Guid> role, CancellationToken cancellationToken) => Task.FromResult(role.NormalizedName);
        public Task SetNormalizedRoleNameAsync(IdentityRole<Guid> role, string normalizedName, CancellationToken cancellationToken) { role.NormalizedName = normalizedName; return Task.CompletedTask; }
    }
}
