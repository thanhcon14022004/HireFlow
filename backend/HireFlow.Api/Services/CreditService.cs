using HireFlow.Api.Data;
using HireFlow.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Services;

public interface ICreditService
{
    Task<int> GetBalanceAsync(int userId, CancellationToken ct = default);
    Task<bool> HasSufficientBalanceAsync(int userId, int requiredCredits, CancellationToken ct = default);
    Task<(bool Success, string? ErrorMessage)> DeductCreditsAsync(
        int userId,
        int amount,
        string transactionType,
        string referenceType,
        string? referenceId,
        string description,
        string? idempotencyKey = null,
        CancellationToken ct = default);

    Task<(bool Success, string? ErrorMessage)> AddCreditsAsync(
        int userId,
        int amount,
        string transactionType,
        string referenceType,
        string? referenceId,
        string description,
        string? idempotencyKey = null,
        CancellationToken ct = default);
}

public class CreditService : ICreditService
{
    private readonly HireFlowDbContext _db;
    private readonly ILogger<CreditService> _logger;

    public CreditService(HireFlowDbContext db, ILogger<CreditService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<int> GetBalanceAsync(int userId, CancellationToken ct = default)
    {
        var wallet = await _db.CreditWallets.AsNoTracking().FirstOrDefaultAsync(w => w.UserId == userId, ct);
        return wallet?.Balance ?? 0;
    }

    public async Task<bool> HasSufficientBalanceAsync(int userId, int requiredCredits, CancellationToken ct = default)
    {
        var balance = await GetBalanceAsync(userId, ct);
        return balance >= requiredCredits;
    }

    public async Task<(bool Success, string? ErrorMessage)> DeductCreditsAsync(
        int userId,
        int amount,
        string transactionType,
        string referenceType,
        string? referenceId,
        string description,
        string? idempotencyKey = null,
        CancellationToken ct = default)
    {
        if (amount <= 0)
        {
            return (false, "Số credit trừ phải lớn hơn 0");
        }

        // Check idempotency first if key provided
        if (!string.IsNullOrWhiteSpace(idempotencyKey))
        {
            var existingTx = await _db.CreditTransactions
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.IdempotencyKey == idempotencyKey, ct);
            if (existingTx != null)
            {
                // Already processed successfully
                return (true, null);
            }
        }

        var wallet = await _db.CreditWallets.FirstOrDefaultAsync(w => w.UserId == userId, ct);
        if (wallet == null)
        {
            wallet = new CreditWallet
            {
                UserId = userId,
                Balance = 0,
                UpdatedAt = DateTime.UtcNow
            };
            _db.CreditWallets.Add(wallet);
            await _db.SaveChangesAsync(ct);
        }

        if (wallet.Balance < amount)
        {
            return (false, $"Bạn không đủ credit để thực hiện thao tác này. Số dư: {wallet.Balance}, cần: {amount}");
        }

        // Concurrency-safe deduction
        wallet.Balance -= amount;
        wallet.UpdatedAt = DateTime.UtcNow;

        var transaction = new CreditTransaction
        {
            UserId = userId,
            Amount = -amount,
            TransactionType = transactionType,
            ReferenceType = referenceType,
            ReferenceId = referenceId,
            Description = description,
            IdempotencyKey = idempotencyKey,
            CreatedAt = DateTime.UtcNow
        };

        _db.CreditTransactions.Add(transaction);

        try
        {
            await _db.SaveChangesAsync(ct);
            return (true, null);
        }
        catch (DbUpdateConcurrencyException ex)
        {
            _logger.LogError(ex, "Concurrency error deducting credits for user {UserId}", userId);
            return (false, "Xung đột dữ liệu khi xử lý credit, vui lòng thử lại");
        }
    }

    public async Task<(bool Success, string? ErrorMessage)> AddCreditsAsync(
        int userId,
        int amount,
        string transactionType,
        string referenceType,
        string? referenceId,
        string description,
        string? idempotencyKey = null,
        CancellationToken ct = default)
    {
        if (amount <= 0)
        {
            return (false, "Số credit cộng phải lớn hơn 0");
        }

        if (!string.IsNullOrWhiteSpace(idempotencyKey))
        {
            var existingTx = await _db.CreditTransactions
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.IdempotencyKey == idempotencyKey, ct);
            if (existingTx != null)
            {
                return (true, null);
            }
        }

        var wallet = await _db.CreditWallets.FirstOrDefaultAsync(w => w.UserId == userId, ct);
        if (wallet == null)
        {
            wallet = new CreditWallet
            {
                UserId = userId,
                Balance = 0,
                UpdatedAt = DateTime.UtcNow
            };
            _db.CreditWallets.Add(wallet);
        }

        wallet.Balance += amount;
        wallet.UpdatedAt = DateTime.UtcNow;

        var transaction = new CreditTransaction
        {
            UserId = userId,
            Amount = amount,
            TransactionType = transactionType,
            ReferenceType = referenceType,
            ReferenceId = referenceId,
            Description = description,
            IdempotencyKey = idempotencyKey,
            CreatedAt = DateTime.UtcNow
        };

        _db.CreditTransactions.Add(transaction);

        try
        {
            await _db.SaveChangesAsync(ct);
            return (true, null);
        }
        catch (DbUpdateConcurrencyException ex)
        {
            _logger.LogError(ex, "Concurrency error adding credits for user {UserId}", userId);
            return (false, "Xung đột dữ liệu khi xử lý credit, vui lòng thử lại");
        }
    }
}

