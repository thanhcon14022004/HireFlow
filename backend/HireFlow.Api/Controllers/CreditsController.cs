using System.Security.Claims;
using HireFlow.Api.Configuration;
using HireFlow.Api.Data;
using HireFlow.Api.DTOs;
using HireFlow.Api.Entities;
using HireFlow.Api.Middleware;
using HireFlow.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Controllers;

[ApiController]
[Authorize]
public class CreditsController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly ICreditService _creditService;
    private readonly IPaymentGateway _paymentGateway;
    private readonly ISepPayService _sepPayService;
    private readonly IMoMoPaymentService _moMoService;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IAuditService _audit;
    private readonly ILogger<CreditsController> _logger;

    public CreditsController(
        HireFlowDbContext db,
        ICreditService creditService,
        IPaymentGateway paymentGateway,
        ISepPayService sepPayService,
        IMoMoPaymentService moMoService,
        IHttpClientFactory httpClientFactory,
        IAuditService audit,
        ILogger<CreditsController> logger)
    {
        _db = db;
        _creditService = creditService;
        _paymentGateway = paymentGateway;
        _sepPayService = sepPayService;
        _moMoService = moMoService;
        _httpClientFactory = httpClientFactory;
        _audit = audit;
        _logger = logger;
    }

    [HttpGet("api/credits/balance")]
    public async Task<IActionResult> GetBalance()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var balance = await _creditService.GetBalanceAsync(userId);

        var wallet = await _db.CreditWallets.AsNoTracking().FirstOrDefaultAsync(w => w.UserId == userId);

        return Ok(new CreditBalanceDto
        {
            Balance = balance,
            UpdatedAt = wallet?.UpdatedAt ?? DateTime.UtcNow
        });
    }

    [HttpGet("api/credits/transactions")]
    public async Task<IActionResult> GetTransactions()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var txs = await _db.CreditTransactions
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.CreatedAt)
            .Take(100)
            .Select(t => new CreditTransactionDto
            {
                TransactionId = t.TransactionId,
                Amount = t.Amount,
                TransactionType = t.TransactionType,
                ReferenceType = t.ReferenceType,
                ReferenceId = t.ReferenceId,
                Description = t.Description,
                CreatedAt = t.CreatedAt
            })
            .ToListAsync();

        return Ok(txs);
    }

    [HttpGet("api/credits/packages")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPackages()
    {
        var packages = await _db.CreditPackages
            .Where(p => p.IsActive)
            .OrderBy(p => p.DisplayOrder)
            .Select(p => new CreditPackageDto
            {
                CreditPackageId = p.CreditPackageId,
                Name = p.Name,
                CreditAmount = p.CreditAmount,
                PriceAmount = p.CreditAmount * 5000m, // Rate: 5,000 VND / 1 Credit
                CurrencyCode = p.CurrencyCode,
                DisplayOrder = p.DisplayOrder
            })
            .ToListAsync();

        return Ok(packages);
    }

    [HttpPost("api/credits/purchases")]
    public async Task<IActionResult> CreatePurchase([FromBody] CreatePurchaseRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        const decimal RATE_PER_CREDIT = 5000m; // 5k / 1 credit
        int creditsToPurchase;
        decimal priceAmount;
        string packageName;
        int packageId;

        if (request.CustomCredits.HasValue && request.CustomCredits.Value > 0)
        {
            creditsToPurchase = request.CustomCredits.Value;
            priceAmount = creditsToPurchase * RATE_PER_CREDIT;
            packageName = $"Nạp {creditsToPurchase} Credits (5.000đ/cr)";

            var pkg = await _db.CreditPackages.FirstOrDefaultAsync(p => p.IsActive) 
                   ?? await _db.CreditPackages.FirstOrDefaultAsync();
            if (pkg == null)
            {
                pkg = new CreditPackage
                {
                    Name = "Nạp tùy chọn",
                    CreditAmount = 1,
                    PriceAmount = 5000m,
                    CurrencyCode = "VND",
                    IsActive = true,
                    DisplayOrder = 99
                };
                _db.CreditPackages.Add(pkg);
                await _db.SaveChangesAsync();
            }
            packageId = pkg.CreditPackageId;
        }
        else if (request.CreditPackageId.HasValue && request.CreditPackageId.Value > 0)
        {
            var package = await _db.CreditPackages.FirstOrDefaultAsync(p => p.CreditPackageId == request.CreditPackageId.Value && p.IsActive);
            if (package == null)
            {
                throw new AppException("Gói credit không tồn tại hoặc đã ngừng cung cấp.", "PACKAGE_NOT_FOUND");
            }
            packageId = package.CreditPackageId;
            creditsToPurchase = package.CreditAmount;
            priceAmount = creditsToPurchase * RATE_PER_CREDIT; // 5k / credit
            packageName = package.Name;
        }
        else
        {
            throw new AppException("Vui lòng nhập hoặc chọn số lượng credit cần nạp.", "INVALID_CREDIT_AMOUNT");
        }

        var isMoMo = string.Equals(request.PaymentProvider?.Trim(), "MoMo", StringComparison.OrdinalIgnoreCase);
        var provider = isMoMo ? "MoMo" : "SepPay";

        var purchase = new CreditPurchase
        {
            UserId = userId,
            CreditPackageId = packageId,
            CreditsPurchased = creditsToPurchase,
            PriceAmount = priceAmount,
            CurrencyCode = "VND",
            PaymentProvider = provider,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        _db.CreditPurchases.Add(purchase);
        await _db.SaveChangesAsync();

        var orderCode = isMoMo ? $"MOMO_HF{purchase.CreditPurchaseId}" : $"HF{purchase.CreditPurchaseId}";
        purchase.ProviderReference = orderCode;
        await _db.SaveChangesAsync();

        string qrImageUrl;
        string? deeplink = null;
        string? momoPhone = null;
        string? bankBrand = null;
        string? accNum = null;
        string? accHolder = null;

        if (isMoMo)
        {
            qrImageUrl = _moMoService.GetQrImageUrl(purchase.PriceAmount, orderCode);
            deeplink = _moMoService.GetDeeplink(purchase.PriceAmount, orderCode);
            momoPhone = _moMoService.PhoneNumber;
            accHolder = _moMoService.AccountHolder;
        }
        else
        {
            qrImageUrl = _sepPayService.GetQrImageUrl(purchase.PriceAmount, orderCode);
            bankBrand = _sepPayService.BankBrandName;
            accNum = _sepPayService.AccountNumber;
            accHolder = _sepPayService.AccountHolder;
        }

        var qrProxyUrl = $"{Request.Scheme}://{Request.Host}/api/credits/purchases/{purchase.CreditPurchaseId}/qr";

        return Ok(new CreditPurchaseDto
        {
            CreditPurchaseId = purchase.CreditPurchaseId,
            CreditPackageId = purchase.CreditPackageId,
            PackageName = packageName,
            CreditsPurchased = purchase.CreditsPurchased,
            PriceAmount = purchase.PriceAmount,
            CurrencyCode = purchase.CurrencyCode,
            PaymentProvider = purchase.PaymentProvider,
            ProviderReference = orderCode,
            OrderCode = orderCode,
            BankBrandName = bankBrand,
            AccountNumber = accNum,
            AccountHolder = accHolder,
            QrImageUrl = qrProxyUrl,
            Deeplink = deeplink,
            MoMoPhoneNumber = momoPhone,
            Status = purchase.Status,
            PaymentUrl = deeplink ?? qrProxyUrl,
            CreatedAt = purchase.CreatedAt,
            ExpiresAt = purchase.CreatedAt.AddMinutes(2),
            RemainingSeconds = 120,
            PaidAt = purchase.PaidAt
        });
    }

    [HttpGet("api/credits/purchases/{purchaseId}/qr")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPurchaseQr(int purchaseId)
    {
        var purchase = await _db.CreditPurchases.FindAsync(purchaseId);
        if (purchase == null) return NotFound("Giao dịch không tồn tại.");

        var orderCode = purchase.ProviderReference ?? $"HF{purchase.CreditPurchaseId}";
        var isMoMo = string.Equals(purchase.PaymentProvider, "MoMo", StringComparison.OrdinalIgnoreCase);
        var qrUrl = isMoMo 
            ? _moMoService.GetQrImageUrl(purchase.PriceAmount, orderCode)
            : _sepPayService.GetQrImageUrl(purchase.PriceAmount, orderCode);

        try
        {
            var client = _httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(8);
            var bytes = await client.GetByteArrayAsync(qrUrl);
            return File(bytes, "image/png");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to proxy QR code from {QrUrl}, redirecting instead", qrUrl);
            return Redirect(qrUrl);
        }
    }

    [HttpGet("api/credits/purchases/{purchaseId}/check-sepay")]
    public async Task<IActionResult> CheckSepPayPayment(int purchaseId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _sepPayService.CheckAndProcessPaymentAsync(purchaseId, userId);
        return Ok(result);
    }

    [HttpGet("api/credits/purchases/{purchaseId}/check-momo")]
    public async Task<IActionResult> CheckMoMoPayment(int purchaseId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _moMoService.CheckAndProcessPaymentAsync(purchaseId, userId);
        return Ok(result);
    }

    [HttpPost("api/credits/purchases/{purchaseId}/simulate-momo-success")]
    public async Task<IActionResult> SimulateMoMoSuccess(int purchaseId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _moMoService.SimulateSuccessAsync(purchaseId, userId);
        return Ok(result);
    }

    [HttpPost("api/credits/purchases/momo-ipn")]
    [AllowAnonymous]
    public async Task<IActionResult> MoMoIpn([FromBody] MoMoIpnRequest ipn)
    {
        _logger.LogInformation("Received MoMo IPN for Order {OrderId}, Amount {Amt}, ResultCode: {Code}",
            ipn.OrderId, ipn.Amount, ipn.ResultCode);

        var processed = await _moMoService.ProcessIpnAsync(ipn);
        return Ok(new { success = processed });
    }

    [HttpPost("api/credits/purchases/sepay-webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> SepPayWebhook([FromBody] SepPayTransactionItem tx)
    {
        _logger.LogInformation("Received SepPay Webhook for Tx {Id}, Amount {Amt}, Content: {Content}",
            tx.Id, tx.AmountIn, tx.TransactionContent);

        var processed = await _sepPayService.ProcessIncomingTransactionAsync(tx);
        return Ok(new { success = processed });
    }

    [HttpGet("api/credits/purchases/{purchaseId}")]
    public async Task<IActionResult> GetPurchase(int purchaseId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = User.FindFirstValue(ClaimTypes.Role);

        var purchase = await _db.CreditPurchases
            .Include(p => p.Package)
            .FirstOrDefaultAsync(p => p.CreditPurchaseId == purchaseId);

        if (purchase == null)
        {
            throw new AppException("Giao dịch nạp credit không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (purchase.UserId != userId && role != "Admin")
        {
            throw new AppException("Bạn không có quyền xem giao dịch này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        return Ok(new CreditPurchaseDto
        {
            CreditPurchaseId = purchase.CreditPurchaseId,
            CreditPackageId = purchase.CreditPackageId,
            PackageName = purchase.Package?.Name ?? "Gói nạp credit",
            CreditsPurchased = purchase.CreditsPurchased,
            PriceAmount = purchase.PriceAmount,
            CurrencyCode = purchase.CurrencyCode,
            PaymentProvider = purchase.PaymentProvider,
            ProviderReference = purchase.ProviderReference,
            Status = purchase.Status,
            CreatedAt = purchase.CreatedAt,
            PaidAt = purchase.PaidAt
        });
    }

    [HttpPost("api/credits/purchases/{purchaseId}/simulate-success")]
    public async Task<IActionResult> SimulatePaymentSuccess(int purchaseId, [FromQuery] string? @ref)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var purchase = await _db.CreditPurchases
            .Include(p => p.Package)
            .FirstOrDefaultAsync(p => p.CreditPurchaseId == purchaseId);

        if (purchase == null)
        {
            throw new AppException("Giao dịch không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (purchase.UserId != userId)
        {
            throw new AppException("Bạn không sở hữu giao dịch này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        // BUY-007: Idempotency check. If already Paid, do not add credit again!
        if (purchase.Status == "Paid")
        {
            var currentBalance = await _creditService.GetBalanceAsync(userId);
            return Ok(new
            {
                message = "Giao dịch đã được thanh toán trước đó (idempotent).",
                status = "Paid",
                newBalance = currentBalance
            });
        }

        // Verify with payment gateway
        var reference = @ref ?? purchase.ProviderReference ?? string.Empty;
        var isVerified = await _paymentGateway.VerifyPaymentAsync(reference, purchase.PriceAmount);
        if (!isVerified)
        {
            purchase.Status = "Failed";
            await _db.SaveChangesAsync();
            throw new AppException("Xác minh thanh toán không thành công.", "PAYMENT_VERIFICATION_FAILED");
        }

        // Atomic update inside transaction
        using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            purchase.Status = "Paid";
            purchase.PaidAt = DateTime.UtcNow;

            var idempotencyKey = $"PAYMENT-{purchase.CreditPurchaseId}-{reference}";
            var addResult = await _creditService.AddCreditsAsync(
                userId,
                purchase.CreditsPurchased,
                "CreditPurchase",
                "Purchase",
                purchase.CreditPurchaseId.ToString(),
                $"Nạp thành công {purchase.CreditsPurchased} credit ({purchase.PriceAmount:N0} {purchase.CurrencyCode})",
                idempotencyKey);

            if (!addResult.Success)
            {
                await tx.RollbackAsync();
                throw new AppException(addResult.ErrorMessage ?? "Lỗi cộng credit.", "CREDIT_ERROR");
            }

            await _db.SaveChangesAsync();
            await tx.CommitAsync();

            await _audit.LogAsync(userId, "PaymentCompleted", "CreditPurchase", purchase.CreditPurchaseId.ToString(), $"Nạp {purchase.CreditsPurchased} credit thành công");

            var newBalance = await _creditService.GetBalanceAsync(userId);

            return Ok(new
            {
                message = $"Thanh toán thành công! Đã cộng {purchase.CreditsPurchased} credit vào ví.",
                status = "Paid",
                creditsAdded = purchase.CreditsPurchased,
                newBalance = newBalance
            });
        }
        catch (Exception)
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    [HttpPost("api/projects/{projectId}/contact-unlock")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> UnlockContact(int projectId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var project = await _db.Projects
            .Include(p => p.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .FirstOrDefaultAsync(p => p.ProjectId == projectId);

        if (project == null)
        {
            throw new AppException("Dự án không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (project.Status == "Removed")
        {
            throw new AppException("Dự án đã bị gỡ bỏ bởi ban quản trị.", "PROJECT_REMOVED");
        }

        var employerId = project.EmployerId;
        if (employerId == userId)
        {
            throw new AppException("Không thể tự mở khóa liên hệ của chính mình.", "CANNOT_UNLOCK_SELF");
        }

        // CONTACT-002 & CONTACT-003: If already unlocked, return details with 0 charge
        var alreadyUnlocked = await _db.ContactUnlocks.AnyAsync(c => c.FreelancerId == userId && c.EmployerId == employerId);
        if (alreadyUnlocked)
        {
            return Ok(new EmployerContactDto
            {
                EmployerId = employerId,
                CompanyName = project.Employer.EmployerProfile?.CompanyName,
                PublicDisplayName = project.Employer.EmployerProfile?.PublicDisplayName ?? project.Employer.FullName,
                ContactEmail = project.Employer.EmployerProfile?.ContactEmail ?? project.Employer.Email,
                ContactPhone = project.Employer.EmployerProfile?.ContactPhone,
                IsUnlocked = true
            });
        }

        // Need 4 credits
        var cost = CreditConstants.ContactUnlockCost;
        var hasCredits = await _creditService.HasSufficientBalanceAsync(userId, cost);
        if (!hasCredits)
        {
            throw new AppException($"Bạn cần {cost} credit để mở khóa thông tin liên hệ nhà tuyển dụng.", "INSUFFICIENT_CREDITS");
        }

        // Atomic unlock and charge
        using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var unlock = new ContactUnlock
            {
                FreelancerId = userId,
                EmployerId = employerId,
                ProjectId = projectId,
                UnlockedAt = DateTime.UtcNow
            };

            _db.ContactUnlocks.Add(unlock);
            await _db.SaveChangesAsync();

            var deduction = await _creditService.DeductCreditsAsync(
                userId,
                cost,
                "ContactUnlock",
                "ContactUnlock",
                unlock.ContactUnlockId.ToString(),
                $"Mở khóa liên hệ nhà tuyển dụng: {project.Employer.FullName}");

            if (!deduction.Success)
            {
                await tx.RollbackAsync();
                throw new AppException(deduction.ErrorMessage ?? "Lỗi trừ credit khi mở khóa liên hệ.", "INSUFFICIENT_CREDITS");
            }

            await tx.CommitAsync();

            await _audit.LogAsync(userId, "ContactUnlocked", "ContactUnlock", unlock.ContactUnlockId.ToString(), $"Mở khóa liên hệ NTD {employerId} (-{cost} credits)");

            return Ok(new EmployerContactDto
            {
                EmployerId = employerId,
                CompanyName = project.Employer.EmployerProfile?.CompanyName,
                PublicDisplayName = project.Employer.EmployerProfile?.PublicDisplayName ?? project.Employer.FullName,
                ContactEmail = project.Employer.EmployerProfile?.ContactEmail ?? project.Employer.Email,
                ContactPhone = project.Employer.EmployerProfile?.ContactPhone,
                IsUnlocked = true
            });
        }
        catch (DbUpdateException)
        {
            // Concurrent duplicate unlock caught by UNIQUE(FreelancerId, EmployerId)
            await tx.RollbackAsync();
            return Ok(new EmployerContactDto
            {
                EmployerId = employerId,
                CompanyName = project.Employer.EmployerProfile?.CompanyName,
                PublicDisplayName = project.Employer.EmployerProfile?.PublicDisplayName ?? project.Employer.FullName,
                ContactEmail = project.Employer.EmployerProfile?.ContactEmail ?? project.Employer.Email,
                ContactPhone = project.Employer.EmployerProfile?.ContactPhone,
                IsUnlocked = true
            });
        }
        catch (Exception)
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    [HttpGet("api/projects/{projectId}/employer-contact")]
    [Authorize]
    public async Task<IActionResult> GetEmployerContact(int projectId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = User.FindFirstValue(ClaimTypes.Role);

        var project = await _db.Projects
            .Include(p => p.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .FirstOrDefaultAsync(p => p.ProjectId == projectId);

        if (project == null)
        {
            throw new AppException("Dự án không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var isOwner = (project.EmployerId == userId);
        var hasApplied = await _db.Applications.AnyAsync(a => a.ProjectId == projectId && a.FreelancerId == userId);
        var isUnlocked = isOwner || role == "Admin" || hasApplied;

        if (!isUnlocked)
        {
            throw new AppException("Bạn cần nộp hồ sơ ứng tuyển (Apply) vào tin này trước để lấy thông tin liên hệ nhà tuyển dụng.", "APPLICATION_REQUIRED", System.Net.HttpStatusCode.Forbidden);
        }

        return Ok(new EmployerContactDto
        {
            EmployerId = project.EmployerId,
            CompanyName = project.Employer.EmployerProfile?.CompanyName,
            PublicDisplayName = project.Employer.EmployerProfile?.PublicDisplayName ?? project.Employer.FullName,
            ContactEmail = project.Employer.EmployerProfile?.ContactEmail ?? project.Employer.Email,
            ContactPhone = project.Employer.EmployerProfile?.ContactPhone,
            IsUnlocked = true
        });
    }
}

