namespace HireFlow.Api.Entities;

public class FreelancerProfile
{
    public int ProfileId { get; set; }
    public int UserId { get; set; }
    public string? AvatarStorageKey { get; set; }
    public string? Headline { get; set; }
    public string? Bio { get; set; }
    public int? ExperienceYears { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public ICollection<FreelancerSkill> Skills { get; set; } = new List<FreelancerSkill>();
}

public class FreelancerSkill
{
    public int FreelancerSkillId { get; set; }
    public int FreelancerProfileId { get; set; }
    public string SkillName { get; set; } = string.Empty;

    public FreelancerProfile Profile { get; set; } = null!;
}

public class EmployerProfile
{
    public int EmployerProfileId { get; set; }
    public int UserId { get; set; }
    public string? CompanyName { get; set; }
    public string? Description { get; set; }
    public string? PublicDisplayName { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}
