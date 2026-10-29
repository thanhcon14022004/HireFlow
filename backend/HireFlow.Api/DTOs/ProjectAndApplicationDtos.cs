using System.ComponentModel.DataAnnotations;

namespace HireFlow.Api.DTOs;

public class ProjectSummaryDto
{
    public int ProjectId { get; set; }
    public int EmployerId { get; set; }
    public string EmployerName { get; set; } = string.Empty;
    public string? CompanyName { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal? BudgetMin { get; set; }
    public decimal? BudgetMax { get; set; }
    public string CurrencyCode { get; set; } = "VND";
    public string? ExperienceLevel { get; set; }
    public DateTime? Deadline { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? PublishedAt { get; set; }
    public List<string> Skills { get; set; } = new();
    public int ApplicantCount { get; set; }
}

public class ProjectDetailDto : ProjectSummaryDto
{
    // Contact information is only included if explicitly unlocked or requester is the employer
    public bool IsContactUnlocked { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public bool HasApplied { get; set; }
    public int? MyApplicationId { get; set; }
    public string? MyApplicationStatus { get; set; }
}

public class CreateProjectRequest
{
    [Required(ErrorMessage = "Tiêu đề dự án không được để trống")]
    [MaxLength(250)]
    public string Title { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mô tả dự án không được để trống")]
    public string Description { get; set; } = string.Empty;

    public decimal? BudgetMin { get; set; }
    public decimal? BudgetMax { get; set; }
    public string CurrencyCode { get; set; } = "VND";
    public string? ExperienceLevel { get; set; }
    public DateTime? Deadline { get; set; }
    public List<string> Skills { get; set; } = new();
}

public class UpdateProjectRequest
{
    [Required(ErrorMessage = "Tiêu đề dự án không được để trống")]
    [MaxLength(250)]
    public string Title { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mô tả dự án không được để trống")]
    public string Description { get; set; } = string.Empty;

    public decimal? BudgetMin { get; set; }
    public decimal? BudgetMax { get; set; }
    public string CurrencyCode { get; set; } = "VND";
    public string? ExperienceLevel { get; set; }
    public DateTime? Deadline { get; set; }
    public List<string> Skills { get; set; } = new();
}

public class ProjectFilterRequest
{
    public string? Keyword { get; set; }
    public string? Skill { get; set; }
    public string? ExperienceLevel { get; set; }
    public decimal? MinBudget { get; set; }
    public decimal? MaxBudget { get; set; }
    public string? Status { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}

public class ApplyProjectRequest
{
    [Required(ErrorMessage = "Vui lòng chọn CV")]
    public int DocumentId { get; set; }
    public string? CoverLetter { get; set; }
}

public class ApplicationDto
{
    public int ApplicationId { get; set; }
    public int ProjectId { get; set; }
    public string ProjectTitle { get; set; } = string.Empty;
    public int FreelancerId { get; set; }
    public string FreelancerName { get; set; } = string.Empty;
    public string? FreelancerHeadline { get; set; }
    public string? FreelancerBio { get; set; }
    public int? FreelancerExperienceYears { get; set; }
    public List<string> FreelancerSkills { get; set; } = new();
    public int DocumentId { get; set; }
    public string OriginalFileName { get; set; } = string.Empty;
    public string? CoverLetter { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime AppliedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public List<ApplicationStatusHistoryDto> StatusHistories { get; set; } = new();
}

public class UpdateApplicationStatusRequest
{
    [Required(ErrorMessage = "Trạng thái không được để trống")]
    public string Status { get; set; } = string.Empty; // Reviewing, Shortlisted, Accepted, Rejected
}

public class ApplicationStatusHistoryDto
{
    public int HistoryId { get; set; }
    public string? OldStatus { get; set; }
    public string NewStatus { get; set; } = string.Empty;
    public string ChangedByUserName { get; set; } = string.Empty;
    public DateTime ChangedAt { get; set; }
}
