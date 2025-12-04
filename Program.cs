// Program.cs (snippet)
using GenLibrary.Data;
using GenLibrary.Identity.Models;
using GenLibrary.Identity.Stores;
using Microsoft.AspNetCore.Identity;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();

builder.Services.AddSingleton<IDal, Dal>(); // your DAL implementation
builder.Services.AddScoped<CustomUserStore>();
builder.Services.AddScoped<CustomRoleStore>();

builder.Services.AddIdentity<AppUser, IdentityRole<Guid>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
})
.AddUserStore<CustomUserStore>()
.AddRoleStore<CustomRoleStore>()
.AddDefaultTokenProviders();

// Cookie config
builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.AccessDeniedPath = "/Account/AccessDenied";
});

builder.Services.AddControllersWithViews();

using (var scope = app.Services.CreateScope())
{
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();

    var roles = new[] { "Librarian", "Member" };
    foreach (var r in roles)
    {
        var exists = await roleManager.RoleExistsAsync(r);
        if (!exists) await roleManager.CreateAsync(new IdentityRole<Guid> { Name = r, NormalizedName = r.ToUpperInvariant() });
    }

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
        var result = await userManager.CreateAsync(adminUser, "P@ssw0rd!"); // UserManager will call your store which will persist via stored proc
        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(adminUser, "Librarian");
        }
    }
}