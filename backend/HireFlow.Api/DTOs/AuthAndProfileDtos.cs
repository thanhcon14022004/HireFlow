using System.ComponentModel.DataAnnotations;

namespace HireFlow.Api.DTOs;

public class RegisterRequest
{
    [Required(ErrorMessage = "Họ và tên không được để trống")]
    [MaxLength(150)]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email không được để trống")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    [MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu không được để trống")]
    [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vai trò không được để trống")]
    public string Role { get; set; } = string.Empty; // Freelancer or Employer only
}

public class LoginRequest
{
    [Required(ErrorMessage = "Email không được để trống")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu không được để trống")]
    public string Password { get; set; } = string.Empty;
}

public class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public int ExpiryMinutes { get; set; }
    public UserInfoDto User { get; set; } = null!;
}

public class UserInfoDto
{
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public int CreditBalance { get; set; }
}

public class ForgotPasswordRequest
{
    [Required(ErrorMessage = "Email không được để trống")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    [Required(ErrorMessage = "Email không được để trống")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mã xác nhận không được để trống")]
    public string Code { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu mới không được để trống")]
    [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
    public string NewPassword { get; set; } = string.Empty;
}

public class ChangePasswordRequest
{
    [Required(ErrorMessage = "Mật khẩu hiện tại không được để trống")]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu mới không được để trống")]
    [MinLength(6, ErrorMessage = "Mật khẩu mới phải có ít nhất 6 ký tự")]
    public string NewPassword { get; set; } = string.Empty;
}

public class FreelancerProfileDto
{
    public int ProfileId { get; set; }
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? AvatarStorageKey { get; set; }
    public string? Headline { get; set; }
    public string? Bio { get; set; }
    public int? ExperienceYears { get; set; }
    public List<string> Skills { get; set; } = new();
    public DateTime UpdatedAt { get; set; }
}

public class UpdateFreelancerProfileRequest
{
    [MaxLength(150)]
    public string? FullName { get; set; }
    [MaxLength(200)]
    public string? Headline { get; set; }
    public string? Bio { get; set; }
    [Range(0, 50)]
    public int? ExperienceYears { get; set; }
    public List<string> Skills { get; set; } = new();
}

public class EmployerProfileDto
{
    public int EmployerProfileId { get; set; }
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? CompanyName { get; set; }
    public string? Description { get; set; }
    public string? PublicDisplayName { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class UpdateEmployerProfileRequest
{
    [MaxLength(150)]
    public string? FullName { get; set; }
    [MaxLength(200)]
    public string? CompanyName { get; set; }
    public string? Description { get; set; }
    [MaxLength(150)]
    public string? PublicDisplayName { get; set; }
    [EmailAddress]
    public string? ContactEmail { get; set; }
    [Phone]
    public string? ContactPhone { get; set; }
}

