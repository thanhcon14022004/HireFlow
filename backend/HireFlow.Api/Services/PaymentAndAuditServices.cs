using HireFlow.Api.Data;
using HireFlow.Api.Entities;

namespace HireFlow.Api.Services;

public interface IPaymentGateway
{
    Task<string> CreateCheckoutUrlAsync(CreditPurchase purchase);
    Task<bool> VerifyPaymentAsync(string providerReference, decimal expectedAmount);
}

public class DevPaymentGateway : IPaymentGateway
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<DevPaymentGateway> _logger;

    public DevPaymentGateway(IConfiguration configuration, ILogger<DevPaymentGateway> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public Task<string> CreateCheckoutUrlAsync(CreditPurchase purchase)
    {
        // Development simulator checkout URL
        var simulationEnabled = _configuration.GetValue<bool>("PaymentGateway:EnableSimulation", true);
        if (!simulationEnabled)
        {
            throw new InvalidOperationException("Cổng thanh toán thực tế chưa được cấu hình cho môi trường này.");
        }

        var providerRef = purchase.ProviderReference ?? $"DEV-PAY-{Guid.NewGuid():N}";
        _logger.LogInformation("Creating simulated checkout for Purchase {PurchaseId}, Ref: {Ref}", purchase.CreditPurchaseId, providerRef);

        var url = $"/api/credits/purchases/{purchase.CreditPurchaseId}/simulate-success?ref={providerRef}";
        return Task.FromResult(url);
    }

    public Task<bool> VerifyPaymentAsync(string providerReference, decimal expectedAmount)
    {
        // For development simulator, returns true if reference starts with DEV-PAY
        if (!string.IsNullOrWhiteSpace(providerReference) && providerReference.StartsWith("DEV-PAY"))
        {
            return Task.FromResult(true);
        }

        return Task.FromResult(false);
    }
}

public interface IEmailService
{
    Task SendPasswordResetCodeAsync(string toEmail, string code);
}

public class DevEmailService : IEmailService
{
    private readonly ILogger<DevEmailService> _logger;

    public DevEmailService(ILogger<DevEmailService> logger)
    {
        _logger = logger;
    }

    public Task SendPasswordResetCodeAsync(string toEmail, string code)
    {
        _logger.LogInformation("==================================================");
        _logger.LogInformation("[DEV EMAIL] Password reset code for {Email}: {Code}", toEmail, code);
        _logger.LogInformation("==================================================");
        return Task.CompletedTask;
    }
}

public interface IAuditService
{
    Task LogAsync(int? actorUserId, string action, string entityType, string? entityId, string? details);
}

public class AuditService : IAuditService
{
    private readonly HireFlowDbContext _db;
    private readonly ILogger<AuditService> _logger;

    public AuditService(HireFlowDbContext db, ILogger<AuditService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task LogAsync(int? actorUserId, string action, string entityType, string? entityId, string? details)
    {
        try
        {
            var log = new AuditLog
            {
                ActorUserId = actorUserId,
                Action = action,
                EntityType = entityType,
                EntityId = entityId,
                Details = details,
                CreatedAt = DateTime.UtcNow
            };

            _db.AuditLogs.Add(log);
            await _db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to write audit log for action {Action}", action);
        }
    }
}

