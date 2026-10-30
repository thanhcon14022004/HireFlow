using System.Security.Cryptography;

namespace HireFlow.Api.Services;

public interface IFileStorageService
{
    Task<(string StorageKey, long FileSize, string ContentHash)> SavePdfAsync(Stream fileStream, string originalFileName, CancellationToken ct = default);
    Task<Stream?> GetFileAsync(string storageKey, CancellationToken ct = default);
    Task<bool> DeleteFileAsync(string storageKey, CancellationToken ct = default);
}

public class LocalFileStorageService : IFileStorageService
{
    private readonly string _baseStoragePath;
    private readonly long _maxSizeBytes;
    private static readonly byte[] PdfMagicBytes = new byte[] { 0x25, 0x50, 0x44, 0x46 }; // %PDF

    public LocalFileStorageService(IConfiguration configuration, IWebHostEnvironment env)
    {
        var configuredPath = configuration["FileStorage:StoragePath"] ?? "storage/cvs";
        _baseStoragePath = Path.IsPathRooted(configuredPath)
            ? configuredPath
            : Path.Combine(env.ContentRootPath, configuredPath);

        if (!Directory.Exists(_baseStoragePath))
        {
            Directory.CreateDirectory(_baseStoragePath);
        }

        var maxMb = int.TryParse(configuration["FileStorage:MaxFileSizeMb"], out var mb) ? mb : 5;
        _maxSizeBytes = maxMb * 1024L * 1024L;
    }

    public async Task<(string StorageKey, long FileSize, string ContentHash)> SavePdfAsync(Stream fileStream, string originalFileName, CancellationToken ct = default)
    {
        // 1. Verify extension
        var ext = Path.GetExtension(originalFileName).ToLowerInvariant();
        if (ext != ".pdf")
        {
            throw new ArgumentException("Chỉ chấp nhận tệp định dạng PDF (.pdf)");
        }

        // 2. Read first bytes for magic number validation
        var memoryStream = new MemoryStream();
        await fileStream.CopyToAsync(memoryStream, ct);
        var bytes = memoryStream.ToArray();

        if (bytes.Length > _maxSizeBytes)
        {
            throw new ArgumentException($"Dung lượng tệp vượt quá giới hạn cho phép ({_maxSizeBytes / 1024 / 1024} MB)");
        }

        if (bytes.Length < 4)
        {
            throw new ArgumentException("Tệp PDF không hợp lệ (dung lượng quá nhỏ)");
        }

        for (int i = 0; i < 4; i++)
        {
            if (bytes[i] != PdfMagicBytes[i])
            {
                throw new ArgumentException("Nội dung tệp không phải là định dạng PDF hợp lệ");
            }
        }

        // 3. Compute SHA256 content hash
        using var sha256 = SHA256.Create();
        var hashBytes = sha256.ComputeHash(bytes);
        var contentHash = Convert.ToHexString(hashBytes).ToLowerInvariant();

        // 4. Generate random secure storage key
        var storageKey = $"{Guid.NewGuid():N}.pdf";
        var fullPath = Path.Combine(_baseStoragePath, storageKey);

        await File.WriteAllBytesAsync(fullPath, bytes, ct);

        return (storageKey, bytes.Length, contentHash);
    }

    public Task<Stream?> GetFileAsync(string storageKey, CancellationToken ct = default)
    {
        // Prevent path traversal attacks
        var safeKey = Path.GetFileName(storageKey);
        var fullPath = Path.Combine(_baseStoragePath, safeKey);

        if (!File.Exists(fullPath))
        {
            return Task.FromResult<Stream?>(null);
        }

        var stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read);
        return Task.FromResult<Stream?>(stream);
    }

    public Task<bool> DeleteFileAsync(string storageKey, CancellationToken ct = default)
    {
        var safeKey = Path.GetFileName(storageKey);
        var fullPath = Path.Combine(_baseStoragePath, safeKey);

        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
            return Task.FromResult(true);
        }

        return Task.FromResult(false);
    }
}

