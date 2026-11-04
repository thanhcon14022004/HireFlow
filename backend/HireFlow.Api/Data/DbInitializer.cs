using HireFlow.Api.Entities;
using HireFlow.Api.Services;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Data;

public static class DbInitializer
{
    public static async Task InitializeAsync(HireFlowDbContext db, IPasswordHasherService passwordHasher, IConfiguration configuration, ILogger logger)
    {
        try
        {
            // Ensure UserNotifications table exists
            try
            {
                await db.Database.ExecuteSqlRawAsync(@"
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='UserNotifications' and xtype='U')
                    BEGIN
                        CREATE TABLE UserNotifications (
                            NotificationId INT IDENTITY(1,1) PRIMARY KEY,
                            UserId INT NOT NULL,
                            Title NVARCHAR(200) NOT NULL,
                            Message NVARCHAR(MAX) NOT NULL,
                            Type NVARCHAR(50) NOT NULL,
                            ReferenceId INT NULL,
                            IsRead BIT NOT NULL DEFAULT 0,
                            CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
                            CONSTRAINT FK_UserNotifications_Users_UserId FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
                        );
                    END
                ");
            }
            catch (Exception ex)
            {
                logger.LogWarning("UserNotifications table check/creation skipped: {Message}", ex.Message);
            }

            // Seed CreditPackages (Rate: 5,000 VND / 1 Credit)
            if (!await db.CreditPackages.AnyAsync())
            {
                var packages = new List<CreditPackage>
                {
                    new()
                    {
                        Name = "Gói Tiết Kiệm (5 Credits)",
                        CreditAmount = 5,
                        PriceAmount = 25000,
                        CurrencyCode = "VND",
                        IsActive = true,
                        DisplayOrder = 1
                    },
                    new()
                    {
                        Name = "Gói Khởi Đầu (10 Credits)",
                        CreditAmount = 10,
                        PriceAmount = 50000,
                        CurrencyCode = "VND",
                        IsActive = true,
                        DisplayOrder = 2
                    },
                    new()
                    {
                        Name = "Gói Tiêu Chuẩn (20 Credits)",
                        CreditAmount = 20,
                        PriceAmount = 100000,
                        CurrencyCode = "VND",
                        IsActive = true,
                        DisplayOrder = 3
                    },
                    new()
                    {
                        Name = "Gói Nâng Cao (50 Credits)",
                        CreditAmount = 50,
                        PriceAmount = 250000,
                        CurrencyCode = "VND",
                        IsActive = true,
                        DisplayOrder = 4
                    },
                    new()
                    {
                        Name = "Gói Doanh Nghiệp (100 Credits)",
                        CreditAmount = 100,
                        PriceAmount = 500000,
                        CurrencyCode = "VND",
                        IsActive = true,
                        DisplayOrder = 5
                    }
                };
                await db.CreditPackages.AddRangeAsync(packages);
                await db.SaveChangesAsync();
                logger.LogInformation("Seeded default Credit Packages at 5k/credit.");
            }
            else
            {
                // Synchronize existing packages to 5,000 VND per 1 credit
                var existingPackages = await db.CreditPackages.ToListAsync();
                foreach (var p in existingPackages)
                {
                    p.PriceAmount = p.CreditAmount * 5000m;
                }
                await db.SaveChangesAsync();
            }

            // Seed Admin User (AUTH-006: Admin cannot register publicly)
            var adminEmail = configuration["AdminSeed:Email"] ?? "admin@hireflow.com";
            var adminUser = await db.Users.FirstOrDefaultAsync(u => u.Email == adminEmail);
            if (adminUser == null)
            {
                var adminPassword = configuration["AdminSeed:Password"] ?? "Admin@HireFlow2026!";
                var adminFullName = configuration["AdminSeed:FullName"] ?? "Quản Trị Viên Hệ Thống";

                adminUser = new User
                {
                    FullName = adminFullName,
                    Email = adminEmail,
                    PasswordHash = passwordHasher.HashPassword(adminPassword),
                    Role = "Admin",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                db.Users.Add(adminUser);
                await db.SaveChangesAsync();

                db.CreditWallets.Add(new CreditWallet
                {
                    UserId = adminUser.UserId,
                    Balance = 9999,
                    UpdatedAt = DateTime.UtcNow
                });
                await db.SaveChangesAsync();

                logger.LogInformation("Seeded initial Admin user: {Email}", adminEmail);
            }

            // Seed Sample Employer & Freelancer for development demo if database is fresh
            var employerEmail = "employer@hireflow.com";
            var employer = await db.Users.FirstOrDefaultAsync(u => u.Email == employerEmail);
            if (employer == null)
            {
                employer = new User
                {
                    FullName = "Công ty Công nghệ TechNova",
                    Email = employerEmail,
                    PasswordHash = passwordHasher.HashPassword("Employer@123!"),
                    Role = "Employer",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                db.Users.Add(employer);
                await db.SaveChangesAsync();

                db.EmployerProfiles.Add(new EmployerProfile
                {
                    UserId = employer.UserId,
                    CompanyName = "TechNova Solutions VN",
                    Description = "Công ty phần mềm chuyên phát triển các giải pháp Web, Mobile và Cloud quy mô lớn.",
                    PublicDisplayName = "TechNova HR Team",
                    ContactEmail = "contact@technova.vn",
                    ContactPhone = "0909123456",
                    UpdatedAt = DateTime.UtcNow
                });

                db.CreditWallets.Add(new CreditWallet
                {
                    UserId = employer.UserId,
                    Balance = 50,
                    UpdatedAt = DateTime.UtcNow
                });

                await db.SaveChangesAsync();

                // Seed sample projects
                var project1 = new Project
                {
                    EmployerId = employer.UserId,
                    Title = "Phát triển Ứng dụng Di động Flutter Thương mại Điện tử",
                    Description = "Chúng tôi cần một lập trình viên Flutter có kinh nghiệm để xây dựng ứng dụng mua sắm trực tuyến kết nối REST API, tích hợp cổng thanh toán và thông báo đẩy. Yêu cầu clean architecture và Riverpod/Provider.",
                    BudgetMin = 15000000,
                    BudgetMax = 25000000,
                    CurrencyCode = "VND",
                    ExperienceLevel = "Trung cấp (2-3 năm)",
                    Deadline = DateTime.UtcNow.AddDays(30),
                    Status = "Open",
                    CreatedAt = DateTime.UtcNow,
                    PublishedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                project1.Skills.Add(new ProjectSkill { SkillName = "Flutter" });
                project1.Skills.Add(new ProjectSkill { SkillName = "Dart" });
                project1.Skills.Add(new ProjectSkill { SkillName = "REST API" });

                var project2 = new Project
                {
                    EmployerId = employer.UserId,
                    Title = "Xây dựng Backend API ASP.NET Core & SQL Server",
                    Description = "Tìm kiếm backend developer thành thạo .NET Core, EF Core để thiết kế và tối ưu hệ thống quản lý kho hàng và báo cáo tài chính. Cần tối ưu query và viết unit test đầy đủ.",
                    BudgetMin = 20000000,
                    BudgetMax = 35000000,
                    CurrencyCode = "VND",
                    ExperienceLevel = "Cao cấp (3+ năm)",
                    Deadline = DateTime.UtcNow.AddDays(45),
                    Status = "Open",
                    CreatedAt = DateTime.UtcNow,
                    PublishedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                project2.Skills.Add(new ProjectSkill { SkillName = ".NET Core" });
                project2.Skills.Add(new ProjectSkill { SkillName = "C#" });
                project2.Skills.Add(new ProjectSkill { SkillName = "SQL Server" });

                await db.Projects.AddRangeAsync(project1, project2);
                await db.SaveChangesAsync();
                logger.LogInformation("Seeded sample Employer and Projects.");
            }

            var freelancerEmail = "freelancer@hireflow.com";
            var freelancer = await db.Users.FirstOrDefaultAsync(u => u.Email == freelancerEmail);
            if (freelancer == null)
            {
                freelancer = new User
                {
                    FullName = "Nguyễn Văn An",
                    Email = freelancerEmail,
                    PasswordHash = passwordHasher.HashPassword("Freelancer@123!"),
                    Role = "Freelancer",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                db.Users.Add(freelancer);
                await db.SaveChangesAsync();

                var profile = new FreelancerProfile
                {
                    UserId = freelancer.UserId,
                    Headline = "Senior Mobile Developer (Flutter / React Native)",
                    Bio = "5 năm kinh nghiệm phát triển ứng dụng di động cho thị trường Đông Nam Á. Đam mê UI/UX mượt mà và tối ưu hiệu năng.",
                    ExperienceYears = 5,
                    UpdatedAt = DateTime.UtcNow
                };
                profile.Skills.Add(new FreelancerSkill { SkillName = "Flutter" });
                profile.Skills.Add(new FreelancerSkill { SkillName = "Dart" });
                profile.Skills.Add(new FreelancerSkill { SkillName = ".NET" });

                db.FreelancerProfiles.Add(profile);

                db.CreditWallets.Add(new CreditWallet
                {
                    UserId = freelancer.UserId,
                    Balance = 30, // 30 credits ready to test
                    UpdatedAt = DateTime.UtcNow
                });

                await db.SaveChangesAsync();
                logger.LogInformation("Seeded sample Freelancer with profile and 30 credits.");
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred while seeding database");
        }
    }
}

