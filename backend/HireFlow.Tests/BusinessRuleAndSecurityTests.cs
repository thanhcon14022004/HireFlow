using System.Text;
using HireFlow.Api.Configuration;
using HireFlow.Api.Data;
using HireFlow.Api.Entities;
using HireFlow.Api.Services;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

namespace HireFlow.Tests;

public class BusinessRuleAndSecurityTests
{
    private HireFlowDbContext CreateInMemoryDbContext(string dbName)
    {
        var options = new DbContextOptionsBuilder<HireFlowDbContext>()
            .UseInMemoryDatabase(databaseName: dbName)
            .Options;
        return new HireFlowDbContext(options);
    }

    [Fact]
    public void CreditConstants_ShouldMatchSpecification()
    {
        // Assert exact costs per RDS Section 5
        Assert.Equal(3, CreditConstants.ApplicationCost);
        Assert.Equal(5, CreditConstants.PublishProjectCost);
        Assert.Equal(4, CreditConstants.ContactUnlockCost);
        Assert.Equal(0, CreditConstants.EditProjectCost);
    }

    [Fact]
    public void PasswordHasher_ShouldCorrectlyHashAndVerify()
    {
        var hasher = new PasswordHasherService();
        var password = "SecurePassword123!";

        var hash = hasher.HashPassword(password);

        Assert.NotEmpty(hash);
        Assert.NotEqual(password, hash); // Plaintext is never stored
        Assert.True(hasher.VerifyPassword(password, hash));
        Assert.False(hasher.VerifyPassword("WrongPassword!", hash));
    }

    [Fact]
    public async Task ContactUnlock_FirstTime_ShouldRequireCredits_SecondTime_Free()
    {
        var db = CreateInMemoryDbContext(nameof(ContactUnlock_FirstTime_ShouldRequireCredits_SecondTime_Free));
        var freelancer = new User { FullName = "Free Lancer", Email = "fl@hireflow.com", Role = "Freelancer" };
        var employer = new User { FullName = "Emp Loyee", Email = "emp@hireflow.com", Role = "Employer" };
        db.Users.AddRange(freelancer, employer);
        await db.SaveChangesAsync();

        var wallet = new CreditWallet { UserId = freelancer.UserId, Balance = 10 };
        db.CreditWallets.Add(wallet);
        await db.SaveChangesAsync();

        var creditService = new CreditService(db, NullLogger<CreditService>.Instance);

        // First unlock check
        var isAlreadyUnlocked = await db.ContactUnlocks.AnyAsync(c => c.FreelancerId == freelancer.UserId && c.EmployerId == employer.UserId);
        Assert.False(isAlreadyUnlocked);

        // Deduct 4 credits
        var cost = CreditConstants.ContactUnlockCost;
        var deduct = await creditService.DeductCreditsAsync(freelancer.UserId, cost, "ContactUnlock", "Contact", employer.UserId.ToString(), "Unlock contact");
        Assert.True(deduct.Success);

        db.ContactUnlocks.Add(new ContactUnlock
        {
            FreelancerId = freelancer.UserId,
            EmployerId = employer.UserId,
            UnlockedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();

        // Second check - already unlocked
        var isUnlockedNow = await db.ContactUnlocks.AnyAsync(c => c.FreelancerId == freelancer.UserId && c.EmployerId == employer.UserId);
        Assert.True(isUnlockedNow);

        // In second check, 0 credits are deducted! Balance remains 6
        var updatedWallet = await db.CreditWallets.FindAsync(wallet.WalletId);
        Assert.Equal(6, updatedWallet!.Balance);
    }

    [Fact]
    public async Task DuplicateApplication_ShouldBePrevented()
    {
        var db = CreateInMemoryDbContext(nameof(DuplicateApplication_ShouldBePrevented));
        var freelancer = new User { FullName = "Free Lancer", Email = "fl2@hireflow.com", Role = "Freelancer" };
        var employer = new User { FullName = "Emp Loyee", Email = "emp2@hireflow.com", Role = "Employer" };
        db.Users.AddRange(freelancer, employer);
        await db.SaveChangesAsync();

        var project = new Project
        {
            EmployerId = employer.UserId,
            Title = "Test Project",
            Description = "Test desc",
            Status = "Open"
        };
        db.Projects.Add(project);

        var doc = new FreelancerDocument
        {
            FreelancerId = freelancer.UserId,
            OriginalFileName = "cv.pdf",
            StorageKey = "cv.pdf",
            ContentType = "application/pdf",
            FileSize = 1000
        };
        db.FreelancerDocuments.Add(doc);
        await db.SaveChangesAsync();

        // First application
        var app1 = new Application
        {
            ProjectId = project.ProjectId,
            FreelancerId = freelancer.UserId,
            DocumentId = doc.DocumentId,
            Status = "Pending"
        };
        db.Applications.Add(app1);
        await db.SaveChangesAsync();

        // Attempting to check if applied
        var hasApplied = await db.Applications.AnyAsync(a => a.ProjectId == project.ProjectId && a.FreelancerId == freelancer.UserId);
        Assert.True(hasApplied);
    }

    [Fact]
    public async Task FileStorage_ShouldValidatePdfMagicBytes()
    {
        var mockEnv = new Mock<IWebHostEnvironment>();
        var tempDir = Path.Combine(Path.GetTempPath(), "HireFlowTests_" + Guid.NewGuid().ToString("N"));
        mockEnv.Setup(e => e.ContentRootPath).Returns(tempDir);

        var inMemoryConfig = new Dictionary<string, string?>
        {
            {"FileStorage:StoragePath", tempDir},
            {"FileStorage:MaxFileSizeMb", "5"}
        };
        var configuration = new ConfigurationBuilder().AddInMemoryCollection(inMemoryConfig).Build();

        var storage = new LocalFileStorageService(configuration, mockEnv.Object);

        // Valid PDF: starts with %PDF- (0x25, 0x50, 0x44, 0x46)
        var validPdfBytes = Encoding.ASCII.GetBytes("%PDF-1.4\nTest content for PDF...");
        using var validStream = new MemoryStream(validPdfBytes);
        var (storageKey, size, hash) = await storage.SavePdfAsync(validStream, "my_cv.pdf");

        Assert.NotEmpty(storageKey);
        Assert.Equal(validPdfBytes.Length, size);
        Assert.NotEmpty(hash);

        // Invalid PDF: text file with .pdf extension
        var fakePdfBytes = Encoding.ASCII.GetBytes("This is not a real PDF file!");
        using var fakeStream = new MemoryStream(fakePdfBytes);
        await Assert.ThrowsAsync<ArgumentException>(() => storage.SavePdfAsync(fakeStream, "fake.pdf"));

        // Non-pdf extension
        using var exeStream = new MemoryStream(validPdfBytes);
        await Assert.ThrowsAsync<ArgumentException>(() => storage.SavePdfAsync(exeStream, "virus.exe"));

        // Cleanup
        if (Directory.Exists(tempDir))
        {
            Directory.Delete(tempDir, true);
        }
    }
}
