using HireFlow.Api.Data;
using HireFlow.Api.Entities;
using HireFlow.Api.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace HireFlow.Tests;

public class CreditServiceTests
{
    private HireFlowDbContext CreateInMemoryDbContext(string dbName)
    {
        var options = new DbContextOptionsBuilder<HireFlowDbContext>()
            .UseInMemoryDatabase(databaseName: dbName)
            .Options;
        return new HireFlowDbContext(options);
    }

    [Fact]
    public async Task DeductCredits_WithSufficientBalance_ShouldSucceedAndDeductBalance()
    {
        // Arrange
        var db = CreateInMemoryDbContext(nameof(DeductCredits_WithSufficientBalance_ShouldSucceedAndDeductBalance));
        var user = new User { FullName = "Tester", Email = "test@hireflow.com", Role = "Freelancer" };
        db.Users.Add(user);
        await db.SaveChangesAsync();

        var wallet = new CreditWallet { UserId = user.UserId, Balance = 10 };
        db.CreditWallets.Add(wallet);
        await db.SaveChangesAsync();

        var creditService = new CreditService(db, NullLogger<CreditService>.Instance);

        // Act
        var result = await creditService.DeductCreditsAsync(
            user.UserId,
            3,
            "ApplicationFee",
            "Application",
            "1",
            "Test application charge");

        // Assert
        Assert.True(result.Success);
        Assert.Null(result.ErrorMessage);

        var updatedWallet = await db.CreditWallets.FindAsync(wallet.WalletId);
        Assert.Equal(7, updatedWallet!.Balance);

        var tx = await db.CreditTransactions.FirstOrDefaultAsync(t => t.UserId == user.UserId);
        Assert.NotNull(tx);
        Assert.Equal(-3, tx!.Amount);
        Assert.Equal("ApplicationFee", tx.TransactionType);
    }

    [Fact]
    public async Task DeductCredits_WithInsufficientBalance_ShouldFailAndNotChangeBalance()
    {
        // Arrange
        var db = CreateInMemoryDbContext(nameof(DeductCredits_WithInsufficientBalance_ShouldFailAndNotChangeBalance));
        var user = new User { FullName = "Broke User", Email = "broke@hireflow.com", Role = "Freelancer" };
        db.Users.Add(user);
        await db.SaveChangesAsync();

        var wallet = new CreditWallet { UserId = user.UserId, Balance = 2 }; // Has 2, needs 3
        db.CreditWallets.Add(wallet);
        await db.SaveChangesAsync();

        var creditService = new CreditService(db, NullLogger<CreditService>.Instance);

        // Act
        var result = await creditService.DeductCreditsAsync(
            user.UserId,
            3,
            "ApplicationFee",
            "Application",
            "1",
            "Test application charge");

        // Assert
        Assert.False(result.Success);
        Assert.Contains("không đủ credit", result.ErrorMessage);

        var updatedWallet = await db.CreditWallets.FindAsync(wallet.WalletId);
        Assert.Equal(2, updatedWallet!.Balance); // Remains 2, no negative balance!
    }

    [Fact]
    public async Task DeductCredits_WithIdempotencyKey_ShouldProcessOnlyOnce()
    {
        // Arrange
        var db = CreateInMemoryDbContext(nameof(DeductCredits_WithIdempotencyKey_ShouldProcessOnlyOnce));
        var user = new User { FullName = "Idempotent User", Email = "idem@hireflow.com", Role = "Freelancer" };
        db.Users.Add(user);
        await db.SaveChangesAsync();

        var wallet = new CreditWallet { UserId = user.UserId, Balance = 20 };
        db.CreditWallets.Add(wallet);
        await db.SaveChangesAsync();

        var creditService = new CreditService(db, NullLogger<CreditService>.Instance);
        var key = "KEY-12345";

        // Act - Call 1
        var result1 = await creditService.DeductCreditsAsync(user.UserId, 5, "ProjectPublish", "Project", "1", "First call", key);
        // Act - Call 2 with identical key
        var result2 = await creditService.DeductCreditsAsync(user.UserId, 5, "ProjectPublish", "Project", "1", "Duplicate call", key);

        // Assert
        Assert.True(result1.Success);
        Assert.True(result2.Success);

        var updatedWallet = await db.CreditWallets.FindAsync(wallet.WalletId);
        Assert.Equal(15, updatedWallet!.Balance); // Deducted only 5, NOT 10!
    }

    [Fact]
    public async Task AddCredits_ShouldIncreaseBalanceAndRecordTransaction()
    {
        // Arrange
        var db = CreateInMemoryDbContext(nameof(AddCredits_ShouldIncreaseBalanceAndRecordTransaction));
        var user = new User { FullName = "Top Up User", Email = "topup@hireflow.com", Role = "Freelancer" };
        db.Users.Add(user);
        await db.SaveChangesAsync();

        var wallet = new CreditWallet { UserId = user.UserId, Balance = 5 };
        db.CreditWallets.Add(wallet);
        await db.SaveChangesAsync();

        var creditService = new CreditService(db, NullLogger<CreditService>.Instance);

        // Act
        var result = await creditService.AddCreditsAsync(user.UserId, 50, "CreditPurchase", "Purchase", "99", "Purchased 50 credits");

        // Assert
        Assert.True(result.Success);
        var updatedWallet = await db.CreditWallets.FindAsync(wallet.WalletId);
        Assert.Equal(55, updatedWallet!.Balance);

        var tx = await db.CreditTransactions.FirstOrDefaultAsync(t => t.UserId == user.UserId && t.Amount == 50);
        Assert.NotNull(tx);
        Assert.Equal("CreditPurchase", tx!.TransactionType);
    }
}

