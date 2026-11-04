using System.Security.Claims;
using HireFlow.Api.Data;
using HireFlow.Api.DTOs;
using HireFlow.Api.Entities;
using HireFlow.Api.Middleware;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly ILogger<ChatController> _logger;

    public ChatController(HireFlowDbContext db, ILogger<ChatController> logger)
    {
        _db = db;
        _logger = logger;
    }

    [HttpGet("conversations")]
    public async Task<IActionResult> GetConversations()
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var conversations = await _db.Conversations
            .Include(c => c.Project)
            .Include(c => c.Freelancer)
            .Include(c => c.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .Where(c => c.FreelancerId == currentUserId || c.EmployerId == currentUserId)
            .OrderByDescending(c => c.LastMessageAt)
            .ToListAsync();

        var convIds = conversations.Select(c => c.ConversationId).ToList();
        var unreadCounts = await _db.ChatMessages
            .Where(m => convIds.Contains(m.ConversationId) && m.SenderId != currentUserId && !m.IsRead)
            .GroupBy(m => m.ConversationId)
            .Select(g => new { ConversationId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ConversationId, x => x.Count);

        var dtos = conversations.Select(c =>
        {
            var isFreelancer = c.FreelancerId == currentUserId;
            var otherUser = isFreelancer ? c.Employer : c.Freelancer;
            var empProfile = c.Employer.EmployerProfile;
            var empName = empProfile != null && !string.IsNullOrEmpty(empProfile.PublicDisplayName)
                ? empProfile.PublicDisplayName
                : c.Employer.FullName;

            return new ConversationDto
            {
                ConversationId = c.ConversationId,
                ProjectId = c.ProjectId,
                ProjectTitle = c.Project?.Title,
                FreelancerId = c.FreelancerId,
                FreelancerName = c.Freelancer.FullName,
                EmployerId = c.EmployerId,
                EmployerName = empName,
                EmployerCompanyName = empProfile?.CompanyName,
                OtherPartyId = otherUser.UserId,
                OtherPartyName = isFreelancer ? empName : c.Freelancer.FullName,
                OtherPartyRole = otherUser.Role,
                LastMessage = c.LastMessage,
                LastMessageAt = c.LastMessageAt,
                UnreadCount = unreadCounts.GetValueOrDefault(c.ConversationId, 0)
            };
        }).ToList();

        return Ok(dtos);
    }

    [HttpGet("conversations/{id}")]
    public async Task<IActionResult> GetConversation(int id)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var c = await _db.Conversations
            .Include(c => c.Project)
            .Include(c => c.Freelancer)
            .Include(c => c.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .FirstOrDefaultAsync(c => c.ConversationId == id);

        if (c == null)
        {
            throw new AppException("Cuộc trò chuyện không tồn tại.", "CONVERSATION_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (c.FreelancerId != currentUserId && c.EmployerId != currentUserId)
        {
            throw new AppException("Bạn không có quyền truy cập cuộc trò chuyện này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        var unreadCount = await _db.ChatMessages
            .CountAsync(m => m.ConversationId == id && m.SenderId != currentUserId && !m.IsRead);

        var isFreelancer = c.FreelancerId == currentUserId;
        var otherUser = isFreelancer ? c.Employer : c.Freelancer;
        var empProfile = c.Employer.EmployerProfile;
        var empName = empProfile != null && !string.IsNullOrEmpty(empProfile.PublicDisplayName)
            ? empProfile.PublicDisplayName
            : c.Employer.FullName;

        var dto = new ConversationDto
        {
            ConversationId = c.ConversationId,
            ProjectId = c.ProjectId,
            ProjectTitle = c.Project?.Title,
            FreelancerId = c.FreelancerId,
            FreelancerName = c.Freelancer.FullName,
            EmployerId = c.EmployerId,
            EmployerName = empName,
            EmployerCompanyName = empProfile?.CompanyName,
            OtherPartyId = otherUser.UserId,
            OtherPartyName = isFreelancer ? empName : c.Freelancer.FullName,
            OtherPartyRole = otherUser.Role,
            LastMessage = c.LastMessage,
            LastMessageAt = c.LastMessageAt,
            UnreadCount = unreadCount
        };

        return Ok(dto);
    }

    [HttpGet("conversations/{id}/messages")]
    public async Task<IActionResult> GetMessages(int id)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var conv = await _db.Conversations.FirstOrDefaultAsync(c => c.ConversationId == id);
        if (conv == null)
        {
            throw new AppException("Cuộc trò chuyện không tồn tại.", "CONVERSATION_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (conv.FreelancerId != currentUserId && conv.EmployerId != currentUserId)
        {
            throw new AppException("Bạn không có quyền xem tin nhắn của cuộc trò chuyện này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        // Mark unread messages sent to me as read
        var unreadMessages = await _db.ChatMessages
            .Where(m => m.ConversationId == id && m.SenderId != currentUserId && !m.IsRead)
            .ToListAsync();

        if (unreadMessages.Any())
        {
            foreach (var msg in unreadMessages)
            {
                msg.IsRead = true;
            }
            await _db.SaveChangesAsync();
        }

        var messages = await _db.ChatMessages
            .Include(m => m.Sender)
            .Where(m => m.ConversationId == id)
            .OrderBy(m => m.SentAt)
            .Select(m => new ChatMessageDto
            {
                MessageId = m.MessageId,
                ConversationId = m.ConversationId,
                SenderId = m.SenderId,
                SenderName = m.Sender.FullName,
                Content = m.Content,
                IsRead = m.IsRead,
                SentAt = m.SentAt,
                IsMe = m.SenderId == currentUserId
            })
            .ToListAsync();

        return Ok(messages);
    }

    [HttpPost("conversations/{id}/messages")]
    public async Task<IActionResult> SendMessage(int id, [FromBody] SendMessageRequest request)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new AppException("Nội dung tin nhắn không được để trống.", "EMPTY_MESSAGE");
        }

        var conv = await _db.Conversations.FirstOrDefaultAsync(c => c.ConversationId == id);
        if (conv == null)
        {
            throw new AppException("Cuộc trò chuyện không tồn tại.", "CONVERSATION_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (conv.FreelancerId != currentUserId && conv.EmployerId != currentUserId)
        {
            throw new AppException("Bạn không có quyền gửi tin nhắn trong cuộc trò chuyện này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        var message = new ChatMessage
        {
            ConversationId = id,
            SenderId = currentUserId,
            Content = request.Content.Trim(),
            IsRead = false,
            SentAt = DateTime.UtcNow
        };

        _db.ChatMessages.Add(message);

        conv.LastMessage = message.Content;
        conv.LastMessageAt = message.SentAt;

        await _db.SaveChangesAsync();

        var sender = await _db.Users.FindAsync(currentUserId);

        var dto = new ChatMessageDto
        {
            MessageId = message.MessageId,
            ConversationId = message.ConversationId,
            SenderId = message.SenderId,
            SenderName = sender?.FullName ?? "",
            Content = message.Content,
            IsRead = message.IsRead,
            SentAt = message.SentAt,
            IsMe = true
        };

        return Ok(dto);
    }

    [HttpPost("start")]
    public async Task<IActionResult> StartConversation([FromBody] StartConversationRequest request)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var currentRole = User.FindFirstValue(ClaimTypes.Role);

        int freelancerId;
        int employerId;
        int? projectId = request.ProjectId > 0 ? request.ProjectId : null;

        if (currentRole == "Freelancer")
        {
            freelancerId = currentUserId;

            if (request.ProjectId.HasValue && request.ProjectId.Value > 0)
            {
                var project = await _db.Projects.FirstOrDefaultAsync(p => p.ProjectId == request.ProjectId.Value);
                if (project == null)
                {
                    throw new AppException("Dự án tuyển dụng không tồn tại.", "PROJECT_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
                }

                // Rule: Candidate must apply to project before initiating contact with employer
                var hasApplied = await _db.Applications.AnyAsync(a => a.ProjectId == project.ProjectId && a.FreelancerId == currentUserId);
                if (!hasApplied)
                {
                    throw new AppException("Bạn cần nộp hồ sơ ứng tuyển trước khi có thể nhắn tin cho nhà tuyển dụng.", "APPLICATION_REQUIRED_TO_CHAT", System.Net.HttpStatusCode.Forbidden);
                }

                employerId = project.EmployerId;
            }
            else if (request.EmployerId.HasValue && request.EmployerId.Value > 0)
            {
                employerId = request.EmployerId.Value;
            }
            else
            {
                throw new AppException("Thiếu thông tin nhà tuyển dụng hoặc dự án.", "INVALID_REQUEST");
            }
        }
        else // Employer
        {
            employerId = currentUserId;

            if (!request.FreelancerId.HasValue || request.FreelancerId.Value <= 0)
            {
                throw new AppException("Thiếu thông tin ứng viên cần liên hệ.", "INVALID_REQUEST");
            }

            freelancerId = request.FreelancerId.Value;
        }

        // Find existing conversation
        var conv = await _db.Conversations
            .Include(c => c.Project)
            .Include(c => c.Freelancer)
            .Include(c => c.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .FirstOrDefaultAsync(c => c.FreelancerId == freelancerId && c.EmployerId == employerId && c.ProjectId == projectId);

        if (conv == null)
        {
            conv = new Conversation
            {
                ProjectId = projectId,
                FreelancerId = freelancerId,
                EmployerId = employerId,
                LastMessage = !string.IsNullOrWhiteSpace(request.InitialMessage) ? request.InitialMessage.Trim() : null,
                LastMessageAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            };

            _db.Conversations.Add(conv);
            await _db.SaveChangesAsync();

            if (!string.IsNullOrWhiteSpace(request.InitialMessage))
            {
                var msg = new ChatMessage
                {
                    ConversationId = conv.ConversationId,
                    SenderId = currentUserId,
                    Content = request.InitialMessage.Trim(),
                    IsRead = false,
                    SentAt = DateTime.UtcNow
                };
                _db.ChatMessages.Add(msg);
                await _db.SaveChangesAsync();
            }

            // Reload navigation properties
            await _db.Entry(conv).Reference(c => c.Project).LoadAsync();
            await _db.Entry(conv).Reference(c => c.Freelancer).LoadAsync();
            await _db.Entry(conv).Reference(c => c.Employer).Query().Include(e => e.EmployerProfile).LoadAsync();
        }
        else if (!string.IsNullOrWhiteSpace(request.InitialMessage))
        {
            var msg = new ChatMessage
            {
                ConversationId = conv.ConversationId,
                SenderId = currentUserId,
                Content = request.InitialMessage.Trim(),
                IsRead = false,
                SentAt = DateTime.UtcNow
            };
            _db.ChatMessages.Add(msg);
            conv.LastMessage = msg.Content;
            conv.LastMessageAt = msg.SentAt;
            await _db.SaveChangesAsync();
        }

        var isFreelancer = conv.FreelancerId == currentUserId;
        var otherUser = isFreelancer ? conv.Employer : conv.Freelancer;
        var empProfile = conv.Employer.EmployerProfile;
        var empName = empProfile != null && !string.IsNullOrEmpty(empProfile.PublicDisplayName)
            ? empProfile.PublicDisplayName
            : conv.Employer.FullName;

        var dto = new ConversationDto
        {
            ConversationId = conv.ConversationId,
            ProjectId = conv.ProjectId,
            ProjectTitle = conv.Project?.Title,
            FreelancerId = conv.FreelancerId,
            FreelancerName = conv.Freelancer.FullName,
            EmployerId = conv.EmployerId,
            EmployerName = empName,
            EmployerCompanyName = empProfile?.CompanyName,
            OtherPartyId = otherUser.UserId,
            OtherPartyName = isFreelancer ? empName : conv.Freelancer.FullName,
            OtherPartyRole = otherUser.Role,
            LastMessage = conv.LastMessage,
            LastMessageAt = conv.LastMessageAt,
            UnreadCount = 0
        };

        return Ok(dto);
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetTotalUnreadCount()
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var count = await _db.ChatMessages
            .Where(m => (m.Conversation.FreelancerId == currentUserId || m.Conversation.EmployerId == currentUserId)
                     && m.SenderId != currentUserId && !m.IsRead)
            .CountAsync();

        return Ok(new { unreadCount = count });
    }
}

