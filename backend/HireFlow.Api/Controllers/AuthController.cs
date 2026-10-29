using System.Security.Claims;
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
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly IPasswordHasherService _hasher;
    private readonly IJwtService _jwt;
    private readonly IEmailService _email;
    private readonly IAuditService _audit;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        HireFlowDbContext db,
        IPasswordHasherService hasher,
        IJwtService jwt,
        IEmailService email,
        IAuditService audit,
        ILogger<AuthController> logger)
    {
        _db = db;
        _hasher = hasher;
        _jwt = jwt;
        _email = email;
        _audit = audit;
        _logger = logger;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        // AUTH-006: Admin registration is disabled
        if (string.Equals(request.Role, "Admin", StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException("Đăng ký tài khoản Quản trị viên (Admin) bị cấm.", "ADMIN_REGISTRATION_FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        var normalizedRole = request.Role.Trim();
        if (!string.Equals(normalizedRole, "Freelancer", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(normalizedRole, "Employer", StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException("Vai trò đăng ký không hợp lệ. Chỉ chấp nhận 'Freelancer' hoặc 'Employer'.", "INVALID_ROLE");
        }

        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        if (await _db.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail))
        {
            throw new AppException("Email này đã được sử dụng bởi một tài khoản khác.", "EMAIL_ALREADY_EXISTS", System.Net.HttpStatusCode.Conflict);
        }

        var user = new User
        {
            FullName = request.FullName.Trim(),
            Email = normalizedEmail,
            PasswordHash = _hasher.HashPassword(request.Password),
            Role = char.ToUpper(normalizedRole[0]) + normalizedRole[1..].ToLower(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        // Initialize role-specific profile
        if (user.Role == "Freelancer")
        {
            _db.FreelancerProfiles.Add(new FreelancerProfile
            {
                UserId = user.UserId,
                UpdatedAt = DateTime.UtcNow
            });
        }
        else if (user.Role == "Employer")
        {
            _db.EmployerProfiles.Add(new EmployerProfile
            {
                UserId = user.UserId,
                CompanyName = user.FullName,
                PublicDisplayName = user.FullName,
                ContactEmail = user.Email,
                UpdatedAt = DateTime.UtcNow
            });
        }

        // Initialize wallet with welcome bonus (10 credits for testing workflows)
        var wallet = new CreditWallet
        {
            UserId = user.UserId,
            Balance = 10,
            UpdatedAt = DateTime.UtcNow
        };
        _db.CreditWallets.Add(wallet);

        _db.CreditTransactions.Add(new CreditTransaction
        {
            UserId = user.UserId,
            Amount = 10,
            TransactionType = "AdminAdjustment",
            ReferenceType = "WelcomeBonus",
            Description = "Tặng 10 credit chào mừng thành viên mới",
            CreatedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();
        await _audit.LogAsync(user.UserId, "UserRegistered", "User", user.UserId.ToString(), $"Đăng ký vai trò {user.Role}");

        var (token, expiry) = _jwt.GenerateToken(user);
        return Ok(new AuthResponse
        {
            Token = token,
            ExpiryMinutes = expiry,
            User = new UserInfoDto
            {
                UserId = user.UserId,
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role,
                IsActive = user.IsActive,
                CreditBalance = wallet.Balance
            }
        });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _db.Users
            .Include(u => u.CreditWallet)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail);

        // AUTH-009: Generic message to not expose whether email exists
        if (user == null || !_hasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new AppException("Email hoặc mật khẩu không chính xác.", "INVALID_CREDENTIALS", System.Net.HttpStatusCode.Unauthorized);
        }

        // AUTH-008: Suspended accounts rejected
        if (!user.IsActive)
        {
            throw new AppException("Tài khoản của bạn đã bị khóa hoặc tạm ngưng hoạt động.", "ACCOUNT_SUSPENDED", System.Net.HttpStatusCode.Forbidden);
        }

        var (token, expiry) = _jwt.GenerateToken(user);
        await _audit.LogAsync(user.UserId, "UserLogin", "User", user.UserId.ToString(), "Đăng nhập thành công");

        return Ok(new AuthResponse
        {
            Token = token,
            ExpiryMinutes = expiry,
            User = new UserInfoDto
            {
                UserId = user.UserId,
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role,
                IsActive = user.IsActive,
                CreditBalance = user.CreditWallet?.Balance ?? 0
            }
        });
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetCurrentUser()
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdStr, out var userId))
        {
            throw new AppException("Không tìm thấy thông tin phiên đăng nhập.", "UNAUTHORIZED", System.Net.HttpStatusCode.Unauthorized);
        }

        var user = await _db.Users
            .Include(u => u.CreditWallet)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null || !user.IsActive)
        {
            throw new AppException("Tài khoản không tồn tại hoặc đã bị khóa.", "ACCOUNT_INACTIVE", System.Net.HttpStatusCode.Forbidden);
        }

        return Ok(new UserInfoDto
        {
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role,
            IsActive = user.IsActive,
            CreditBalance = user.CreditWallet?.Balance ?? 0
        });
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail);

        // Silent return if user not found to prevent user enumeration
        if (user == null)
        {
            return Ok(new { message = "Nếu email tồn tại trong hệ thống, mã xác nhận đã được gửi đi." });
        }

        // Invalidate old tokens
        var existingTokens = await _db.PasswordResetTokens.Where(t => t.UserId == user.UserId && !t.IsUsed).ToListAsync();
        foreach (var t in existingTokens) t.IsUsed = true;

        // Generate 6 digit code
        var code = Random.Shared.Next(100000, 999999).ToString();
        var resetToken = new PasswordResetToken
        {
            UserId = user.UserId,
            Code = code,
            TokenHash = _hasher.HashPassword(code),
            ExpiresAt = DateTime.UtcNow.AddMinutes(15),
            IsUsed = false,
            CreatedAt = DateTime.UtcNow
        };

        _db.PasswordResetTokens.Add(resetToken);
        await _db.SaveChangesAsync();

        await _email.SendPasswordResetCodeAsync(user.Email, code);
        await _audit.LogAsync(user.UserId, "PasswordResetRequested", "User", user.UserId.ToString(), "Yêu cầu mã đặt lại mật khẩu");

        return Ok(new { message = "Nếu email tồn tại trong hệ thống, mã xác nhận đã được gửi đi." });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail);
        if (user == null)
        {
            throw new AppException("Yêu cầu không hợp lệ hoặc mã xác nhận đã hết hạn.", "INVALID_RESET_REQUEST");
        }

        var tokenRecord = await _db.PasswordResetTokens
            .Where(t => t.UserId == user.UserId && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        if (tokenRecord == null || tokenRecord.Code != request.Code.Trim())
        {
            throw new AppException("Mã xác nhận không đúng hoặc đã hết hạn (hiệu lực 15 phút).", "INVALID_OR_EXPIRED_CODE");
        }

        tokenRecord.IsUsed = true;
        user.PasswordHash = _hasher.HashPassword(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await _audit.LogAsync(user.UserId, "PasswordResetCompleted", "User", user.UserId.ToString(), "Đặt lại mật khẩu thành công bằng mã OTP");

        return Ok(new { message = "Đặt lại mật khẩu thành công. Vui lòng đăng nhập bằng mật khẩu mới." });
    }

    [Authorize]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdStr, out var userId))
        {
            throw new AppException("Chưa đăng nhập.", "UNAUTHORIZED", System.Net.HttpStatusCode.Unauthorized);
        }

        var user = await _db.Users.FindAsync(userId);
        if (user == null)
        {
            throw new AppException("Tài khoản không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (!_hasher.VerifyPassword(request.CurrentPassword, user.PasswordHash))
        {
            throw new AppException("Mật khẩu hiện tại không chính xác.", "INCORRECT_CURRENT_PASSWORD");
        }

        user.PasswordHash = _hasher.HashPassword(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await _audit.LogAsync(user.UserId, "PasswordChanged", "User", user.UserId.ToString(), "Đổi mật khẩu thành công");

        return Ok(new { message = "Đổi mật khẩu thành công." });
    }
}
