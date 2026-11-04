using System.Globalization;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;
using HireFlow.Api.Data;
using HireFlow.Api.DTOs;
using HireFlow.Api.Entities;
using HireFlow.Api.Middleware;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Services;

public class SepPayTransactionItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("bank_brand_name")]
    public string BankBrandName { get; set; } = string.Empty;

    [JsonPropertyName("account_number")]
    public string AccountNumber { get; set; } = string.Empty;

    [JsonPropertyName("transaction_date")]
    public string TransactionDate { get; set; } = string.Empty;

    [JsonPropertyName("amount_out")]
    public string AmountOut { get; set; } = "0";

    [JsonPropertyName("amount_in")]
    public string AmountIn { get; set; } = "0";

    [JsonPropertyName("transaction_content")]
    public string TransactionContent { get; set; } = string.Empty;

    [JsonPropertyName("reference_number")]
    public string? ReferenceNumber { get; set; }

    [JsonPropertyName("code")]
    public string? Code { get; set; }
}

public class SepPayTransactionsResponse
{
    [JsonPropertyName("status")]
    public int Status { get; set; }

    [JsonPropertyName("error")]
    public string? Error { get; set; }

    [JsonPropertyName("transactions")]
    public List<SepPayTransactionItem> Transactions { get; set; } = new();
}

public interface ISepPayService
{
    string BankBrandName { get; }
    string AccountNumber { get; }
    string AccountHolder { get; }
    string GetQrImageUrl(decimal amount, string orderCode);
    Task<List<SepPayTransactionItem>> FetchTransactionsAsync(int limit = 20);
    Task<SepPayCheckResultDto> CheckAndProcessPaymentAsync(int purchaseId, int userId);
    Task<bool> ProcessIncomingTransactionAsync(SepPayTransactionItem tx);
}

public class SepPayService : ISepPayService
{
    private readonly HireFlowDbContext _db;
    private readonly ICreditService _creditService;
    private readonly IAuditService _audit;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _config;
    private readonly ILogger<SepPayService> _logger;

    public SepPayService(
        HireFlowDbContext db,
        ICreditService creditService,
        IAuditService audit,
        IHttpClientFactory httpClientFactory,
        IConfiguration config,
        ILogger<SepPayService> logger)
    {
        _db = db;
        _creditService = creditService;
        _audit = audit;
        _httpClientFactory = httpClientFactory;
        _config = config;
        _logger = logger;
    }

    public string BankBrandName => _config["SepPay:BankBrandName"] ?? "ACB";
    public string AccountNumber => _config["SepPay:AccountNumber"] ?? "27655931";
    public string AccountHolder => _config["SepPay:AccountHolder"] ?? "HA TRUNG THANH";
    private string ApiToken => _config["SepPay:ApiToken"] ?? "XWPNYEIQU6QXFEML5HU2XKVZSBGOQBRMNDTBA7NG2CZCYUISIVPLDKMKGFDKOJYI";
    private string ApiUrl => _config["SepPay:ApiUrl"] ?? "https://my.sepay.vn/userapi/transactions/list";

    public string GetQrImageUrl(decimal amount, string orderCode)
    {
        // Dynamic VietQR image generated via SepPay's standard QR service
        return $"https://qr.sepay.vn/img?acc={AccountNumber}&bank={BankBrandName}&amount={amount:0}&des={orderCode}";
    }

