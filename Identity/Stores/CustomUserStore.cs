using GenLibrary.Data;
using GenLibrary.Identity.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.SqlClient;
using System.Data;

namespace GenLibrary.Identity.Stores
{
    public class CustomUserStore :
        IUserStore<AppUser>,
        IUserPasswordStore<AppUser>,
        IUserRoleStore<AppUser>,
        IUserEmailStore<AppUser>
    {
        private readonly IDal _dal;
        private readonly string _conn;

        public CustomUserStore(IDal dal, IConfiguration config)
        {
            _dal = dal;
            _conn = config.GetConnectionString("DefaultConnection");
        }

        public void Dispose() { /* no-op */ }

        #region IUserStore
        public async Task<IdentityResult> CreateAsync(AppUser user, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var pUserName = new SqlParameter("@UserName", user.UserName ?? (object)DBNull.Value);
            var pNormUser = new SqlParameter("@NormalizedUserName", user.NormalizedUserName ?? (object)DBNull.Value);
            var pEmail = new SqlParameter("@Email", user.Email ?? (object)DBNull.Value);
            var pNormEmail = new SqlParameter("@NormalizedEmail", user.NormalizedEmail ?? (object)DBNull.Value);
            var pPasswordHash = new SqlParameter("@PasswordHash", user.PasswordHash ?? (object)DBNull.Value);
            var pFullName = new SqlParameter("@FullName", user.FullName ?? (object)DBNull.Value);

            try
            {
                // The stored procedure returns the new Id via SELECT, not an output parameter
                using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_CreateUser", pUserName, pNormUser, pEmail, pNormEmail, pPasswordHash, pFullName);
                if (await reader.ReadAsync(cancellationToken))
                {
                    user.Id = reader.GetGuid(0);
                }
                return IdentityResult.Success;
            }
            catch (SqlException ex)
            {
                return IdentityResult.Failed(new IdentityError { Code = "CreateError", Description = ex.Message });
            }
        }

        public async Task<IdentityResult> UpdateAsync(AppUser user, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var pId = new SqlParameter("@Id", user.Id);
            var pUserName = new SqlParameter("@UserName", user.UserName ?? (object)DBNull.Value);
            var pNormUser = new SqlParameter("@NormalizedUserName", user.NormalizedUserName ?? (object)DBNull.Value);
            var pEmail = new SqlParameter("@Email", user.Email ?? (object)DBNull.Value);
            var pNormEmail = new SqlParameter("@NormalizedEmail", user.NormalizedEmail ?? (object)DBNull.Value);
            var pPasswordHash = new SqlParameter("@PasswordHash", user.PasswordHash ?? (object)DBNull.Value);
            var pFullName = new SqlParameter("@FullName", user.FullName ?? (object)DBNull.Value);
            var pConcurrency = new SqlParameter("@ConcurrencyStamp", user.ConcurrencyStamp ?? (object)DBNull.Value);

            await _dal.ExecuteNonQueryAsync(_conn, "PROC_ID_UpdateUser", pId, pUserName, pNormUser, pEmail, pNormEmail, pPasswordHash, pFullName, pConcurrency);
            return IdentityResult.Success;
        }

        public async Task<IdentityResult> DeleteAsync(AppUser user, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var pId = new SqlParameter("@Id", user.Id);
            await _dal.ExecuteNonQueryAsync(_conn, "PROC_ID_DeleteUser", pId);
            return IdentityResult.Success;
        }

        public Task<AppUser> FindByIdAsync(string userId, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (!Guid.TryParse(userId, out var gid)) return Task.FromResult<AppUser>(null);

            return FindByIdAsync(gid, cancellationToken);
        }

        public async Task<AppUser> FindByIdAsync(Guid id, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();

            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_GetUserById", new SqlParameter("@Id", id));
            if (await reader.ReadAsync(cancellationToken))
            {
                return MapUser(reader);
            }
            return null;
        }

        public async Task<AppUser> FindByNameAsync(string normalizedUserName, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_GetUserByNormalizedUserName", new SqlParameter("@NormalizedUserName", normalizedUserName));
            if (await reader.ReadAsync(cancellationToken))
            {
                return MapUser(reader);
            }
            return null;
        }

        private AppUser MapUser(SqlDataReader reader)
        {
            var user = new AppUser
            {
                Id = reader.GetGuid(reader.GetOrdinal("Id")),
                UserName = reader["UserName"]?.ToString(),
                NormalizedUserName = reader["NormalizedUserName"]?.ToString(),
                Email = reader["Email"]?.ToString(),
                NormalizedEmail = reader["NormalizedEmail"]?.ToString(),
                EmailConfirmed = reader["EmailConfirmed"] != DBNull.Value && (bool)reader["EmailConfirmed"],
                PasswordHash = reader["PasswordHash"]?.ToString(),
                SecurityStamp = reader["SecurityStamp"]?.ToString(),
                ConcurrencyStamp = reader["ConcurrencyStamp"]?.ToString(),
                PhoneNumber = reader["PhoneNumber"]?.ToString(),
                PhoneNumberConfirmed = reader["PhoneNumberConfirmed"] != DBNull.Value && (bool)reader["PhoneNumberConfirmed"],
                TwoFactorEnabled = reader["TwoFactorEnabled"] != DBNull.Value && (bool)reader["TwoFactorEnabled"],
                FullName = reader["FullName"]?.ToString()
            };
            return user;
        }

        public Task<string> GetUserIdAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.Id.ToString());
        public Task<string> GetUserNameAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.UserName);
        public Task SetUserNameAsync(AppUser user, string userName, CancellationToken cancellationToken) { user.UserName = userName; return Task.CompletedTask; }
        public Task<string> GetNormalizedUserNameAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.NormalizedUserName);
        public Task SetNormalizedUserNameAsync(AppUser user, string normalizedName, CancellationToken cancellationToken) { user.NormalizedUserName = normalizedName; return Task.CompletedTask; }
        #endregion

        #region IUserPasswordStore
        public Task SetPasswordHashAsync(AppUser user, string passwordHash, CancellationToken cancellationToken)
        {
            user.PasswordHash = passwordHash;
            // persist to db
            return _dal.ExecuteNonQueryAsync(_conn, "PROC_ID_SetPasswordHash", new SqlParameter("@UserId", user.Id), new SqlParameter("@PasswordHash", passwordHash));
        }

        public Task<string> GetPasswordHashAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.PasswordHash);
        public Task<bool> HasPasswordAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(!string.IsNullOrEmpty(user.PasswordHash));
        #endregion

        #region IUserRoleStore
        public async Task AddToRoleAsync(AppUser user, string roleName, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            // Get role id
            using var r = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_GetRoleByNormalizedName", new SqlParameter("@NormalizedName", roleName.ToUpperInvariant()));
            Guid roleId;
            if (await r.ReadAsync(cancellationToken))
            {
                roleId = r.GetGuid(r.GetOrdinal("Id"));
            }
            else
            {
                // create role
                var pRoleId = new SqlParameter("@Id", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output };
                await _dal.ExecuteNonQueryAsync(_conn, "PROC_ID_CreateRole", pRoleId, new SqlParameter("@Name", roleName), new SqlParameter("@NormalizedName", roleName.ToUpperInvariant()));
                roleId = (Guid)pRoleId.Value;
            }

            await _dal.ExecuteNonQueryAsync(_conn, "PROC_ID_AddUserToRole", new SqlParameter("@UserId", user.Id), new SqlParameter("@RoleId", roleId));
        }

        public Task RemoveFromRoleAsync(AppUser user, string roleName, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            // get role id
            return Task.Run(async () =>
            {
                using var r = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_GetRoleByNormalizedName", new SqlParameter("@NormalizedName", roleName.ToUpperInvariant()));
                if (await r.ReadAsync(cancellationToken))
                {
                    var roleId = r.GetGuid(r.GetOrdinal("Id"));
                    await _dal.ExecuteNonQueryAsync(_conn, "PROC_ID_RemoveUserFromRole", new SqlParameter("@UserId", user.Id), new SqlParameter("@RoleId", roleId));
                }
            }, cancellationToken);
        }

        public async Task<IList<string>> GetRolesAsync(AppUser user, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var roles = new List<string>();
            using var r = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_GetRolesForUser", new SqlParameter("@UserId", user.Id));
            while (await r.ReadAsync(cancellationToken))
            {
                roles.Add(r["Name"].ToString());
            }
            return roles;
        }

        public async Task<bool> IsInRoleAsync(AppUser user, string roleName, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var roles = await GetRolesAsync(user, cancellationToken);
            return roles.Contains(roleName);
        }

        public async Task<IList<AppUser>> GetUsersInRoleAsync(string roleName, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var users = new List<AppUser>();
            using var r = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "SELECT u.* FROM AppUsers u JOIN AppUserRoles ur ON u.Id = ur.UserId JOIN AppRoles r ON r.Id = ur.RoleId WHERE r.NormalizedName = @NormalizedName", new SqlParameter("@NormalizedName", roleName.ToUpperInvariant()));
            while (await r.ReadAsync(cancellationToken))
            {
                users.Add(MapUser(r));
            }
            return users;
        }
        #endregion

        #region IUserEmailStore
        public Task SetEmailAsync(AppUser user, string email, CancellationToken cancellationToken) { user.Email = email; return Task.CompletedTask; }
        public Task<string> GetEmailAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.Email);
        public Task<bool> GetEmailConfirmedAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.EmailConfirmed);
        public Task SetEmailConfirmedAsync(AppUser user, bool confirmed, CancellationToken cancellationToken) { user.EmailConfirmed = confirmed; return Task.CompletedTask; }
        public async Task<AppUser> FindByEmailAsync(string normalizedEmail, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            using var reader = (SqlDataReader)await _dal.ExecuteReaderAsync(_conn, "PROC_ID_GetUserByNormalizedEmail", new SqlParameter("@NormalizedEmail", normalizedEmail));
            if (await reader.ReadAsync(cancellationToken))
            {
                // PROC_ID_GetUserByNormalizedEmail returns fewer columns than MapUser expects,
                // so we map only the available columns here
                return new AppUser
                {
                    Id = reader.GetGuid(reader.GetOrdinal("Id")),
                    UserName = reader["UserName"]?.ToString(),
                    NormalizedUserName = reader["NormalizedUserName"]?.ToString(),
                    Email = reader["Email"]?.ToString(),
                    NormalizedEmail = reader["NormalizedEmail"]?.ToString(),
                    EmailConfirmed = reader["EmailConfirmed"] != DBNull.Value && (bool)reader["EmailConfirmed"],
                    PasswordHash = reader["PasswordHash"]?.ToString(),
                    FullName = reader["FullName"]?.ToString()
                };
            }
            return null;
        }

        public Task<string> GetNormalizedEmailAsync(AppUser user, CancellationToken cancellationToken) => Task.FromResult(user.NormalizedEmail);
        public Task SetNormalizedEmailAsync(AppUser user, string normalizedEmail, CancellationToken cancellationToken) { user.NormalizedEmail = normalizedEmail; return Task.CompletedTask; }
        #endregion
    }

}
