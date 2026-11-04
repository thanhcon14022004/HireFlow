using System.Security.Claims;
using HireFlow.Api.Data;
using HireFlow.Api.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Controllers;

[ApiController]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly ILogger<NotificationsController> _logger;

    public NotificationsController(HireFlowDbContext db, ILogger<NotificationsController> logger)
    {
        _db = db;
        _logger = logger;
    }

    [HttpGet("api/notifications")]
    public async Task<IActionResult> GetMyNotifications([FromQuery] int limit = 30)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var list = await _db.UserNotifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(limit)
            .Select(n => new UserNotificationDto
            {
                NotificationId = n.NotificationId,
                Title = n.Title,
                Message = n.Message,
                Type = n.Type,
                ReferenceId = n.ReferenceId,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .ToListAsync();

        return Ok(list);
    }

    [HttpGet("api/notifications/unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var count = await _db.UserNotifications
            .CountAsync(n => n.UserId == userId && !n.IsRead);

        return Ok(new { count });
    }

    [HttpPatch("api/notifications/{notificationId}/read")]
    public async Task<IActionResult> MarkAsRead(int notificationId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var notif = await _db.UserNotifications
            .FirstOrDefaultAsync(n => n.NotificationId == notificationId && n.UserId == userId);

        if (notif != null)
        {
            notif.IsRead = true;
            await _db.SaveChangesAsync();
        }

        return Ok(new { success = true });
    }

    [HttpPost("api/notifications/mark-all-read")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var unread = await _db.UserNotifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync();

        foreach (var n in unread)
        {
            n.IsRead = true;
        }

        await _db.SaveChangesAsync();
        return Ok(new { success = true, markedCount = unread.Count });
    }
}

