namespace HireFlow.Api.DTOs;

public class ConversationDto
{
    public int ConversationId { get; set; }
    public int? ProjectId { get; set; }
    public string? ProjectTitle { get; set; }
    public int FreelancerId { get; set; }
    public string FreelancerName { get; set; } = string.Empty;
    public int EmployerId { get; set; }
    public string EmployerName { get; set; } = string.Empty;
    public string? EmployerCompanyName { get; set; }
    public int OtherPartyId { get; set; }
    public string OtherPartyName { get; set; } = string.Empty;
    public string OtherPartyRole { get; set; } = string.Empty;
    public string? LastMessage { get; set; }
    public DateTime LastMessageAt { get; set; }
    public int UnreadCount { get; set; }
}

public class ChatMessageDto
{
    public int MessageId { get; set; }
    public int ConversationId { get; set; }
    public int SenderId { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime SentAt { get; set; }
    public bool IsMe { get; set; }
}

public class StartConversationRequest
{
    public int? ProjectId { get; set; }
    public int? EmployerId { get; set; }
    public int? FreelancerId { get; set; }
    public string? InitialMessage { get; set; }
}

public class SendMessageRequest
{
    public string Content { get; set; } = string.Empty;
}

