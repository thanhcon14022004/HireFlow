using System.Security.Claims;
using HireFlow.Api.Configuration;
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
public class ProjectsController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly ICreditService _creditService;
    private readonly IAuditService _audit;
    private readonly ILogger<ProjectsController> _logger;

    public ProjectsController(
        HireFlowDbContext db,
        ICreditService creditService,
        IAuditService audit,
        ILogger<ProjectsController> logger)
    {
        _db = db;
        _creditService = creditService;
        _audit = audit;
        _logger = logger;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetProjects([FromQuery] ProjectFilterRequest filter)
    {
        var query = _db.Projects
            .Include(p => p.Skills)
            .Include(p => p.Applications)
            .Include(p => p.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .AsNoTracking();

        // Admin can filter by any status; public can only see Open (or Closed if explicitly requested)
        var role = User.FindFirstValue(ClaimTypes.Role);
        if (role == "Admin")
        {
            if (!string.IsNullOrWhiteSpace(filter.Status))
            {
                query = query.Where(p => p.Status == filter.Status);
            }
        }
        else
        {
            // Public discovery only shows Open (or Closed for history) - Never Hidden/Removed
            if (!string.IsNullOrWhiteSpace(filter.Status) && (filter.Status == "Open" || filter.Status == "Closed"))
            {
                query = query.Where(p => p.Status == filter.Status);
            }
            else
            {
                query = query.Where(p => p.Status == "Open");
            }
        }

        // Keyword filter on Title and Description
        if (!string.IsNullOrWhiteSpace(filter.Keyword))
        {
            var kw = filter.Keyword.Trim().ToLower();
            query = query.Where(p => p.Title.ToLower().Contains(kw) || p.Description.ToLower().Contains(kw));
        }

        // Skill filter
        if (!string.IsNullOrWhiteSpace(filter.Skill))
        {
            var sk = filter.Skill.Trim().ToLower();
            query = query.Where(p => p.Skills.Any(s => s.SkillName.ToLower().Contains(sk)));
        }

        // Experience filter
        if (!string.IsNullOrWhiteSpace(filter.ExperienceLevel))
        {
            query = query.Where(p => p.ExperienceLevel == filter.ExperienceLevel);
        }

        // Budget filters
        if (filter.MinBudget.HasValue)
        {
            query = query.Where(p => p.BudgetMax >= filter.MinBudget.Value || p.BudgetMin >= filter.MinBudget.Value);
        }

        if (filter.MaxBudget.HasValue)
        {
            query = query.Where(p => p.BudgetMin <= filter.MaxBudget.Value);
        }

        var totalCount = await query.CountAsync();
        var page = filter.Page < 1 ? 1 : filter.Page;
        var pageSize = filter.PageSize is < 1 or > 50 ? 10 : filter.PageSize;

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
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        });
    }

    [HttpGet("{projectId}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetProjectDetail(int projectId)
    {
        var project = await _db.Projects
            .Include(p => p.Skills)
            .Include(p => p.Applications)
            .Include(p => p.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .FirstOrDefaultAsync(p => p.ProjectId == projectId);

        if (project == null)
        {
            throw new AppException("Dự án không tồn tại.", "PROJECT_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var role = User.FindFirstValue(ClaimTypes.Role);
        var currentUserIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        int.TryParse(currentUserIdStr, out var currentUserId);

        // Moderated project access check
        if ((project.Status == "Hidden" || project.Status == "Removed") && role != "Admin" && project.EmployerId != currentUserId)
        {
            throw new AppException("Dự án không tồn tại hoặc đã bị ẩn.", "PROJECT_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var isOwner = (currentUserId > 0 && project.EmployerId == currentUserId);
        var isUnlocked = false;
        var hasApplied = false;
        int? myApplicationId = null;
        string? myApplicationStatus = null;

        if (currentUserId > 0)
        {
            if (isOwner)
            {
                isUnlocked = true;
            }
            else
            {
                // Check if unlocked contact
                isUnlocked = await _db.ContactUnlocks.AnyAsync(c => c.FreelancerId == currentUserId && c.EmployerId == project.EmployerId);

                // Check if applied
                var app = await _db.Applications.FirstOrDefaultAsync(a => a.ProjectId == projectId && a.FreelancerId == currentUserId);
                if (app != null)
                {
                    hasApplied = true;
                    myApplicationId = app.ApplicationId;
                    myApplicationStatus = app.Status;
                }
            }
        }

        var empProfile = project.Employer.EmployerProfile;

        var detail = new ProjectDetailDto
        {
            ProjectId = project.ProjectId,
            EmployerId = project.EmployerId,
            EmployerName = empProfile != null && !string.IsNullOrEmpty(empProfile.PublicDisplayName)
                ? empProfile.PublicDisplayName
                : project.Employer.FullName,
            CompanyName = empProfile?.CompanyName,
            Title = project.Title,
            Description = project.Description,
            BudgetMin = project.BudgetMin,
            BudgetMax = project.BudgetMax,
            CurrencyCode = project.CurrencyCode,
            ExperienceLevel = project.ExperienceLevel,
            Deadline = project.Deadline,
            Status = project.Status,
            CreatedAt = project.CreatedAt,
            PublishedAt = project.PublishedAt,
            Skills = project.Skills.Select(s => s.SkillName).ToList(),
            ApplicantCount = project.Applications.Count,
            IsContactUnlocked = isUnlocked,
            ContactEmail = isUnlocked ? (empProfile?.ContactEmail ?? project.Employer.Email) : null,
            ContactPhone = isUnlocked ? empProfile?.ContactPhone : null,
            HasApplied = hasApplied,
            MyApplicationId = myApplicationId,
            MyApplicationStatus = myApplicationStatus
        };

        return Ok(detail);
    }

    [HttpPost]
    [Authorize(Roles = "Employer")]
    public async Task<IActionResult> CreateProject([FromBody] CreateProjectRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // PUB-002 & PUB-003: Check credits (5 credits) and execute atomically
        var cost = CreditConstants.PublishProjectCost;
        var hasCredits = await _creditService.HasSufficientBalanceAsync(userId, cost);
        if (!hasCredits)
        {
            throw new AppException($"Bạn cần {cost} credit để đăng dự án. Vui lòng nạp thêm credit.", "INSUFFICIENT_CREDITS");
        }

        // Use transaction for atomic publication + credit deduction
        using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var project = new Project
            {
                EmployerId = userId,
                Title = request.Title.Trim(),
                Description = request.Description.Trim(),
                BudgetMin = request.BudgetMin,
                BudgetMax = request.BudgetMax,
                CurrencyCode = string.IsNullOrWhiteSpace(request.CurrencyCode) ? "VND" : request.CurrencyCode,
                ExperienceLevel = request.ExperienceLevel?.Trim(),
                Deadline = request.Deadline,
                Status = "Open",
                CreatedAt = DateTime.UtcNow,
                PublishedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            if (request.Skills != null)
            {
                foreach (var sk in request.Skills.Where(s => !string.IsNullOrWhiteSpace(s)).Distinct())
                {
                    project.Skills.Add(new ProjectSkill { SkillName = sk.Trim() });
                }
            }

            _db.Projects.Add(project);
            await _db.SaveChangesAsync();

            // Deduct credits
            var deduction = await _creditService.DeductCreditsAsync(
                userId,
                cost,
                "ProjectPublish",
                "Project",
                project.ProjectId.ToString(),
                $"Phí đăng tin tuyển dụng: {project.Title}");

            if (!deduction.Success)
            {
                await tx.RollbackAsync();
                throw new AppException(deduction.ErrorMessage ?? "Lỗi trừ credit khi đăng dự án.", "INSUFFICIENT_CREDITS");
            }

            await tx.CommitAsync();

            await _audit.LogAsync(userId, "ProjectPublished", "Project", project.ProjectId.ToString(), $"Đăng dự án thành công (-{cost} credits)");

            return CreatedAtAction(nameof(GetProjectDetail), new { projectId = project.ProjectId }, new { projectId = project.ProjectId, message = "Đăng dự án thành công." });
        }
        catch (Exception)
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    [HttpPut("{projectId}")]
    [Authorize(Roles = "Employer")]
    public async Task<IActionResult> UpdateProject(int projectId, [FromBody] UpdateProjectRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var project = await _db.Projects
            .Include(p => p.Skills)
            .FirstOrDefaultAsync(p => p.ProjectId == projectId);

        if (project == null)
        {
            throw new AppException("Dự án không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        // Ownership check
        if (project.EmployerId != userId)
        {
            throw new AppException("Bạn không có quyền chỉnh sửa dự án này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        project.Title = request.Title.Trim();
        project.Description = request.Description.Trim();
        project.BudgetMin = request.BudgetMin;
        project.BudgetMax = request.BudgetMax;
        project.CurrencyCode = string.IsNullOrWhiteSpace(request.CurrencyCode) ? "VND" : request.CurrencyCode;
        project.ExperienceLevel = request.ExperienceLevel?.Trim();
        project.Deadline = request.Deadline;
        project.UpdatedAt = DateTime.UtcNow;

        _db.ProjectSkills.RemoveRange(project.Skills);
        project.Skills.Clear();
        if (request.Skills != null)
        {
            foreach (var sk in request.Skills.Where(s => !string.IsNullOrWhiteSpace(s)).Distinct())
            {
                project.Skills.Add(new ProjectSkill
                {
                    ProjectId = project.ProjectId,
                    SkillName = sk.Trim()
                });
            }
        }

        await _db.SaveChangesAsync();
        await _audit.LogAsync(userId, "ProjectUpdated", "Project", project.ProjectId.ToString(), "Chỉnh sửa thông tin dự án");

        return Ok(new { message = "Cập nhật dự án thành công." });
    }

    [HttpPost("{projectId}/close")]
    [Authorize(Roles = "Employer")]
    public async Task<IActionResult> CloseProject(int projectId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var project = await _db.Projects.FirstOrDefaultAsync(p => p.ProjectId == projectId);
        if (project == null)
        {
            throw new AppException("Dự án không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (project.EmployerId != userId)
        {
            throw new AppException("Bạn không có quyền đóng dự án này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        project.Status = "Closed";
        project.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await _audit.LogAsync(userId, "ProjectClosed", "Project", project.ProjectId.ToString(), "Đóng dự án tuyển dụng");

        return Ok(new { message = "Đã đóng dự án. Dự án sẽ không nhận thêm ứng tuyển mới." });
    }
}

