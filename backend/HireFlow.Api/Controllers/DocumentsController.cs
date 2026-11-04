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
public class DocumentsController : ControllerBase
{
    private readonly HireFlowDbContext _db;
    private readonly IFileStorageService _storage;
    private readonly ILogger<DocumentsController> _logger;

    public DocumentsController(HireFlowDbContext db, IFileStorageService storage, ILogger<DocumentsController> logger)
    {
        _db = db;
        _storage = storage;
        _logger = logger;
    }

    [HttpPost("cv")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> UploadCv([FromForm] IFormFile? file, [FromForm] bool isDefault = false)
    {
        if (file == null || file.Length == 0)
        {
            throw new AppException("Vui lòng tải lên tệp PDF CV", "FILE_REQUIRED");
        }

        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        try
        {
            using var stream = file.OpenReadStream();
            var (storageKey, size, hash) = await _storage.SavePdfAsync(stream, file.FileName);

            // If marked as default, unset other defaults
            if (isDefault)
            {
                var existingDefaults = await _db.FreelancerDocuments
                    .Where(d => d.FreelancerId == userId && d.IsDefault)
                    .ToListAsync();
                foreach (var d in existingDefaults) d.IsDefault = false;
            }
            else
            {
                // If user has no other CVs, automatically make this one default
                var hasAny = await _db.FreelancerDocuments.AnyAsync(d => d.FreelancerId == userId && !d.IsDeleted);
                if (!hasAny) isDefault = true;
            }

            var doc = new FreelancerDocument
            {
                FreelancerId = userId,
                OriginalFileName = file.FileName,
                StorageKey = storageKey,
                ContentType = "application/pdf",
                FileSize = size,
                ContentHash = hash,
                IsDefault = isDefault,
                UploadedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            _db.FreelancerDocuments.Add(doc);
            await _db.SaveChangesAsync();

            return Ok(new DocumentDto
            {
                DocumentId = doc.DocumentId,
                OriginalFileName = doc.OriginalFileName,
                ContentType = doc.ContentType,
                FileSize = doc.FileSize,
                IsDefault = doc.IsDefault,
                UploadedAt = doc.UploadedAt
            });
        }
        catch (ArgumentException ex)
        {
            throw new AppException(ex.Message, "INVALID_FILE");
        }
    }

    [HttpGet("my-cvs")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> GetMyCvs()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var cvs = await _db.FreelancerDocuments
            .Where(d => d.FreelancerId == userId && !d.IsDeleted)
            .OrderByDescending(d => d.IsDefault)
            .ThenByDescending(d => d.UploadedAt)
            .Select(d => new DocumentDto
            {
                DocumentId = d.DocumentId,
                OriginalFileName = d.OriginalFileName,
                ContentType = d.ContentType,
                FileSize = d.FileSize,
                IsDefault = d.IsDefault,
                UploadedAt = d.UploadedAt
            })
            .ToListAsync();

        return Ok(cvs);
    }

    [HttpGet("{documentId}")]
    public async Task<IActionResult> GetDocument(int documentId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = User.FindFirstValue(ClaimTypes.Role);

        var doc = await _db.FreelancerDocuments.FirstOrDefaultAsync(d => d.DocumentId == documentId);
        if (doc == null || doc.IsDeleted)
        {
            throw new AppException("Tài liệu không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        // CV-007: Authorized access check
        var isOwner = doc.FreelancerId == userId;
        var isAuthorizedEmployer = false;

        if (!isOwner && role == "Employer")
        {
            // Check if this document was submitted to any project owned by this employer
            isAuthorizedEmployer = await _db.Applications
                .Include(a => a.Project)
                .AnyAsync(a => a.DocumentId == documentId && a.Project.EmployerId == userId);
        }

        if (!isOwner && !isAuthorizedEmployer && role != "Admin")
        {
            throw new AppException("Bạn không có quyền truy cập tài liệu này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        return Ok(new DocumentDto
        {
            DocumentId = doc.DocumentId,
            OriginalFileName = doc.OriginalFileName,
            ContentType = doc.ContentType,
            FileSize = doc.FileSize,
            IsDefault = doc.IsDefault,
            UploadedAt = doc.UploadedAt
        });
    }

    [HttpGet("{documentId}/download")]
    public async Task<IActionResult> DownloadCv(int documentId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = User.FindFirstValue(ClaimTypes.Role);

        var doc = await _db.FreelancerDocuments.FirstOrDefaultAsync(d => d.DocumentId == documentId);
        if (doc == null)
        {
            throw new AppException("Tài liệu không tồn tại.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        // CV-007: Authorization check
        var isOwner = doc.FreelancerId == userId;
        var isAuthorizedEmployer = false;

        if (!isOwner && role == "Employer")
        {
            isAuthorizedEmployer = await _db.Applications
                .Include(a => a.Project)
                .AnyAsync(a => a.DocumentId == documentId && a.Project.EmployerId == userId);
        }

        if (!isOwner && !isAuthorizedEmployer && role != "Admin")
        {
            throw new AppException("Bạn không có quyền tải xuống tài liệu này.", "FORBIDDEN", System.Net.HttpStatusCode.Forbidden);
        }

        var stream = await _storage.GetFileAsync(doc.StorageKey);
        if (stream == null)
        {
            throw new AppException("Tệp vật lý không còn tồn tại trên máy chủ.", "FILE_NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        return File(stream, "application/pdf", doc.OriginalFileName);
    }

    [HttpPut("{documentId}/default")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> SetDefault(int documentId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var doc = await _db.FreelancerDocuments
            .FirstOrDefaultAsync(d => d.DocumentId == documentId && d.FreelancerId == userId && !d.IsDeleted);

        if (doc == null)
        {
            throw new AppException("Không tìm thấy CV trong danh sách của bạn.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        var allDocs = await _db.FreelancerDocuments.Where(d => d.FreelancerId == userId).ToListAsync();
        foreach (var d in allDocs)
        {
            d.IsDefault = (d.DocumentId == documentId);
        }

        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã đặt CV làm mặc định." });
    }

    [HttpDelete("{documentId}")]
    [Authorize(Roles = "Freelancer")]
    public async Task<IActionResult> DeleteCv(int documentId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var doc = await _db.FreelancerDocuments
            .FirstOrDefaultAsync(d => d.DocumentId == documentId && d.FreelancerId == userId && !d.IsDeleted);

        if (doc == null)
        {
            throw new AppException("Không tìm thấy CV cần xóa.", "NOT_FOUND", System.Net.HttpStatusCode.NotFound);
        }

        // CV-008: If referenced by existing application, soft delete / archive to keep historical application intact
        var wasDefault = doc.IsDefault;
        var isReferenced = await _db.Applications.AnyAsync(a => a.DocumentId == documentId);
        if (isReferenced)
        {
            doc.IsDeleted = true;
            doc.IsDefault = false;
        }
        else
        {
            _db.FreelancerDocuments.Remove(doc);
            try
            {
                await _storage.DeleteFileAsync(doc.StorageKey);
            }
            catch
            {
                // Ignore physical file delete errors
            }
        }

        if (wasDefault)
        {
            var nextDefault = await _db.FreelancerDocuments
                .Where(d => d.FreelancerId == userId && d.DocumentId != documentId && !d.IsDeleted)
                .OrderByDescending(d => d.UploadedAt)
                .FirstOrDefaultAsync();
            if (nextDefault != null)
            {
                nextDefault.IsDefault = true;
            }
        }

        await _db.SaveChangesAsync();
        return Ok(new { message = "Xóa CV thành công." });
    }
}

