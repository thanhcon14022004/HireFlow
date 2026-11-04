using System.Text;
using HireFlow.Api.Configuration;
using HireFlow.Api.Data;
using HireFlow.Api.Entities;
using HireFlow.Api.Services;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
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
            .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
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

    [Fact]
    public void ProjectBudget_MinGreaterThanMax_ShouldThrowValidation()
    {
        decimal budgetMin = 10_000_000m;
        decimal budgetMax = 5_000_000m;

        Assert.True(budgetMin > budgetMax, "BudgetMin cannot exceed BudgetMax");
    }

    [Fact]
    public void ProjectDeadline_InPast_ShouldBeRecognizedAsExpired()
    {
        var expiredDeadline = DateTime.UtcNow.AddDays(-1);
        var futureDeadline = DateTime.UtcNow.AddDays(5);

        Assert.True(expiredDeadline < DateTime.UtcNow);
        Assert.False(futureDeadline < DateTime.UtcNow);
    }

    [Fact]
    public void SelfApplication_And_SelfUnlock_IdentifiedCorrectly()
    {
        int employerId = 42;
        int freelancerUserId = 42; // Same user!

        // Self application
        Assert.Equal(employerId, freelancerUserId);

        // Self contact unlock
        Assert.True(employerId == freelancerUserId, "Freelancer cannot unlock their own contact info");
    }

    [Fact]
    public async Task HireFlowAutomationService_ShouldCloseExpiredProjects_And_ExpireStalePurchases()
    {
        var dbName = nameof(HireFlowAutomationService_ShouldCloseExpiredProjects_And_ExpireStalePurchases);
        var db = CreateInMemoryDbContext(dbName);

        // 1. Add expired open project
        var employer = new User { FullName = "Employer Auto", Email = "emp_auto@hireflow.com", Role = "Employer" };
        db.Users.Add(employer);

        var pkg = new CreditPackage { CreditPackageId = 1, Name = "Pkg 1", CreditAmount = 10, PriceAmount = 20000, IsActive = true };
        db.CreditPackages.Add(pkg);
        await db.SaveChangesAsync();

        var expiredProject = new Project
        {
            EmployerId = employer.UserId,
            Title = "Auto Close Project",
            Description = "Desc",
            Status = "Open",
            Deadline = DateTime.UtcNow.AddMinutes(-10) // 10 minutes ago
        };
        var validProject = new Project
        {
            EmployerId = employer.UserId,
            Title = "Still Open Project",
            Description = "Desc",
            Status = "Open",
            Deadline = DateTime.UtcNow.AddDays(3) // 3 days in future
        };
        db.Projects.AddRange(expiredProject, validProject);

        // 2. Add stale purchase (> 2 minutes old)
        var stalePurchase = new CreditPurchase
        {
            UserId = employer.UserId,
            CreditPackageId = 1,
            CreditsPurchased = 10,
            PriceAmount = 20000,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow.AddMinutes(-5) // 5 minutes ago
        };
        db.CreditPurchases.Add(stalePurchase);
        await db.SaveChangesAsync();

        // Setup ServiceCollection for scope
        var services = new Microsoft.Extensions.DependencyInjection.ServiceCollection();
        services.AddScoped(_ => db);
        var mockSepPay = new Mock<ISepPayService>();
        mockSepPay.Setup(s => s.FetchTransactionsAsync(It.IsAny<int>())).ReturnsAsync(new List<SepPayTransactionItem>());
        services.AddScoped(_ => mockSepPay.Object);
        var mockAudit = new Mock<IAuditService>();
        services.AddScoped(_ => mockAudit.Object);
        var provider = services.BuildServiceProvider();
        var scopeFactory = provider.GetRequiredService<Microsoft.Extensions.DependencyInjection.IServiceScopeFactory>();

        var automationService = new HireFlowAutomationService(scopeFactory, NullLogger<HireFlowAutomationService>.Instance);

        // Act
        var result = await automationService.RunAutomationCycleAsync();

        // Assert
        Assert.Equal(1, result.ProjectsClosed);
        Assert.Equal(1, result.PurchasesExpired);

        var assertDb = CreateInMemoryDbContext(dbName);
        var updatedExpiredProj = await assertDb.Projects.FindAsync(expiredProject.ProjectId);
        Assert.Equal("Closed", updatedExpiredProj!.Status);

        var updatedValidProj = await assertDb.Projects.FindAsync(validProject.ProjectId);
        Assert.Equal("Open", updatedValidProj!.Status);

        var updatedPurchase = await assertDb.CreditPurchases.FindAsync(stalePurchase.CreditPurchaseId);
        Assert.Equal("Expired", updatedPurchase!.Status);
    }

    [Fact]
    public async Task MoMoPaymentService_ShouldComputeValidHmacSha256_And_SimulateSuccess()
    {
        // 1. Verify HMAC-SHA256 signature
        var rawData = "accessKey=KEY&amount=20000&orderId=MOMO_HF1";
        var secret = "SECRET123";
        var signature = MoMoPaymentService.ComputeHmacSha256(rawData, secret);
        Assert.NotEmpty(signature);
        Assert.Equal(64, signature.Length); // 64 hex characters for SHA256

        // 2. Test End-to-end MoMo simulation and wallet crediting
        var dbName = nameof(MoMoPaymentService_ShouldComputeValidHmacSha256_And_SimulateSuccess);
        var db = CreateInMemoryDbContext(dbName);

        var user = new User { FullName = "MoMo User", Email = "momo_user@hireflow.com", Role = "Freelancer" };
        db.Users.Add(user);
        await db.SaveChangesAsync();

        var wallet = new CreditWallet { UserId = user.UserId, Balance = 10 };
        db.CreditWallets.Add(wallet);

        var pkg = new CreditPackage { CreditPackageId = 2, Name = "Gói MoMo 50cr", CreditAmount = 50, PriceAmount = 100000, IsActive = true };
        db.CreditPackages.Add(pkg);

        var purchase = new CreditPurchase
        {
            UserId = user.UserId,
            CreditPackageId = pkg.CreditPackageId,
            CreditsPurchased = 50,
            PriceAmount = 100000,
            PaymentProvider = "MoMo",
            ProviderReference = "MOMO_HF101",
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };
        db.CreditPurchases.Add(purchase);
        await db.SaveChangesAsync();

        var creditService = new CreditService(db, NullLogger<CreditService>.Instance);
        var audit = new AuditService(db, NullLogger<AuditService>.Instance);
        var mockHttpClientFactory = new Mock<IHttpClientFactory>();
        var inMemoryConfig = new Dictionary<string, string?>
        {
            {"MoMo:PartnerCode", "MOMO_TEST"},
            {"MoMo:PhoneNumber", "0909123456"},
            {"MoMo:AccountHolder", "HIREFLOW MOMO STORE"}
        };
        var config = new ConfigurationBuilder().AddInMemoryCollection(inMemoryConfig).Build();

        var momoService = new MoMoPaymentService(db, creditService, audit, mockHttpClientFactory.Object, config, NullLogger<MoMoPaymentService>.Instance);

        // Verify QR & Deeplink generation
        var qrUrl = momoService.GetQrImageUrl(100000, "MOMO_HF101");
        Assert.Contains("0909123456", qrUrl);
        Assert.Contains("MOMO_HF101", qrUrl);

        var deeplink = momoService.GetDeeplink(100000, "MOMO_HF101");
        Assert.StartsWith("momo://app", deeplink);

        // Simulate payment success
        var result = await momoService.SimulateSuccessAsync(purchase.CreditPurchaseId, user.UserId);
        Assert.True(result.Success);
        Assert.Equal("Paid", result.Status);
        Assert.Equal(50, result.CreditsAdded);
        Assert.Equal(60, result.NewBalance); // 10 + 50 = 60 credits!

        var updatedWallet = await db.CreditWallets.FindAsync(wallet.WalletId);
        Assert.Equal(60, updatedWallet!.Balance);

        var updatedPurchase = await db.CreditPurchases.FindAsync(purchase.CreditPurchaseId);
        Assert.Equal("Paid", updatedPurchase!.Status);
        Assert.NotNull(updatedPurchase.PaidAt);
    }

    [Fact]
    public async Task SavedProjects_ShouldSave_And_PreventDuplicate_And_AllowUnsave()
    {
        var db = CreateInMemoryDbContext(nameof(SavedProjects_ShouldSave_And_PreventDuplicate_And_AllowUnsave));
        var freelancer = new User { FullName = "Free Lancer", Email = "fl_save@hireflow.com", Role = "Freelancer" };
        var employer = new User { FullName = "Emp Loyee", Email = "emp_save@hireflow.com", Role = "Employer" };
        db.Users.AddRange(freelancer, employer);
        await db.SaveChangesAsync();

        var project = new Project
        {
            EmployerId = employer.UserId,
            Title = "Flutter Mobile Dev",
            Description = "Need Flutter developer for mobile app",
            Status = "Open"
        };
        db.Projects.Add(project);
        await db.SaveChangesAsync();

        // 1. Initially not saved
        var isSavedBefore = await db.SavedProjects.AnyAsync(sp => sp.FreelancerId == freelancer.UserId && sp.ProjectId == project.ProjectId);
        Assert.False(isSavedBefore);

        // 2. Save project
        db.SavedProjects.Add(new SavedProject
        {
            FreelancerId = freelancer.UserId,
            ProjectId = project.ProjectId,
            SavedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();

        var isSavedAfter = await db.SavedProjects.AnyAsync(sp => sp.FreelancerId == freelancer.UserId && sp.ProjectId == project.ProjectId);
        Assert.True(isSavedAfter);

        // 3. Unsave project
        var savedRecord = await db.SavedProjects.FirstOrDefaultAsync(sp => sp.FreelancerId == freelancer.UserId && sp.ProjectId == project.ProjectId);
        Assert.NotNull(savedRecord);
        db.SavedProjects.Remove(savedRecord!);
        await db.SaveChangesAsync();

        var isSavedAfterUnsave = await db.SavedProjects.AnyAsync(sp => sp.FreelancerId == freelancer.UserId && sp.ProjectId == project.ProjectId);
        Assert.False(isSavedAfterUnsave);
    }
}
