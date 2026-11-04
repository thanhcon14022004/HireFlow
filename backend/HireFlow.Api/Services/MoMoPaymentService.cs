using System.Globalization;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using HireFlow.Api.Data;
using HireFlow.Api.DTOs;
using HireFlow.Api.Entities;
using HireFlow.Api.Middleware;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Services;

public class MoMoCreatePaymentResponse
{
    [JsonPropertyName("partnerCode")]
    public string? PartnerCode { get; set; }

    [JsonPropertyName("orderId")]
    public string? OrderId { get; set; }

    [JsonPropertyName("requestId")]
    public string? RequestId { get; set; }

    [JsonPropertyName("amount")]
    public long Amount { get; set; }

    [JsonPropertyName("responseTime")]
    public long ResponseTime { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonPropertyName("resultCode")]
    public int ResultCode { get; set; }

    [JsonPropertyName("payUrl")]
    public string? PayUrl { get; set; }

    [JsonPropertyName("deeplink")]
    public string? Deeplink { get; set; }

    [JsonPropertyName("qrCodeUrl")]
    public string? QrCodeUrl { get; set; }
}

public interface IMoMoPaymentService
{
    string PartnerCode { get; }
    string PhoneNumber { get; }
    string AccountHolder { get; }
    string GetQrImageUrl(decimal amount, string orderCode);
    string GetDeeplink(decimal amount, string orderCode);
    Task<MoMoCheckResultDto> CheckAndProcessPaymentAsync(int purchaseId, int userId);
    Task<bool> ProcessIpnAsync(MoMoIpnRequest ipn);
    Task<MoMoCheckResultDto> SimulateSuccessAsync(int purchaseId, int userId);
}

public class MoMoPaymentService : IMoMoPaymentService
{
    private readonly HireFlowDbContext _db;
    private readonly ICreditService _creditService;
    private readonly IAuditService _audit;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _config;
    private readonly ILogger<MoMoPaymentService> _logger;

    public MoMoPaymentService(
        HireFlowDbContext db,
        ICreditService creditService,
        IAuditService audit,
        IHttpClientFactory httpClientFactory,
        IConfiguration config,
        ILogger<MoMoPaymentService> logger)
    {
        _db = db;
        _creditService = creditService;
        _audit = audit;
        _httpClientFactory = httpClientFactory;
        _config = config;
        _logger = logger;
    }

    public string PartnerCode => _config["MoMo:PartnerCode"] ?? "MOMOHIREFLOW";
    public string PhoneNumber => _config["MoMo:PhoneNumber"] ?? "0364663787";
    public string AccountHolder => _config["MoMo:AccountHolder"] ?? "HA TRUNG THANH";
    private string AccessKey => _config["MoMo:AccessKey"] ?? "MOMO_ACCESS_KEY_DEV";
    private string SecretKey => _config["MoMo:SecretKey"] ?? "MOMO_SECRET_KEY_DEV";
    private string ApiUrl => _config["MoMo:ApiUrl"] ?? "https://test-payment.momo.vn/v2/gateway/api/create";

    public string GetQrImageUrl(decimal amount, string orderCode)
    {
        // Dynamic VietQR for MoMo e-wallet transfer with encoded memo and account holder
        var encodedName = Uri.EscapeDataString(AccountHolder);
        return $"https://api.vietqr.io/image/970422-{PhoneNumber}-compact.jpg?amount={amount:0}&addInfo={orderCode}&accountName={encodedName}";
    }

    public string GetDeeplink(decimal amount, string orderCode)
    {
        // Direct MoMo app deeplink to open MoMo payment sheet
        return $"momo://app?action=payWithApp&isScanQR=true&serviceType=transfer&phoneNumber={PhoneNumber}&amount={amount:0}&comment={orderCode}";
    }

    public static string ComputeHmacSha256(string message, string secretKey)
    {
        var keyBytes = Encoding.UTF8.GetBytes(secretKey);
        var messageBytes = Encoding.UTF8.GetBytes(message);
        using var hmac = new HMACSHA256(keyBytes);
        var hashBytes = hmac.ComputeHash(messageBytes);
        return BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant();
    }

