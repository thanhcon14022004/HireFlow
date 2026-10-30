namespace HireFlow.Api.Entities;

public class Project
{
    public int ProjectId { get; set; }
    public int EmployerId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal? BudgetMin { get; set; }
    public decimal? BudgetMax { get; set; }
    public string CurrencyCode { get; set; } = "VND";
    public string? ExperienceLevel { get; set; }
    public DateTime? Deadline { get; set; }
    public string Status { get; set; } = "Open"; // Open, Closed, Hidden, Removed
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PublishedAt { get; set; }

    public User Employer { get; set; } = null!;
    public ICollection<ProjectSkill> Skills { get; set; } = new List<ProjectSkill>();
    public ICollection<Application> Applications { get; set; } = new List<Application>();
}

public class ProjectSkill
{
    public int ProjectSkillId { get; set; }
    public int ProjectId { get; set; }
    public string SkillName { get; set; } = string.Empty;

    public Project Project { get; set; } = null!;
}

public class FreelancerDocument
{
    public int DocumentId { get; set; }
    public int FreelancerId { get; set; }
    public string OriginalFileName { get; set; } = string.Empty;
    public string StorageKey { get; set; } = string.Empty;
    public string ContentType { get; set; } = "application/pdf";
    public long FileSize { get; set; }
    public string? ContentHash { get; set; }
    public bool IsDefault { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;

    public User Freelancer { get; set; } = null!;
    public ICollection<Application> Applications { get; set; } = new List<Application>();
}

