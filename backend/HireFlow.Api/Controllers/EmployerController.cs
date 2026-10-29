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
[Authorize(Roles = "Employer,Admin")]
public class EmployerController : ControllerBase
{
    private readonly HireFlowDbContext _db;

    public EmployerController(HireFlowDbContext db)
    {
        _db = db;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var user = await _db.Users
            .Include(u => u.EmployerProfile)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null)
        {
            throw new AppException("Không tìm thấy người dùng", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var profile = user.EmployerProfile;
        if (profile == null)
        {
            profile = new EmployerProfile
            {
                UserId = userId,
                CompanyName = user.FullName,
                PublicDisplayName = user.FullName,
                ContactEmail = user.Email,
                UpdatedAt = DateTime.UtcNow
            };
            _db.EmployerProfiles.Add(profile);
            await _db.SaveChangesAsync();
        }

        return Ok(new EmployerProfileDto
        {
            EmployerProfileId = profile.EmployerProfileId,
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            CompanyName = profile.CompanyName,
            Description = profile.Description,
            PublicDisplayName = profile.PublicDisplayName,
            ContactEmail = profile.ContactEmail,
            ContactPhone = profile.ContactPhone,
            UpdatedAt = profile.UpdatedAt
        });
    }

    [HttpPut("profile")]
    [Authorize(Roles = "Employer")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateEmployerProfileRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var user = await _db.Users
            .Include(u => u.EmployerProfile)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null)
        {
            throw new AppException("Không tìm thấy người dùng", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (!string.IsNullOrWhiteSpace(request.FullName))
        {
            user.FullName = request.FullName.Trim();
        }

        var profile = user.EmployerProfile;
        if (profile == null)
        {
            profile = new EmployerProfile { UserId = userId };
            _db.EmployerProfiles.Add(profile);
        }

        profile.CompanyName = request.CompanyName?.Trim();
        profile.Description = request.Description?.Trim();
        profile.PublicDisplayName = request.PublicDisplayName?.Trim();
        profile.ContactEmail = request.ContactEmail?.Trim();
        profile.ContactPhone = request.ContactPhone?.Trim();
        profile.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(new EmployerProfileDto
        {
            EmployerProfileId = profile.EmployerProfileId,
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            CompanyName = profile.CompanyName,
            Description = profile.Description,
            PublicDisplayName = profile.PublicDisplayName,
            ContactEmail = profile.ContactEmail,
            ContactPhone = profile.ContactPhone,
            UpdatedAt = profile.UpdatedAt
        });
    }

    [HttpGet("projects")]
    [Authorize(Roles = "Employer")]
    public async Task<IActionResult> GetMyProjects()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var projects = await _db.Projects
            .Include(p => p.Skills)
            .Include(p => p.Employer)
                .ThenInclude(e => e.EmployerProfile)
            .Include(p => p.Applications)
            .Where(p => p.EmployerId == userId)
            .OrderByDescending(p => p.CreatedAt)
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

        return Ok(projects);
    }
}
