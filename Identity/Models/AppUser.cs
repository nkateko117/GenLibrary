using Microsoft.AspNetCore.Identity;

namespace GenLibrary.Identity.Models
{
    public class AppUser : IdentityUser<Guid>
    {
        public string? FullName { get; set; }
    }
}
