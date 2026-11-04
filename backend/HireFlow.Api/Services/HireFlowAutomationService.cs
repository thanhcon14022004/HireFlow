using HireFlow.Api.Data;
using HireFlow.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Services;

public interface IHireFlowAutomationService
{
    Task<AutomationRunResult> RunAutomationCycleAsync(CancellationToken cancellationToken = default);
}

public class AutomationRunResult
{
    public int ProjectsClosed { get; set; }
    public int PurchasesExpired { get; set; }
    public int PurchasesAutoReconciled { get; set; }
    public int TokensCleanedUp { get; set; }
    public DateTime ExecutedAt { get; set; } = DateTime.UtcNow;
}

public class HireFlowAutomationService : BackgroundService, IHireFlowAutomationService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<HireFlowAutomationService> _logger;
    private readonly TimeSpan _pollInterval = TimeSpan.FromSeconds(15);

    public HireFlowAutomationService(
        IServiceScopeFactory scopeFactory,
        ILogger<HireFlowAutomationService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("HireFlow Automation Background Service is starting...");

        // Small initial delay on startup
        await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunAutomationCycleAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during HireFlow automation cycle execution");
            }

            try
            {
                await Task.Delay(_pollInterval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }

        _logger.LogInformation("HireFlow Automation Background Service is stopped.");
    }

    public async Task<AutomationRunResult> RunAutomationCycleAsync(CancellationToken cancellationToken = default)
    {
        var result = new AutomationRunResult();

        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<HireFlowDbContext>();
        var sepPayService = scope.ServiceProvider.GetRequiredService<ISepPayService>();
        var audit = scope.ServiceProvider.GetRequiredService<IAuditService>();
        var now = DateTime.UtcNow;

        // 1. Tự động đóng dự án quá hạn (Auto-close Expired Projects)
        var expiredProjects = await db.Projects
            .Where(p => p.Status == "Open" && p.Deadline.HasValue && p.Deadline.Value < now)
            .ToListAsync(cancellationToken);

        if (expiredProjects.Count > 0)
        {
            foreach (var p in expiredProjects)
            {
                p.Status = "Closed";
                p.UpdatedAt = now;
                _logger.LogInformation("Auto-closed expired project #{ProjectId} - '{Title}' (Deadline was {Deadline})",
                    p.ProjectId, p.Title, p.Deadline);

                await audit.LogAsync(
                    p.EmployerId,
                    "ProjectAutoClosed",
                    "Project",
                    p.ProjectId.ToString(),
                    $"Dự án đã tự động đóng nhận hồ sơ do hết hạn ({p.Deadline:yyyy-MM-dd HH:mm})");
            }

            await db.SaveChangesAsync(cancellationToken);
            result.ProjectsClosed = expiredProjects.Count;
        }

        // 2. Tự động kiểm tra & khớp đơn nạp SepPay ngầm (Auto-reconcile Active Pending SepPay Purchases)
        var pendingPurchases = await db.CreditPurchases
            .Where(p => p.Status == "Pending")
            .ToListAsync(cancellationToken);

        if (pendingPurchases.Count > 0)
        {
            // Tách các đơn còn hiệu lực và các đơn đã quá 2 phút
            var activePending = pendingPurchases.Where(p => p.CreatedAt.AddMinutes(2) >= now).ToList();
            var expiredPending = pendingPurchases.Where(p => p.CreatedAt.AddMinutes(2) < now).ToList();

            // Auto-reconcile matching bank transfers for active purchases
            if (activePending.Count > 0)
            {
                try
                {
                    var recentBankTxs = await sepPayService.FetchTransactionsAsync(30);
                    if (recentBankTxs.Count > 0)
                    {
                        foreach (var purchase in activePending)
                        {
                            var orderCode = purchase.ProviderReference ?? $"HF{purchase.CreditPurchaseId}";
                            var hasMatch = recentBankTxs.Any(tx =>
                            {
                                if (string.IsNullOrWhiteSpace(tx.AmountIn)) return false;
                                if (!decimal.TryParse(tx.AmountIn, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var amt)) return false;
                                if (amt < purchase.PriceAmount) return false;
                                var content = tx.TransactionContent ?? string.Empty;
                                return content.Contains(orderCode, StringComparison.OrdinalIgnoreCase);
                            });

                            if (hasMatch)
                            {
                                var checkRes = await sepPayService.CheckAndProcessPaymentAsync(purchase.CreditPurchaseId, purchase.UserId);
                                if (checkRes.Success)
                                {
                                    _logger.LogInformation("Auto-reconciled SepPay payment for Order {OrderCode}, added {Credits} credits to User {UserId}",
                                        orderCode, purchase.CreditsPurchased, purchase.UserId);
                                    result.PurchasesAutoReconciled++;
                                }
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "SepPay background fetch encountered an issue");
                }
            }

            // Auto-expire stale purchases (> 2 minutes)
            if (expiredPending.Count > 0)
            {
                foreach (var ep in expiredPending)
                {
                    ep.Status = "Expired";
                    _logger.LogInformation("Auto-expired stale purchase #{PurchaseId} ({OrderCode}) after 2 minutes timeout",
                        ep.CreditPurchaseId, ep.ProviderReference);
                }
                await db.SaveChangesAsync(cancellationToken);
                result.PurchasesExpired = expiredPending.Count;
            }
        }

        // 3. Tự động dọn dẹp các token quên mật khẩu quá hạn > 24 giờ
        var yesterday = now.AddDays(-1);
        var oldTokens = await db.PasswordResetTokens
            .Where(t => !t.IsUsed && t.ExpiresAt < yesterday)
            .ToListAsync(cancellationToken);

        if (oldTokens.Count > 0)
        {
            foreach (var t in oldTokens)
            {
                t.IsUsed = true;
            }
            await db.SaveChangesAsync(cancellationToken);
            result.TokensCleanedUp = oldTokens.Count;
        }

        return result;
    }
}
