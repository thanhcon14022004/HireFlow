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
[Authorize(Roles = "Freelancer,Admin")]
public class FreelancerController : ControllerBase
{
    private readonly HireFlowDbContext _db;

    public FreelancerController(HireFlowDbContext db)
    {
        _db = db;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var user = await _db.Users
            .Include(u => u.FreelancerProfile)
                .ThenInclude(p => p!.Skills)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null)
        {
            throw new AppException("Không tìm thấy người dùng", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var profile = user.FreelancerProfile;
        if (profile == null)
        {
            profile = new FreelancerProfile { UserId = userId, UpdatedAt = DateTime.UtcNow };
            _db.FreelancerProfiles.Add(profile);
            await _db.SaveChangesAsync();
        }

        return Ok(new FreelancerProfileDto
        {
            ProfileId = profile.ProfileId,
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            AvatarStorageKey = profile.AvatarStorageKey,
            Headline = profile.Headline,
            Bio = profile.Bio,
            ExperienceYears = profile.ExperienceYears,
            Skills = profile.Skills.Select(s => s.SkillName).ToList(),
            UpdatedAt = profile.UpdatedAt
        });
    }

    [HttpPut("profile")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateFreelancerProfileRequest request)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var user = await _db.Users
            .Include(u => u.FreelancerProfile)
                .ThenInclude(p => p!.Skills)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null)
        {
            throw new AppException("Không tìm thấy người dùng", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        if (!string.IsNullOrWhiteSpace(request.FullName))
        {
            user.FullName = request.FullName.Trim();
        }

        var profile = user.FreelancerProfile;
        if (profile == null)
        {
            profile = new FreelancerProfile { UserId = userId };
            _db.FreelancerProfiles.Add(profile);
        }

        profile.Headline = request.Headline?.Trim();
        profile.Bio = request.Bio?.Trim();
        profile.ExperienceYears = request.ExperienceYears;
        profile.UpdatedAt = DateTime.UtcNow;

        // Update skills
        _db.FreelancerSkills.RemoveRange(profile.Skills);
        profile.Skills.Clear();
        if (request.Skills != null)
        {
            foreach (var skill in request.Skills.Where(s => !string.IsNullOrWhiteSpace(s)).Distinct())
            {
                profile.Skills.Add(new FreelancerSkill
                {
                    FreelancerProfileId = profile.ProfileId,
                    SkillName = skill.Trim()
                });
            }
        }

        await _db.SaveChangesAsync();

        return Ok(new FreelancerProfileDto
        {
            ProfileId = profile.ProfileId,
            UserId = user.UserId,
            FullName = user.FullName,
            Email = user.Email,
            AvatarStorageKey = profile.AvatarStorageKey,
            Headline = profile.Headline,
            Bio = profile.Bio,
            ExperienceYears = profile.ExperienceYears,
            Skills = profile.Skills.Select(s => s.SkillName).ToList(),
            UpdatedAt = profile.UpdatedAt
        });
    }
}
