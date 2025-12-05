using GenLibrary.Data;
using GenLibrary.Identity.Models;
using GenLibrary.Identity.Stores;
using GenLibrary.Services;
using Microsoft.AspNetCore.Identity;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddSingleton<IDal, Dal>();

// Register Identity Stores
builder.Services.AddScoped<IUserStore<AppUser>, CustomUserStore>();
builder.Services.AddScoped<IRoleStore<IdentityRole<Guid>>, CustomRoleStore>();

builder.Services.AddScoped<IAuthService, AuthService>();

// ASP.NET Core Identity Config
builder.Services.AddIdentity<AppUser, IdentityRole<Guid>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
})
.AddDefaultTokenProviders();

builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.AccessDeniedPath = "/Account/AccessDenied";
    options.ExpireTimeSpan = TimeSpan.FromHours(4);
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// Seeding Initial Roles + Admin User
using (var scope = app.Services.CreateScope())
{
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();

    var roles = new[] { "Librarian", "Member" };

    foreach (var role in roles)
    {
        if (!await roleManager.RoleExistsAsync(role))
        {
            await roleManager.CreateAsync(
                new IdentityRole<Guid>
                {
                    Name = role,
                    NormalizedName = role.ToUpperInvariant()
                });
        }
    }

    // Seeding default Librarian
    var adminEmail = "librarian@library.local";
    var adminUser = await userManager.FindByEmailAsync(adminEmail);

    if (adminUser == null)
    {
        adminUser = new AppUser
        {
            UserName = "librarian",
            NormalizedUserName = "LIBRARIAN",
            Email = adminEmail,
            NormalizedEmail = adminEmail.ToUpperInvariant(),
            FullName = "Initial Librarian"
        };

        var createResult = await userManager.CreateAsync(adminUser, "P@ssw0rd!");

        if (createResult.Succeeded)
        {
            await userManager.AddToRoleAsync(adminUser, "Librarian");
        }
    }
}
app.Run();
