using System.Security.Claims;
using HireFlow.Api.Data;
using HireFlow.Api.DTOs;
using HireFlow.Api.Entities;
using HireFlow.Api.Middleware;
using HireFlow.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReportsController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly IAuditService _audit;

    public ReportsController(HireFlowDbContext db, IAuditService audit)
    {
        _db = db;
        _audit = audit;
    }

    [HttpPost]
    public async Task<IActionResult> CreateReport([FromBody] CreateReportRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var report = new Report
        {
            ReporterUserId = userId,
            TargetType = request.TargetType,
            TargetId = request.TargetId,
            Reason = request.Reason.Trim(),
            Description = request.Description?.Trim(),
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        _db.Reports.Add(report);
        await _db.SaveChangesAsync();

        await _audit.LogAsync(userId, "ReportSubmitted", request.TargetType, request.TargetId.ToString(), $"Báo cáo vi phạm: {request.Reason}");

        return Ok(new { reportId = report.ReportId, message = "Cảm ơn bạn đã gửi báo cáo. Ban quản trị sẽ sớm xem xét." });
    }
}

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly IAuditService _audit;
    private readonly ILogger<AdminController> _logger;

    public AdminController(HireFlowDbContext db, IAuditService audit, ILogger<AdminController> logger)
    {
        _db = db;
        _audit = audit;
        _logger = logger;
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers([FromQuery] string? search, [FromQuery] string? role, [FromQuery] bool? isActive, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var query = _db.Users.Include(u => u.CreditWallet).AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(u => u.FullName.ToLower().Contains(s) || u.Email.ToLower().Contains(s));
        }

        if (!string.IsNullOrWhiteSpace(role))
        {
            query = query.Where(u => u.Role == role);
        }

        if (isActive.HasValue)
        {
            query = query.Where(u => u.IsActive == isActive.Value);
        }

        var total = await query.CountAsync();
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 50 ? 10 : pageSize;

        var items = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new AdminUserDto
            {
                UserId = u.UserId,
                FullName = u.FullName,
                Email = u.Email,
                Role = u.Role,
                IsActive = u.IsActive,
                CreditBalance = u.CreditWallet != null ? u.CreditWallet.Balance : 0,
                CreatedAt = u.CreatedAt
            })
            .ToListAsync();

        return Ok(new PagedResult<AdminUserDto>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        });
    }

    [HttpPatch("users/{userId}/status")]
    public async Task<IActionResult> UpdateUserStatus(int userId, [FromBody] UpdateUserStatusRequest request)
    {
        var adminId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var user = await _db.Users.FindAsync(userId);
        if (user == null)
        {
            throw new AppException("Người dùng không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (user.Role == "Admin")
        {
            throw new AppException("Không thể thay đổi trạng thái của tài khoản Quản trị viên.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        user.IsActive = request.IsActive;
        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        var action = request.IsActive ? "UserReactivated" : "UserSuspended";
        await _audit.LogAsync(adminId, action, "User", user.UserId.ToString(), $"Thay đổi trạng thái hoạt động: {request.IsActive}");

        return Ok(new { message = $"Đã {(request.IsActive ? "mở khóa" : "khóa")} tài khoản người dùng thành công." });
    }

    [HttpGet("projects")]
    public async Task<IActionResult> GetProjects([FromQuery] string? search, [FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var query = _db.Projects
            .Include(p => p.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .Include(p => p.Skills)
            .Include(p => p.Applications)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p => p.Title.ToLower().Contains(s) || p.Employer.FullName.ToLower().Contains(s));
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(p => p.Status == status);
        }

        var total = await query.CountAsync();
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 50 ? 10 : pageSize;

        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new ProjectSummaryDto
            {
                ProjectId = p.ProjectId,
                EmployerId = p.EmployerId,
                EmployerName = p.Employer.EmployerProfile != null && !string.IsNullOrEmpty(p.Employer.EmployerProfile.PublicDisplayName)
                    ? p.Employer.EmployerProfile.PublicDisplayName
                    : p.Employer.FullName,
                CompanyName = p.Employer.EmployerProfile != null ? p.Employer.EmployerProfile.CompanyName : null,
                Title = p.Title,
                Description = p.Description,
                BudgetMin = p.BudgetMin,
                BudgetMax = p.BudgetMax,
                CurrencyCode = p.CurrencyCode,
                ExperienceLevel = p.ExperienceLevel,
                Deadline = p.Deadline,
                Status = p.Status,
                CreatedAt = p.CreatedAt,
                PublishedAt = p.PublishedAt,
                Skills = p.Skills.Select(s => s.SkillName).ToList(),
                ApplicantCount = p.Applications.Count
            })
            .ToListAsync();

        return Ok(new PagedResult<ProjectSummaryDto>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        });
    }

    [HttpPatch("projects/{projectId}/moderation")]
    public async Task<IActionResult> ModerateProject(int projectId, [FromBody] ModerateProjectRequest request)
    {
        var adminId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var validStatuses = new[] { "Open", "Hidden", "Removed" };
        var normalized = validStatuses.FirstOrDefault(s => string.Equals(s, request.Status.Trim(), StringComparison.OrdinalIgnoreCase));

        if (normalized == null)
        {
            throw new AppException("Trạng thái kiểm duyệt không hợp lệ. Chỉ chấp nhận: Open, Hidden, Removed.", "INVALID_STATUS");
        }

        var project = await _db.Projects.FindAsync(projectId);
        if (project == null)
        {
            throw new AppException("Dự án không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var oldStatus = project.Status;
        project.Status = normalized;
        project.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        await _audit.LogAsync(adminId, "ProjectModerated", "Project", project.ProjectId.ToString(), $"Thay đổi trạng thái từ {oldStatus} sang {normalized}. Lý do: {request.Reason}");

        return Ok(new { message = $"Đã cập nhật trạng thái kiểm duyệt dự án thành '{normalized}'.", status = normalized });
    }

    [HttpGet("reports")]
    public async Task<IActionResult> GetReports([FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var query = _db.Reports
            .Include(r => r.ReporterUser)
            .Include(r => r.ResolvedByUser)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(r => r.Status == status);
        }

        var total = await query.CountAsync();
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 50 ? 10 : pageSize;

        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new ReportDto
            {
                ReportId = r.ReportId,
                ReporterUserId = r.ReporterUserId,
                ReporterName = r.ReporterUser.FullName,
                TargetType = r.TargetType,
                TargetId = r.TargetId,
                Reason = r.Reason,
                Description = r.Description,
                Status = r.Status,
                CreatedAt = r.CreatedAt,
                ResolvedAt = r.ResolvedAt,
                ResolvedByUserName = r.ResolvedByUser != null ? r.ResolvedByUser.FullName : null
            })
            .ToListAsync();

        return Ok(new PagedResult<ReportDto>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        });
    }

    [HttpPatch("reports/{reportId}")]
    public async Task<IActionResult> UpdateReportStatus(int reportId, [FromBody] UpdateReportStatusRequest request)
    {
        var adminId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var validStatuses = new[] { "Reviewing", "Resolved", "Rejected" };
        var normalized = validStatuses.FirstOrDefault(s => string.Equals(s, request.Status.Trim(), StringComparison.OrdinalIgnoreCase));

        if (normalized == null)
        {
            throw new AppException("Trạng thái xử lý không hợp lệ. Chỉ chấp nhận: Reviewing, Resolved, Rejected.", "INVALID_STATUS");
        }

        var report = await _db.Reports.FindAsync(reportId);
        if (report == null)
        {
            throw new AppException("Báo cáo không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        report.Status = normalized;
        if (normalized is "Resolved" or "Rejected")
        {
            report.ResolvedAt = DateTime.UtcNow;
            report.ResolvedByUserId = adminId;
        }

        await _db.SaveChangesAsync();
        await _audit.LogAsync(adminId, "ReportStatusUpdated", "Report", report.ReportId.ToString(), $"Cập nhật trạng thái báo cáo thành {normalized}");

        return Ok(new { message = $"Đã cập nhật trạng thái báo cáo thành '{normalized}'." });
    }

    [HttpGet("credit-transactions")]
    public async Task<IActionResult> GetAllCreditTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var query = _db.CreditTransactions.Include(t => t.User).AsNoTracking();
        var total = await query.CountAsync();
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 50 ? 20 : pageSize;

        var items = await query
            .OrderByDescending(t => t.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(t => new
            {
                t.TransactionId,
                t.UserId,
                UserName = t.User.FullName,
                UserEmail = t.User.Email,
                t.Amount,
                t.TransactionType,
                t.ReferenceType,
                t.ReferenceId,
                t.Description,
                t.CreatedAt
            })
            .ToListAsync();

        return Ok(new
        {
            items,
            totalCount = total,
            page,
            pageSize
        });
    }

    [HttpGet("audit-logs")]
    public async Task<IActionResult> GetAuditLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var query = _db.AuditLogs.Include(a => a.ActorUser).AsNoTracking();
        var total = await query.CountAsync();
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 50 ? 20 : pageSize;

        var items = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new AuditLogDto
            {
                AuditLogId = a.AuditLogId,
                ActorUserId = a.ActorUserId,
                ActorUserName = a.ActorUser != null ? a.ActorUser.FullName : "Hệ thống",
                Action = a.Action,
                EntityType = a.EntityType,
                EntityId = a.EntityId,
                Details = a.Details,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();

        return Ok(new PagedResult<AuditLogDto>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        });
    }
}

