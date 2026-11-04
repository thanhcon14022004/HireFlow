namespace HireFlow.Api.Entities;

public class Conversation
{
    public int ConversationId { get; set; }
    public int? ProjectId { get; set; }
    public int FreelancerId { get; set; }
    public int EmployerId { get; set; }
    public string? LastMessage { get; set; }
    public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Project? Project { get; set; }
    public User Freelancer { get; set; } = null!;
    public User Employer { get; set; } = null!;
    public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
}

public class ChatMessage
{
    public int MessageId { get; set; }
    public int ConversationId { get; set; }
    public int SenderId { get; set; }
    public string Content { get; set; } = string.Empty;
    public bool IsRead { get; set; } = false;
    public DateTime SentAt { get; set; } = DateTime.UtcNow;

    public Conversation Conversation { get; set; } = null!;
    public User Sender { get; set; } = null!;
}

