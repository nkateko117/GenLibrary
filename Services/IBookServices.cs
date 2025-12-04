using GenLibrary.Dtos;
using GenLibrary.Identity.Models;

namespace GenLibrary.Services
{
    public interface IBookServices
    {
        Task<IEnumerable<AuthorDto>> GetMembersAsync();
    }
}
