using System.ComponentModel.DataAnnotations;

namespace HireFlow.Api.DTOs;

public class DocumentDto
{
    public int DocumentId { get; set; }
    public string OriginalFileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = "application/pdf";
    public long FileSize { get; set; }
    public bool IsDefault { get; set; }
    public DateTime UploadedAt { get; set; }
}

public class CreditBalanceDto
{
    public int Balance { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreditTransactionDto
{
    public int TransactionId { get; set; }
    public int Amount { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public string ReferenceType { get; set; } = string.Empty;
    public string? ReferenceId { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class CreditPackageDto
{
    public int CreditPackageId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int CreditAmount { get; set; }
    public decimal PriceAmount { get; set; }
    public string CurrencyCode { get; set; } = "VND";
    public int DisplayOrder { get; set; }
}

public class CreatePurchaseRequest
{
    [Required(ErrorMessage = "Vui lòng chọn gói credit")]
    public int CreditPackageId { get; set; }
}

public class CreditPurchaseDto
{
    public int CreditPurchaseId { get; set; }
    public int CreditPackageId { get; set; }
    public string PackageName { get; set; } = string.Empty;
    public int CreditsPurchased { get; set; }
    public decimal PriceAmount { get; set; }
    public string CurrencyCode { get; set; } = "VND";
    public string PaymentProvider { get; set; } = string.Empty;
    public string? ProviderReference { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? PaymentUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? PaidAt { get; set; }
}

public class EmployerContactDto
{
    public int EmployerId { get; set; }
    public string? CompanyName { get; set; }
    public string? PublicDisplayName { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public bool IsUnlocked { get; set; }
}

public class AdminUserDto
{
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public int CreditBalance { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UpdateUserStatusRequest
{
    public bool IsActive { get; set; }
}

public class ModerateProjectRequest
{
    [Required]
    public string Status { get; set; } = string.Empty; // Open, Hidden, Removed
    public string? Reason { get; set; }
}

public class CreateReportRequest
{
    [Required]
    public string TargetType { get; set; } = "Project"; // User, Project, Other
    [Required]
    public int TargetId { get; set; }
    [Required(ErrorMessage = "Lý do báo cáo không được để trống")]
    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class ReportDto
{
    public int ReportId { get; set; }
    public int ReporterUserId { get; set; }
    public string ReporterName { get; set; } = string.Empty;
    public string TargetType { get; set; } = string.Empty;
    public int TargetId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public string? ResolvedByUserName { get; set; }
}

public class UpdateReportStatusRequest
{
    [Required]
    public string Status { get; set; } = string.Empty; // Reviewing, Resolved, Rejected
}

public class AuditLogDto
{
    public int AuditLogId { get; set; }
    public int? ActorUserId { get; set; }
    public string? ActorUserName { get; set; }
    public string Action { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public string? EntityId { get; set; }
    public string? Details { get; set; }
    public DateTime CreatedAt { get; set; }
}