    public async Task<MoMoCheckResultDto> CheckAndProcessPaymentAsync(int purchaseId, int userId)
    {
        var purchase = await _db.CreditPurchases
            .Include(p => p.Package)
            .FirstOrDefaultAsync(p => p.CreditPurchaseId == purchaseId);

        if (purchase == null)
        {
            throw new AppException("Giao dịch không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (purchase.UserId != userId)
        {
            throw new AppException("Bạn không có quyền truy cập giao dịch này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        // 1. If already Paid, return success immediately (idempotent)
        if (purchase.Status == "Paid")
        {
            var currentBal = await _creditService.GetBalanceAsync(userId);
            return new MoMoCheckResultDto
            {
                Success = true,
                Status = "Paid",
                CreditsAdded = purchase.CreditsPurchased,
                NewBalance = currentBal,
                Message = "Giao dịch MoMo đã được thanh toán thành công.",
                RemainingSeconds = 0
            };
        }

        // 2. Check 2-minute expiration timeout
        var remainingSeconds = (int)Math.Max(0, (purchase.CreatedAt.AddMinutes(2) - DateTime.UtcNow).TotalSeconds);
        if (remainingSeconds <= 0)
        {
            if (purchase.Status == "Pending")
            {
                purchase.Status = "Expired";
                await _db.SaveChangesAsync();
                _logger.LogInformation("MoMo Purchase {PurchaseId} expired after 2 minutes", purchaseId);
            }

            return new MoMoCheckResultDto
            {
                Success = false,
                Status = "Expired",
                Message = "Phiên giao dịch MoMo đã hết hạn 2 phút. Giao dịch đã tự động hủy.",
                RemainingSeconds = 0
            };
        }

        return new MoMoCheckResultDto
        {
            Success = false,
            Status = "Pending",
            Message = "Đang chờ quét mã thanh toán MoMo...",
            RemainingSeconds = remainingSeconds
        };
    }

    public async Task<MoMoCheckResultDto> SimulateSuccessAsync(int purchaseId, int userId)
    {
        var purchase = await _db.CreditPurchases
            .Include(p => p.Package)
            .FirstOrDefaultAsync(p => p.CreditPurchaseId == purchaseId);

        if (purchase == null)
        {
            throw new AppException("Giao dịch không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (purchase.UserId != userId)
        {
            throw new AppException("Bạn không có quyền thực hiện giao dịch này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        if (purchase.Status == "Paid")
        {
            var currentBal = await _creditService.GetBalanceAsync(userId);
            return new MoMoCheckResultDto
            {
                Success = true,
                Status = "Paid",
                CreditsAdded = purchase.CreditsPurchased,
                NewBalance = currentBal,
                Message = "Giao dịch đã được thanh toán trước đó (idempotent).",
                RemainingSeconds = 0
            };
        }

        var orderCode = purchase.ProviderReference ?? $"MOMO_HF{purchase.CreditPurchaseId}";
        var mockTransId = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString();

        using var dbTx = await _db.Database.BeginTransactionAsync();
        try
        {
            purchase.Status = "Paid";
            purchase.PaidAt = DateTime.UtcNow;
            purchase.PaymentProvider = "MoMo";
            purchase.ProviderReference = $"{orderCode}|MoMoTx:{mockTransId}";

            var idempotencyKey = $"MOMO-PAYMENT-{purchase.CreditPurchaseId}-{mockTransId}";
            var addResult = await _creditService.AddCreditsAsync(
                userId,
                purchase.CreditsPurchased,
                "CreditPurchase",
                "Purchase",
                purchase.CreditPurchaseId.ToString(),
                $"Nạp {purchase.CreditsPurchased} credit qua Ví MoMo ({purchase.PriceAmount:N0}đ - Mã GD MoMo #{mockTransId})",
                idempotencyKey);

            if (!addResult.Success)
            {
                await dbTx.RollbackAsync();
                return new MoMoCheckResultDto
                {
                    Success = false,
                    Status = "Failed",
                    Message = addResult.ErrorMessage ?? "Lỗi cộng credit.",
                    RemainingSeconds = 0
                };
            }

            await _db.SaveChangesAsync();
            await dbTx.CommitAsync();

            await _audit.LogAsync(
                userId,
                "PaymentCompleted",
                "CreditPurchase",
                purchase.CreditPurchaseId.ToString(),
                $"Thanh toán MoMo thành công: Đơn {orderCode}, số tiền {purchase.PriceAmount:N0}đ, cộng {purchase.CreditsPurchased} credit");

            var newBal = await _creditService.GetBalanceAsync(userId);

            return new MoMoCheckResultDto
            {
                Success = true,
                Status = "Paid",
                CreditsAdded = purchase.CreditsPurchased,
                NewBalance = newBal,
                Message = "Thanh toán thành công qua Ví MoMo!",
                RemainingSeconds = 0
            };
        }
        catch (Exception ex)
        {
            await dbTx.RollbackAsync();
            _logger.LogError(ex, "Error simulating MoMo payment for purchase {PurchaseId}", purchaseId);
            throw;
        }
    }

    public async Task<bool> ProcessIpnAsync(MoMoIpnRequest ipn)
    {
        if (ipn.ResultCode != 0)
        {
            _logger.LogWarning("MoMo IPN reported non-zero resultCode: {ResultCode}, msg: {Msg}", ipn.ResultCode, ipn.Message);
            return false;
        }

        var orderId = ipn.OrderId;
        if (string.IsNullOrWhiteSpace(orderId)) return false;

        var purchase = await _db.CreditPurchases
            .FirstOrDefaultAsync(p => p.ProviderReference != null && p.ProviderReference.StartsWith(orderId) && p.Status == "Pending");

        if (purchase == null)
        {
            _logger.LogWarning("MoMo IPN could not find matching pending purchase for OrderId: {OrderId}", orderId);
            return false;
        }

        var result = await SimulateSuccessAsync(purchase.CreditPurchaseId, purchase.UserId);
        return result.Success;
    }
}