    public async Task<List<SepPayTransactionItem>> FetchTransactionsAsync(int limit = 20)
    {
        try
        {
            var client = _httpClientFactory.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", ApiToken);
            client.Timeout = TimeSpan.FromSeconds(10);

            var url = $"{ApiUrl}?limit={limit}";
            var response = await client.GetAsync(url);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("SepPay API returned HTTP {StatusCode}", response.StatusCode);
                return new List<SepPayTransactionItem>();
            }

            var json = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<SepPayTransactionsResponse>(json);
            return result?.Transactions ?? new List<SepPayTransactionItem>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching transactions from SepPay API");
            return new List<SepPayTransactionItem>();
        }
    }

    public async Task<SepPayCheckResultDto> CheckAndProcessPaymentAsync(int purchaseId, int userId)
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
            return new SepPayCheckResultDto
            {
                Success = true,
                Status = "Paid",
                CreditsAdded = purchase.CreditsPurchased,
                NewBalance = currentBal,
                Message = "Giao dịch đã được thanh toán thành công.",
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
                _logger.LogInformation("Purchase {PurchaseId} expired after 2 minutes", purchaseId);
            }

            return new SepPayCheckResultDto
            {
                Success = false,
                Status = "Expired",
                Message = "Phiên giao dịch đã hết hạn 2 phút. Giao dịch đã tự động hủy.",
                RemainingSeconds = 0
            };
        }

        // 3. Query SepPay transactions API for matching bank movement
        var orderCode = purchase.ProviderReference ?? $"HF{purchase.CreditPurchaseId}";
        var txs = await FetchTransactionsAsync(30);

        var matchingTx = txs.FirstOrDefault(tx =>
        {
            if (string.IsNullOrWhiteSpace(tx.AmountIn)) return false;
            if (!decimal.TryParse(tx.AmountIn, NumberStyles.Any, CultureInfo.InvariantCulture, out var amt)) return false;
            if (amt < purchase.PriceAmount) return false;

            var content = tx.TransactionContent ?? string.Empty;
            return content.Contains(orderCode, StringComparison.OrdinalIgnoreCase);
        });

        if (matchingTx != null)
        {
            // Verify if this SepPay tx id was already used to prevent duplicate credit
            var alreadyUsed = await _db.CreditPurchases
                .AnyAsync(p => p.Status == "Paid" && p.ProviderReference != null && p.ProviderReference.Contains($"SepPayTx:{matchingTx.Id}"));

            if (alreadyUsed)
            {
                _logger.LogWarning("SepPay transaction {TxId} was already applied to another purchase", matchingTx.Id);
            }
            else
            {
                using var dbTx = await _db.Database.BeginTransactionAsync();
                try
                {
                    purchase.Status = "Paid";
                    purchase.PaidAt = DateTime.UtcNow;
                    purchase.PaymentProvider = "SepPay";
                    purchase.ProviderReference = $"{orderCode}|SepPayTx:{matchingTx.Id}";

                    var idempotencyKey = $"SEPAY-PAYMENT-{purchase.CreditPurchaseId}-{matchingTx.Id}";
                    var addResult = await _creditService.AddCreditsAsync(
                        userId,
                        purchase.CreditsPurchased,
                        "CreditPurchase",
                        "Purchase",
                        purchase.CreditPurchaseId.ToString(),
                        $"Nạp {purchase.CreditsPurchased} credit qua SepPay (ACB {decimal.Parse(matchingTx.AmountIn):N0}đ - GD #{matchingTx.Id})",
                        idempotencyKey);

                    if (!addResult.Success)
                    {
                        await dbTx.RollbackAsync();
                        return new SepPayCheckResultDto
                        {
                            Success = false,
                            Status = "Failed",
                            Message = addResult.ErrorMessage ?? "Lỗi cộng credit.",
                            RemainingSeconds = remainingSeconds
                        };
                    }

                    await _db.SaveChangesAsync();
                    await dbTx.CommitAsync();

                    await _audit.LogAsync(
                        userId,
                        "PaymentCompleted",
                        "CreditPurchase",
                        purchase.CreditPurchaseId.ToString(),
                        $"Thanh toán SepPay thành công: Đơn {orderCode}, số tiền {matchingTx.AmountIn}đ, cộng {purchase.CreditsPurchased} credit");

                    var newBal = await _creditService.GetBalanceAsync(userId);

                    return new SepPayCheckResultDto
                    {
                        Success = true,
                        Status = "Paid",
                        CreditsAdded = purchase.CreditsPurchased,
                        NewBalance = newBal,
                        Message = "Thanh toán thành công qua SepPay!",
                        RemainingSeconds = 0
                    };
                }
                catch (Exception ex)
                {
                    await dbTx.RollbackAsync();
                    _logger.LogError(ex, "Error processing SepPay payment for purchase {PurchaseId}", purchaseId);
                    throw;
                }
            }
        }

        return new SepPayCheckResultDto
        {
            Success = false,
            Status = "Pending",
            Message = "Đang chờ thanh toán...",
            RemainingSeconds = remainingSeconds
        };
    }

    public async Task<bool> ProcessIncomingTransactionAsync(SepPayTransactionItem tx)
    {
        if (string.IsNullOrWhiteSpace(tx.AmountIn)) return false;
        if (!decimal.TryParse(tx.AmountIn, NumberStyles.Any, CultureInfo.InvariantCulture, out var amt)) return false;

        var content = tx.TransactionContent ?? string.Empty;
        if (string.IsNullOrWhiteSpace(content)) return false;

        // Find pending purchase where ProviderReference appears in transaction content
        var purchases = await _db.CreditPurchases
            .Where(p => p.Status == "Pending")
            .ToListAsync();

        var purchase = purchases.FirstOrDefault(p =>
            p.ProviderReference != null &&
            content.Contains(p.ProviderReference, StringComparison.OrdinalIgnoreCase) &&
            amt >= p.PriceAmount);

        if (purchase == null) return false;

        var checkRes = await CheckAndProcessPaymentAsync(purchase.CreditPurchaseId, purchase.UserId);
        return checkRes.Success;
    }
}
