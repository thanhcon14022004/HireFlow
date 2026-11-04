namespace HireFlow.Api.Entities;

public class Report
{
    public int ReportId { get; set; }
    public int ReporterUserId { get; set; }
    public string TargetType { get; set; } = "Project"; // User, Project, Other
    public int TargetId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = "Pending"; // Pending, Reviewing, Resolved, Rejected
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }
    public int? ResolvedByUserId { get; set; }

    public User ReporterUser { get; set; } = null!;
    public User? ResolvedByUser { get; set; }
}

public class AuditLog
{
    public int AuditLogId { get; set; }
    public int? ActorUserId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public string? EntityId { get; set; }
    public string? Details { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? ActorUser { get; set; }
}

public class PasswordResetToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty; // 6-digit numeric verification code for mobile/friendly UX
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}

public class UserNotification
{
    public int NotificationId { get; set; }
    public int UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "ApplicationStatus"; // ApplicationStatus, System
    public int? ReferenceId { get; set; } // ApplicationId or ProjectId
    public bool IsRead { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}

