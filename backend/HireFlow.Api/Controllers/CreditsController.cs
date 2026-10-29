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
    private readonly IAuditService _audit;
    private readonly ILogger<CreditsController> _logger;

    public CreditsController(
        HireFlowDbContext db,
        ICreditService creditService,
        IPaymentGateway paymentGateway,
        IAuditService audit,
        ILogger<CreditsController> logger)
    {
        _db = db;
        _creditService = creditService;
        _paymentGateway = paymentGateway;
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
                PriceAmount = p.PriceAmount,
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

        var package = await _db.CreditPackages.FirstOrDefaultAsync(p => p.CreditPackageId == request.CreditPackageId && p.IsActive);
        if (package == null)
        {
            throw new AppException("Gói credit không tồn tại hoặc đã ngừng cung cấp.", "PACKAGE_NOT_FOUND");
        }

        var providerRef = $"DEV-PAY-{Guid.NewGuid():N}";

        var purchase = new CreditPurchase
        {
            UserId = userId,
            CreditPackageId = package.CreditPackageId,
            CreditsPurchased = package.CreditAmount,
            PriceAmount = package.PriceAmount,
            CurrencyCode = package.CurrencyCode,
            PaymentProvider = "DevSimulator",
            ProviderReference = providerRef,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        _db.CreditPurchases.Add(purchase);
        await _db.SaveChangesAsync();

        var checkoutUrl = await _paymentGateway.CreateCheckoutUrlAsync(purchase);

        return Ok(new CreditPurchaseDto
        {
            CreditPurchaseId = purchase.CreditPurchaseId,
            CreditPackageId = purchase.CreditPackageId,
            PackageName = package.Name,
            CreditsPurchased = purchase.CreditsPurchased,
            PriceAmount = purchase.PriceAmount,
            CurrencyCode = purchase.CurrencyCode,
            PaymentProvider = purchase.PaymentProvider,
            ProviderReference = purchase.ProviderReference,
            Status = purchase.Status,
            PaymentUrl = checkoutUrl,
            CreatedAt = purchase.CreatedAt,
            PaidAt = purchase.PaidAt
        });
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

        var employerId = project.EmployerId;

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
        var isUnlocked = isOwner || role == "Admin" || await _db.ContactUnlocks.AnyAsync(c => c.FreelancerId == userId && c.EmployerId == project.EmployerId);

        if (!isUnlocked)
        {
            throw new AppException("Thông tin liên hệ này chưa được mở khóa. Chi phí mở khóa là 4 credit.", "CONTACT_LOCKED", System.Net.HttpStatusCode.Forbidden);
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
