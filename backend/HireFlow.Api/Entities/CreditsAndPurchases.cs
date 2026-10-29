using System.ComponentModel.DataAnnotations;

namespace HireFlow.Api.Entities;

public class CreditWallet
{
    public int WalletId { get; set; }
    public int UserId { get; set; }
    public int Balance { get; set; } = 0;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [Timestamp]
    public byte[]? RowVersion { get; set; }

    public User User { get; set; } = null!;
}

public class CreditTransaction
{
    public int TransactionId { get; set; }
    public int UserId { get; set; }
    public int Amount { get; set; } // Negative for deductions, positive for additions
    public string TransactionType { get; set; } = string.Empty; // ApplicationFee, ContactUnlock, ProjectPublish, CreditPurchase, AdminAdjustment
    public string ReferenceType { get; set; } = string.Empty; // Application, Project, ContactUnlock, Purchase, Admin
    public string? ReferenceId { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? IdempotencyKey { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}

public class ContactUnlock
{
    public int ContactUnlockId { get; set; }
    public int FreelancerId { get; set; }
    public int EmployerId { get; set; }
    public int? ProjectId { get; set; }
    public DateTime UnlockedAt { get; set; } = DateTime.UtcNow;

    public User Freelancer { get; set; } = null!;
    public User Employer { get; set; } = null!;
}

public class CreditPackage
{
    public int CreditPackageId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int CreditAmount { get; set; }
    public decimal PriceAmount { get; set; }
    public string CurrencyCode { get; set; } = "VND";
    public bool IsActive { get; set; } = true;
    public int DisplayOrder { get; set; } = 0;
}

public class CreditPurchase
{
    public int CreditPurchaseId { get; set; }
    public int UserId { get; set; }
    public int CreditPackageId { get; set; }
    public int CreditsPurchased { get; set; }
    public decimal PriceAmount { get; set; }
    public string CurrencyCode { get; set; } = "VND";
    public string PaymentProvider { get; set; } = "DevSimulator";
    public string? ProviderReference { get; set; }
    public string Status { get; set; } = "Pending"; // Pending, Paid, Failed, Cancelled
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PaidAt { get; set; }

    public User User { get; set; } = null!;
    public CreditPackage? Package { get; set; }
}
