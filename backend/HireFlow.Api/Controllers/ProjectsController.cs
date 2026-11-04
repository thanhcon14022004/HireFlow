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

var currentUserIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        int.TryParse(currentUserIdStr, out var currentUserId);

        var savedProjectIds = currentUserId > 0
            ? await _db.SavedProjects.Where(sp => sp.FreelancerId == currentUserId).Select(sp => sp.ProjectId).ToListAsync()
            : new List<int>();

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
                ApplicantCount = p.Applications.Count,
                HasApplied = currentUserId > 0 && p.Applications.Any(a => a.FreelancerId == currentUserId),
                MyApplicationStatus = currentUserId > 0
                    ? p.Applications.Where(a => a.FreelancerId == currentUserId).Select(a => a.Status).FirstOrDefault()
                    : null,
MyApplicationId = currentUserId > 0
                    ? p.Applications.Where(a => a.FreelancerId == currentUserId).Select(a => (int?)a.ApplicationId).FirstOrDefault()
                    : null,
                IsSaved = currentUserId > 0 && savedProjectIds.Contains(p.ProjectId)
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

        var savedProjectIds = currentUserId > 0
            ? await _db.SavedProjects.Where(sp => sp.FreelancerId == currentUserId).Select(sp => sp.ProjectId).ToListAsync()
            : new List<int>();

        // Moderated project access check
        if ((project.Status == "Hidden" || project.Status == "Removed") && role != "Admin" && project.EmployerId != currentUserId)
        {
            throw new AppException("Dự án không tồn tại hoặc đã bị ẩn.", "PROJECT_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var isOwner = (currentUserId > 0 && project.EmployerId == currentUserId);
var isUnlocked = false;
        var hasApplied = false;
        var isSaved = false;
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
                // Check if candidate applied to this project
                var app = await _db.Applications.FirstOrDefaultAsync(a => a.ProjectId == projectId && a.FreelancerId == currentUserId);
                if (app != null)
                {
                    hasApplied = true;
                    myApplicationId = app.ApplicationId;
                    myApplicationStatus = app.Status;
                }

// Rule: Candidate must apply to project to unlock employer contact details
                isUnlocked = hasApplied;
                isSaved = await _db.SavedProjects.AnyAsync(sp => sp.FreelancerId == currentUserId && sp.ProjectId == projectId);
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
MyApplicationStatus = myApplicationStatus,
            IsSaved = isSaved
        };

        return Ok(detail);
    }

    [HttpPost]
    [Authorize(Roles = "Employer")]
    public async Task<IActionResult> CreateProject([FromBody] CreateProjectRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Budget validation
        if (request.BudgetMin.HasValue && request.BudgetMin.Value < 0)
        {
            throw new AppException("Ngân sách tối thiểu không được là số âm.", "INVALID_BUDGET");
        }
        if (request.BudgetMax.HasValue && request.BudgetMax.Value < 0)
        {
            throw new AppException("Ngân sách tối đa không được là số âm.", "INVALID_BUDGET");
        }
        if (request.BudgetMin.HasValue && request.BudgetMax.HasValue && request.BudgetMin.Value > request.BudgetMax.Value)
        {
            throw new AppException("Ngân sách tối thiểu không được lớn hơn ngân sách tối đa.", "INVALID_BUDGET");
        }

        // Deadline validation
        if (request.Deadline.HasValue && request.Deadline.Value <= DateTime.UtcNow)
        {
            throw new AppException("Hạn chót nộp hồ sơ phải ở tương lai.", "INVALID_DEADLINE");
        }

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

        // Check if project can be updated
        if (project.Status == "Closed" || project.Status == "Removed")
        {
            throw new AppException("Không thể chỉnh sửa dự án đã đóng hoặc bị gỡ bỏ.", "PROJECT_NOT_EDITABLE");
        }

        // Budget validation
        if (request.BudgetMin.HasValue && request.BudgetMin.Value < 0)
        {
            throw new AppException("Ngân sách tối thiểu không được là số âm.", "INVALID_BUDGET");
        }
        if (request.BudgetMax.HasValue && request.BudgetMax.Value < 0)
        {
            throw new AppException("Ngân sách tối đa không được là số âm.", "INVALID_BUDGET");
        }
        if (request.BudgetMin.HasValue && request.BudgetMax.HasValue && request.BudgetMin.Value > request.BudgetMax.Value)
        {
            throw new AppException("Ngân sách tối thiểu không được lớn hơn ngân sách tối đa.", "INVALID_BUDGET");
        }

        // Deadline validation
        if (request.Deadline.HasValue && request.Deadline.Value <= DateTime.UtcNow)
        {
            throw new AppException("Hạn chót nộp hồ sơ phải ở tương lai.", "INVALID_DEADLINE");
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

        if (project.Status == "Closed")
        {
            return Ok(new { message = "Dự án đã đóng trước đó." });
        }

        if (project.Status == "Removed")
        {
            throw new AppException("Dự án đã bị gỡ bỏ bởi quản trị viên.", "PROJECT_REMOVED");
        }

        project.Status = "Closed";
        project.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await _audit.LogAsync(userId, "ProjectClosed", "Project", project.ProjectId.ToString(), "Đóng dự án tuyển dụng");

        return Ok(new { message = "Đã đóng dự án. Dự án sẽ không nhận thêm ứng tuyển mới." });
    }

    [HttpPost("{projectId}/save")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> SaveProject(int projectId)
    {
        var currentUserIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(currentUserIdStr, out var currentUserId))
        {
            throw new AppException("Không tìm thấy thông tin tài khoản.", "UNAUTHORIZED", System.Net.HttpStatusCode.Unauthorized);
        }

        var project = await _db.Projects.FirstOrDefaultAsync(p => p.ProjectId == projectId);
        if (project == null || project.Status == "Removed")
        {
            throw new AppException("Dự án không tồn tại.", "PROJECT_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var existing = await _db.SavedProjects.FirstOrDefaultAsync(sp => sp.FreelancerId == currentUserId && sp.ProjectId == projectId);
        if (existing == null)
        {
            _db.SavedProjects.Add(new SavedProject
            {
                FreelancerId = currentUserId,
                ProjectId = projectId,
                SavedAt = DateTime.UtcNow
            });
            await _db.SaveChangesAsync();
        }

        return Ok(new { message = "Đã lưu dự án vào danh sách quan tâm thành công.", isSaved = true });
    }

    [HttpDelete("{projectId}/save")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> UnsaveProject(int projectId)
    {
        var currentUserIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(currentUserIdStr, out var currentUserId))
        {
            throw new AppException("Không tìm thấy thông tin tài khoản.", "UNAUTHORIZED", System.Net.HttpStatusCode.Unauthorized);
        }

        var existing = await _db.SavedProjects.FirstOrDefaultAsync(sp => sp.FreelancerId == currentUserId && sp.ProjectId == projectId);
        if (existing != null)
        {
            _db.SavedProjects.Remove(existing);
            await _db.SaveChangesAsync();
        }

        return Ok(new { message = "Đã bỏ lưu dự án.", isSaved = false });
    }

    [HttpGet("saved")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> GetSavedProjects()
    {
        var currentUserIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(currentUserIdStr, out var currentUserId))
        {
            throw new AppException("Không tìm thấy thông tin tài khoản.", "UNAUTHORIZED", System.Net.HttpStatusCode.Unauthorized);
        }

        var items = await _db.SavedProjects
            .Where(sp => sp.FreelancerId == currentUserId)
            .OrderByDescending(sp => sp.SavedAt)
            .Include(sp => sp.Project)
                .ThenInclude(p => p.Skills)
            .Include(sp => sp.Project)
                .ThenInclude(p => p.Applications)
            .Include(sp => sp.Project)
                .ThenInclude(p => p.Employer)
                    .ThenInclude(e => e.EmployerProfile)
            .Select(sp => new ProjectSummaryDto
            {
                ProjectId = sp.Project.ProjectId,
                EmployerId = sp.Project.EmployerId,
                EmployerName = sp.Project.Employer.EmployerProfile != null && !string.IsNullOrEmpty(sp.Project.Employer.EmployerProfile.PublicDisplayName)
                    ? sp.Project.Employer.EmployerProfile.PublicDisplayName
                    : sp.Project.Employer.FullName,
                CompanyName = sp.Project.Employer.EmployerProfile != null ? sp.Project.Employer.EmployerProfile.CompanyName : null,
                Title = sp.Project.Title,
                Description = sp.Project.Description,
                BudgetMin = sp.Project.BudgetMin,
                BudgetMax = sp.Project.BudgetMax,
                CurrencyCode = sp.Project.CurrencyCode,
                ExperienceLevel = sp.Project.ExperienceLevel,
                Deadline = sp.Project.Deadline,
                Status = sp.Project.Status,
                CreatedAt = sp.Project.CreatedAt,
                PublishedAt = sp.Project.PublishedAt,
                Skills = sp.Project.Skills.Select(s => s.SkillName).ToList(),
                ApplicantCount = sp.Project.Applications.Count,
                HasApplied = sp.Project.Applications.Any(a => a.FreelancerId == currentUserId),
                MyApplicationStatus = sp.Project.Applications.Where(a => a.FreelancerId == currentUserId).Select(a => a.Status).FirstOrDefault(),
                MyApplicationId = sp.Project.Applications.Where(a => a.FreelancerId == currentUserId).Select(a => (int?)a.ApplicationId).FirstOrDefault(),
                IsSaved = true
            })
            .ToListAsync();

        return Ok(new { items, totalCount = items.Count });
    }
}
