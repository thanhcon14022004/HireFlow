namespace HireFlow.Api.Entities;

public class User
{
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty; // Freelancer, Employer, Admin
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public FreelancerProfile? FreelancerProfile { get; set; }
    public EmployerProfile? EmployerProfile { get; set; }
    public CreditWallet? CreditWallet { get; set; }

    public ICollection<Project> Projects { get; set; } = new List<Project>();
    public ICollection<Application> Applications { get; set; } = new List<Application>();
    public ICollection<FreelancerDocument> Documents { get; set; } = new List<FreelancerDocument>();
    public ICollection<CreditTransaction> CreditTransactions { get; set; } = new List<CreditTransaction>();
    public ICollection<ContactUnlock> UnlockedContactsAsFreelancer { get; set; } = new List<ContactUnlock>();
    public ICollection<ContactUnlock> UnlockedContactsAsEmployer { get; set; } = new List<ContactUnlock>();
    public ICollection<CreditPurchase> CreditPurchases { get; set; } = new List<CreditPurchase>();
    public ICollection<Report> SubmittedReports { get; set; } = new List<Report>();
    public ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
}

