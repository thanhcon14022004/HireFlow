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
[Authorize]
public class ApplicationsController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly ICreditService _creditService;
    private readonly IFileStorageService _storage;
    private readonly IAuditService _audit;
    private readonly ILogger<ApplicationsController> _logger;

    public ApplicationsController(
        HireFlowDbContext db,
        ICreditService creditService,
        IFileStorageService storage,
        IAuditService audit,
        ILogger<ApplicationsController> logger)
    {
        _db = db;
        _creditService = creditService;
        _storage = storage;
        _audit = audit;
        _logger = logger;
    }

    [HttpPost("api/projects/{projectId}/applications")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> Apply(int projectId, [FromBody] ApplyProjectRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // 1. Check project
        var project = await _db.Projects.FirstOrDefaultAsync(p => p.ProjectId == projectId);
        if (project == null || project.Status != "Open")
        {
            throw new AppException("Dự án không tồn tại hoặc đã đóng nhận ứng tuyển.", "PROJECT_NOT_OPEN");
        }

        // 1b. Check if project deadline has passed
        if (project.Deadline.HasValue && project.Deadline.Value < DateTime.UtcNow)
        {
            throw new AppException("Dự án đã quá hạn nộp hồ sơ.", "PROJECT_EXPIRED");
        }

        // 1c. Defensive check: Cannot apply to own project
        if (project.EmployerId == userId)
        {
            throw new AppException("Bạn không thể ứng tuyển vào dự án do chính mình đăng.", "CANNOT_APPLY_OWN_PROJECT");
        }

        // 2. Check CV ownership and validity
        var document = await _db.FreelancerDocuments
            .FirstOrDefaultAsync(d => d.DocumentId == request.DocumentId && d.FreelancerId == userId && !d.IsDeleted);
        if (document == null)
        {
            throw new AppException("CV đã chọn không hợp lệ hoặc không thuộc tài khoản của bạn.", "INVALID_DOCUMENT");
        }

        // 3. Check duplicate application
        var alreadyApplied = await _db.Applications.AnyAsync(a => a.ProjectId == projectId && a.FreelancerId == userId);
        if (alreadyApplied)
        {
            throw new AppException("Bạn đã nộp hồ sơ ứng tuyển vào dự án này rồi.", "ALREADY_APPLIED", System.Net.HttpStatusCode.Conflict);
        }

        // 4. Verify credits
        var cost = CreditConstants.ApplicationCost;
        var hasCredits = await _creditService.HasSufficientBalanceAsync(userId, cost);
        if (!hasCredits)
        {
            throw new AppException($"Bạn cần {cost} credit để ứng tuyển dự án này. Vui lòng nạp thêm credit.", "INSUFFICIENT_CREDITS");
        }

        // 5. Execute atomically
        using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var application = new Application
            {
                ProjectId = projectId,
                FreelancerId = userId,
                DocumentId = request.DocumentId,
                CoverLetter = request.CoverLetter?.Trim(),
                Status = "Pending",
                AppliedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Applications.Add(application);
            await _db.SaveChangesAsync();

            // Initial status history record
            _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
            {
                ApplicationId = application.ApplicationId,
                OldStatus = null,
                NewStatus = "Pending",
                ChangedByUserId = userId,
                ChangedAt = DateTime.UtcNow
            });

            // Deduct credits
            var deduction = await _creditService.DeductCreditsAsync(
                userId,
                cost,
                "ApplicationFee",
                "Application",
                application.ApplicationId.ToString(),
                $"Ứng tuyển dự án: {project.Title}");

            if (!deduction.Success)
            {
                await tx.RollbackAsync();
                throw new AppException(deduction.ErrorMessage ?? "Lỗi trừ credit khi ứng tuyển.", "INSUFFICIENT_CREDITS");
            }

            await _db.SaveChangesAsync();
            await tx.CommitAsync();

            await _audit.LogAsync(userId, "ApplicationSubmitted", "Application", application.ApplicationId.ToString(), $"Ứng tuyển thành công (-{cost} credits)");

            return Ok(new
            {
                applicationId = application.ApplicationId,
                status = application.Status,
                message = "Nộp hồ sơ ứng tuyển thành công!"
            });
        }
        catch (DbUpdateException ex)
        {
            await tx.RollbackAsync();
            _logger.LogError(ex, "Duplicate or error submitting application for user {UserId}", userId);
            throw new AppException("Bạn đã nộp hồ sơ ứng tuyển vào dự án này rồi.", "ALREADY_APPLIED", System.Net.HttpStatusCode.Conflict);
        }
        catch (Exception)
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    [HttpGet("api/applications/my")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> GetMyApplications()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var applications = await _db.Applications
            .Include(a => a.Project)
            .Include(a => a.Document)
            .Include(a => a.StatusHistories)
                .ThenInclude(h => h.ChangedByUser)
            .Where(a => a.FreelancerId == userId)
            .OrderByDescending(a => a.AppliedAt)
            .Select(a => new ApplicationDto
            {
                ApplicationId = a.ApplicationId,
                ProjectId = a.ProjectId,
                ProjectTitle = a.Project.Title,
                FreelancerId = a.FreelancerId,
                FreelancerName = a.Freelancer.FullName,
                DocumentId = a.DocumentId,
                OriginalFileName = a.Document.OriginalFileName,
                CoverLetter = a.CoverLetter,
                Status = a.Status,
                AppliedAt = a.AppliedAt,
                UpdatedAt = a.UpdatedAt,
                StatusHistories = a.StatusHistories.OrderByDescending(h => h.ChangedAt).Select(h => new ApplicationStatusHistoryDto
                {
                    HistoryId = h.HistoryId,
                    OldStatus = h.OldStatus,
                    NewStatus = h.NewStatus,
                    ChangedByUserName = h.ChangedByUser.FullName,
                    ChangedAt = h.ChangedAt
                }).ToList()
            })
            .ToListAsync();

        return Ok(applications);
    }

    [HttpGet("api/projects/{projectId}/applications")]
    [Authorize(Roles = "Employer,Admin")]
    public async Task<IActionResult> GetProjectApplications(int projectId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = User.FindFirstValue(ClaimTypes.Role);

        var project = await _db.Projects.FirstOrDefaultAsync(p => p.ProjectId == projectId);
        if (project == null)
        {
            throw new AppException("Dự án không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        // Ownership check
        if (project.EmployerId != userId && role != "Admin")
        {
            throw new AppException("Bạn không có quyền xem danh sách ứng viên của dự án này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        var applications = await _db.Applications
            .Include(a => a.Freelancer)
                .ThenInclude(f => f.FreelancerProfile)
                    .ThenInclude(p => p!.Skills)
            .Include(a => a.Document)
            .Include(a => a.StatusHistories)
                .ThenInclude(h => h.ChangedByUser)
            .Where(a => a.ProjectId == projectId)
            .OrderByDescending(a => a.AppliedAt)
            .Select(a => new ApplicationDto
            {
                ApplicationId = a.ApplicationId,
                ProjectId = a.ProjectId,
                ProjectTitle = project.Title,
                FreelancerId = a.FreelancerId,
                FreelancerName = a.Freelancer.FullName,
                FreelancerHeadline = a.Freelancer.FreelancerProfile != null ? a.Freelancer.FreelancerProfile.Headline : null,
                FreelancerBio = a.Freelancer.FreelancerProfile != null ? a.Freelancer.FreelancerProfile.Bio : null,
                FreelancerExperienceYears = a.Freelancer.FreelancerProfile != null ? a.Freelancer.FreelancerProfile.ExperienceYears : null,
                FreelancerSkills = a.Freelancer.FreelancerProfile != null
                    ? a.Freelancer.FreelancerProfile.Skills.Select(s => s.SkillName).ToList()
                    : new List<string>(),
                DocumentId = a.DocumentId,
                OriginalFileName = a.Document.OriginalFileName,
                CoverLetter = a.CoverLetter,
                Status = a.Status,
                AppliedAt = a.AppliedAt,
                UpdatedAt = a.UpdatedAt,
                StatusHistories = a.StatusHistories.OrderByDescending(h => h.ChangedAt).Select(h => new ApplicationStatusHistoryDto
                {
                    HistoryId = h.HistoryId,
                    OldStatus = h.OldStatus,
                    NewStatus = h.NewStatus,
                    ChangedByUserName = h.ChangedByUser.FullName,
                    ChangedAt = h.ChangedAt
                }).ToList()
            })
            .ToListAsync();

        return Ok(applications);
    }

    [HttpGet("api/applications/{applicationId}")]
    public async Task<IActionResult> GetApplicationDetail(int applicationId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = User.FindFirstValue(ClaimTypes.Role);

        var a = await _db.Applications
            .Include(x => x.Project)
            .Include(x => x.Freelancer)
                .ThenInclude(f => f.FreelancerProfile)
                    .ThenInclude(p => p!.Skills)
            .Include(x => x.Document)
            .Include(x => x.StatusHistories)
                .ThenInclude(h => h.ChangedByUser)
            .FirstOrDefaultAsync(x => x.ApplicationId == applicationId);

        if (a == null)
        {
            throw new AppException("Hồ sơ ứng tuyển không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var isOwnerEmployer = (a.Project.EmployerId == userId);
        var isSubmittingFreelancer = (a.FreelancerId == userId);

        if (!isOwnerEmployer && !isSubmittingFreelancer && role != "Admin")
        {
            throw new AppException("Bạn không có quyền truy cập hồ sơ này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        var dto = new ApplicationDto
        {
            ApplicationId = a.ApplicationId,
            ProjectId = a.ProjectId,
            ProjectTitle = a.Project.Title,
            FreelancerId = a.FreelancerId,
            FreelancerName = a.Freelancer.FullName,
            FreelancerHeadline = a.Freelancer.FreelancerProfile?.Headline,
            FreelancerBio = a.Freelancer.FreelancerProfile?.Bio,
            FreelancerExperienceYears = a.Freelancer.FreelancerProfile?.ExperienceYears,
            FreelancerSkills = a.Freelancer.FreelancerProfile?.Skills.Select(s => s.SkillName).ToList() ?? new List<string>(),
            DocumentId = a.DocumentId,
            OriginalFileName = a.Document.OriginalFileName,
            CoverLetter = a.CoverLetter,
            Status = a.Status,
            AppliedAt = a.AppliedAt,
            UpdatedAt = a.UpdatedAt,
            StatusHistories = a.StatusHistories.OrderByDescending(h => h.ChangedAt).Select(h => new ApplicationStatusHistoryDto
            {
                HistoryId = h.HistoryId,
                OldStatus = h.OldStatus,
                NewStatus = h.NewStatus,
                ChangedByUserName = h.ChangedByUser.FullName,
                ChangedAt = h.ChangedAt
            }).ToList()
        };

        return Ok(dto);
    }

    [HttpGet("api/applications/{applicationId}/cv")]
    public async Task<IActionResult> DownloadApplicationCv(int applicationId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = User.FindFirstValue(ClaimTypes.Role);

        var app = await _db.Applications
            .Include(a => a.Project)
            .Include(a => a.Document)
            .FirstOrDefaultAsync(a => a.ApplicationId == applicationId);

        if (app == null)
        {
            throw new AppException("Hồ sơ ứng tuyển không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var isOwnerEmployer = (app.Project.EmployerId == userId);
        var isSubmittingFreelancer = (app.FreelancerId == userId);

        if (!isOwnerEmployer && !isSubmittingFreelancer && role != "Admin")
        {
            throw new AppException("Bạn không có quyền xem hoặc tải CV của hồ sơ này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        var stream = await _storage.GetFileAsync(app.Document.StorageKey);
        if (stream == null)
        {
            throw new AppException("Tệp CV không tìm thấy trên máy chủ.", "FILE_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        return File(stream, "application/pdf", app.Document.OriginalFileName);
    }

    [HttpPatch("api/applications/{applicationId}/status")]
    [Authorize(Roles = "Employer")]
    public async Task<IActionResult> UpdateStatus(int applicationId, [FromBody] UpdateApplicationStatusRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var validStatuses = new[] { "Reviewing", "Shortlisted", "Accepted", "Rejected" };
        var normalizedStatus = validStatuses.FirstOrDefault(s => string.Equals(s, request.Status.Trim(), StringComparison.OrdinalIgnoreCase));

        if (normalizedStatus == null)
        {
            throw new AppException("Trạng thái không hợp lệ. Chỉ chấp nhận: Reviewing, Shortlisted, Accepted, Rejected.", "INVALID_STATUS");
        }

        var app = await _db.Applications
            .Include(a => a.Project)
                .ThenInclude(p => p.Employer)
                    .ThenInclude(e => e.EmployerProfile)
            .FirstOrDefaultAsync(a => a.ApplicationId == applicationId);

        if (app == null)
        {
            throw new AppException("Hồ sơ ứng tuyển không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        // Ownership check
        if (app.Project.EmployerId != userId)
        {
            throw new AppException("Bạn không phải nhà tuyển dụng sở hữu dự án này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        // Project active check
        if (app.Project.Status == "Closed" || app.Project.Status == "Removed")
        {
            throw new AppException("Không thể thay đổi trạng thái hồ sơ của dự án đã đóng hoặc bị gỡ.", "PROJECT_NOT_ACTIVE");
        }

        // Idempotency: if already in requested status, return early without duplicate history
        if (string.Equals(app.Status, normalizedStatus, StringComparison.OrdinalIgnoreCase))
        {
            return Ok(new { message = $"Hồ sơ đã ở trạng thái '{normalizedStatus}'.", status = normalizedStatus });
        }

        var oldStatus = app.Status;
        app.Status = normalizedStatus;
        app.UpdatedAt = DateTime.UtcNow;

        _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
        {
            ApplicationId = app.ApplicationId,
            OldStatus = oldStatus,
            NewStatus = normalizedStatus,
            ChangedByUserId = userId,
            ChangedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();
        await _audit.LogAsync(userId, "ApplicationStatusChanged", "Application", app.ApplicationId.ToString(), $"Thay đổi trạng thái từ {oldStatus} sang {normalizedStatus}");

        // Create UserNotification for candidate
        var candidateId = app.FreelancerId;
        var statusVN = normalizedStatus switch
        {
            "Reviewing" => "Đang xem xét hồ sơ",
            "Shortlisted" => "Mời phỏng vấn (Shortlisted)",
            "Accepted" => "Được chấp thuận trúng tuyển 🎉",
            "Rejected" => "Từ chối hồ sơ",
            _ => normalizedStatus
        };
        var notifTitle = "HireFlow: Cập nhật trạng thái hồ sơ";
        var companyName = app.Project.Employer?.EmployerProfile?.CompanyName 
            ?? app.Project.Employer?.EmployerProfile?.PublicDisplayName 
            ?? app.Project.Employer?.FullName 
            ?? "Nhà tuyển dụng";
        var notifMessage = $"Hồ sơ ứng tuyển vị trí \"{app.Project.Title}\" của bạn vừa được {companyName} chuyển sang: {statusVN}.";

        var notif = new UserNotification
        {
            UserId = candidateId,
            Title = notifTitle,
            Message = notifMessage,
            Type = "ApplicationStatus",
            ReferenceId = app.ApplicationId,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };
        _db.UserNotifications.Add(notif);
        await _db.SaveChangesAsync();

        // Also trigger real-time Android system notification to the emulator via ADB
        TriggerEmulatorNotification(notifTitle, notifMessage, $"app_{app.ApplicationId}");

        return Ok(new { message = $"Đã cập nhật trạng thái hồ sơ thành '{normalizedStatus}'.", status = normalizedStatus });
    }

    private static void TriggerEmulatorNotification(string title, string message, string tag = "hireflow_status")
    {
        _ = Task.Run(() =>
        {
            try
            {
                var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                var adbPath = System.IO.Path.Combine(localAppData, "Android", "Sdk", "platform-tools", "adb.exe");
                if (!System.IO.File.Exists(adbPath))
                {
                    adbPath = "adb";
                }

                var cleanMessage = message.Replace("\"", "'").Replace("\n", " ");
                var cleanTitle = title.Replace("\"", "'");
                var psi = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = adbPath,
                    Arguments = $"shell cmd notification post -S bigtext -t \"{cleanTitle}\" \"{tag}\" \"{cleanMessage}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                using var proc = System.Diagnostics.Process.Start(psi);
                proc?.WaitForExit(3000);
            }
            catch
            {
                // Silently ignore if ADB is not accessible
            }
        });
    }
}

