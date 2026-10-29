namespace HireFlow.Api.Entities;

public class Application
{
    public int ApplicationId { get; set; }
    public int ProjectId { get; set; }
    public int FreelancerId { get; set; }
    public int DocumentId { get; set; }
    public string? CoverLetter { get; set; }
    public string Status { get; set; } = "Pending"; // Pending, Reviewing, Shortlisted, Accepted, Rejected
    public DateTime AppliedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Project Project { get; set; } = null!;
    public User Freelancer { get; set; } = null!;
    public FreelancerDocument Document { get; set; } = null!;
    public ICollection<ApplicationStatusHistory> StatusHistories { get; set; } = new List<ApplicationStatusHistory>();
}

public class ApplicationStatusHistory
{
    public int HistoryId { get; set; }
    public int ApplicationId { get; set; }
    public string? OldStatus { get; set; }
    public string NewStatus { get; set; } = string.Empty;
    public int ChangedByUserId { get; set; }
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;

    public Application Application { get; set; } = null!;
    public User ChangedByUser { get; set; } = null!;
}
