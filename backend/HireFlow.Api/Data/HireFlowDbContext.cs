using HireFlow.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace HireFlow.Api.Data;

public class HireFlowDbContext : DbContext
{
    public HireFlowDbContext(DbContextOptions<HireFlowDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<FreelancerProfile> FreelancerProfiles => Set<FreelancerProfile>();
    public DbSet<FreelancerSkill> FreelancerSkills => Set<FreelancerSkill>();
    public DbSet<EmployerProfile> EmployerProfiles => Set<EmployerProfile>();
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<ProjectSkill> ProjectSkills => Set<ProjectSkill>();
    public DbSet<FreelancerDocument> FreelancerDocuments => Set<FreelancerDocument>();
    public DbSet<Application> Applications => Set<Application>();
    public DbSet<ApplicationStatusHistory> ApplicationStatusHistories => Set<ApplicationStatusHistory>();
    public DbSet<CreditWallet> CreditWallets => Set<CreditWallet>();
    public DbSet<CreditTransaction> CreditTransactions => Set<CreditTransaction>();
    public DbSet<ContactUnlock> ContactUnlocks => Set<ContactUnlock>();
    public DbSet<CreditPackage> CreditPackages => Set<CreditPackage>();
    public DbSet<CreditPurchase> CreditPurchases => Set<CreditPurchase>();
    public DbSet<Report> Reports => Set<Report>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.UserId);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.Property(u => u.Email).IsRequired().HasMaxLength(256);
            entity.Property(u => u.FullName).IsRequired().HasMaxLength(150);
            entity.Property(u => u.Role).IsRequired().HasMaxLength(50);
        });

        // FreelancerProfile
        modelBuilder.Entity<FreelancerProfile>(entity =>
        {
            entity.HasKey(fp => fp.ProfileId);
            entity.HasIndex(fp => fp.UserId).IsUnique();
            entity.HasOne(fp => fp.User)
                .WithOne(u => u.FreelancerProfile)
                .HasForeignKey<FreelancerProfile>(fp => fp.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // FreelancerSkill
        modelBuilder.Entity<FreelancerSkill>(entity =>
        {
            entity.HasKey(s => s.FreelancerSkillId);
            entity.HasOne(s => s.Profile)
                .WithMany(p => p.Skills)
                .HasForeignKey(s => s.FreelancerProfileId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // EmployerProfile
        modelBuilder.Entity<EmployerProfile>(entity =>
        {
            entity.HasKey(ep => ep.EmployerProfileId);
            entity.HasIndex(ep => ep.UserId).IsUnique();
            entity.HasOne(ep => ep.User)
                .WithOne(u => u.EmployerProfile)
                .HasForeignKey<EmployerProfile>(ep => ep.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Project
        modelBuilder.Entity<Project>(entity =>
        {
            entity.HasKey(p => p.ProjectId);
            entity.Property(p => p.Title).IsRequired().HasMaxLength(250);
            entity.Property(p => p.BudgetMin).HasColumnType("decimal(18,2)");
            entity.Property(p => p.BudgetMax).HasColumnType("decimal(18,2)");
            entity.HasOne(p => p.Employer)
                .WithMany(u => u.Projects)
                .HasForeignKey(p => p.EmployerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // ProjectSkill
        modelBuilder.Entity<ProjectSkill>(entity =>
        {
            entity.HasKey(ps => ps.ProjectSkillId);
            entity.HasOne(ps => ps.Project)
                .WithMany(p => p.Skills)
                .HasForeignKey(ps => ps.ProjectId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // FreelancerDocument
        modelBuilder.Entity<FreelancerDocument>(entity =>
        {
            entity.HasKey(d => d.DocumentId);
            entity.Property(d => d.OriginalFileName).IsRequired().HasMaxLength(255);
            entity.Property(d => d.StorageKey).IsRequired().HasMaxLength(255);
            entity.HasOne(d => d.Freelancer)
                .WithMany(u => u.Documents)
                .HasForeignKey(d => d.FreelancerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Application (Unique ProjectId + FreelancerId per APP-005)
        modelBuilder.Entity<Application>(entity =>
        {
            entity.HasKey(a => a.ApplicationId);
            entity.HasIndex(a => new { a.ProjectId, a.FreelancerId }).IsUnique();
            entity.HasOne(a => a.Project)
                .WithMany(p => p.Applications)
                .HasForeignKey(a => a.ProjectId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(a => a.Freelancer)
                .WithMany(u => u.Applications)
                .HasForeignKey(a => a.FreelancerId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(a => a.Document)
                .WithMany(d => d.Applications)
                .HasForeignKey(a => a.DocumentId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // ApplicationStatusHistory
        modelBuilder.Entity<ApplicationStatusHistory>(entity =>
        {
            entity.HasKey(h => h.HistoryId);
            entity.HasOne(h => h.Application)
                .WithMany(a => a.StatusHistories)
                .HasForeignKey(h => h.ApplicationId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(h => h.ChangedByUser)
                .WithMany()
                .HasForeignKey(h => h.ChangedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // CreditWallet
        modelBuilder.Entity<CreditWallet>(entity =>
        {
            entity.HasKey(w => w.WalletId);
            entity.HasIndex(w => w.UserId).IsUnique();
            entity.HasOne(w => w.User)
                .WithOne(u => u.CreditWallet)
                .HasForeignKey<CreditWallet>(w => w.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // CreditTransaction
        modelBuilder.Entity<CreditTransaction>(entity =>
        {
            entity.HasKey(t => t.TransactionId);
            entity.HasIndex(t => t.IdempotencyKey).IsUnique().HasFilter("[IdempotencyKey] IS NOT NULL");
            entity.HasOne(t => t.User)
                .WithMany(u => u.CreditTransactions)
                .HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // ContactUnlock (Unique FreelancerId + EmployerId per CONTACT-004)
        modelBuilder.Entity<ContactUnlock>(entity =>
        {
            entity.HasKey(c => c.ContactUnlockId);
            entity.HasIndex(c => new { c.FreelancerId, c.EmployerId }).IsUnique();
            entity.HasOne(c => c.Freelancer)
                .WithMany(u => u.UnlockedContactsAsFreelancer)
                .HasForeignKey(c => c.FreelancerId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(c => c.Employer)
                .WithMany(u => u.UnlockedContactsAsEmployer)
                .HasForeignKey(c => c.EmployerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // CreditPackage
        modelBuilder.Entity<CreditPackage>(entity =>
        {
            entity.HasKey(cp => cp.CreditPackageId);
            entity.Property(cp => cp.PriceAmount).HasColumnType("decimal(18,2)");
        });

        // CreditPurchase
        modelBuilder.Entity<CreditPurchase>(entity =>
        {
            entity.HasKey(cp => cp.CreditPurchaseId);
            entity.Property(cp => cp.PriceAmount).HasColumnType("decimal(18,2)");
            entity.HasIndex(cp => cp.ProviderReference).IsUnique().HasFilter("[ProviderReference] IS NOT NULL");
            entity.HasOne(cp => cp.User)
                .WithMany(u => u.CreditPurchases)
                .HasForeignKey(cp => cp.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Report
        modelBuilder.Entity<Report>(entity =>
        {
            entity.HasKey(r => r.ReportId);
            entity.HasOne(r => r.ReporterUser)
                .WithMany(u => u.SubmittedReports)
                .HasForeignKey(r => r.ReporterUserId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(r => r.ResolvedByUser)
                .WithMany()
                .HasForeignKey(r => r.ResolvedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // AuditLog
        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(a => a.AuditLogId);
            entity.HasOne(a => a.ActorUser)
                .WithMany(u => u.AuditLogs)
                .HasForeignKey(a => a.ActorUserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // PasswordResetToken
        modelBuilder.Entity<PasswordResetToken>(entity =>
        {
            entity.HasKey(t => t.Id);
            entity.HasOne(t => t.User)
                .WithMany()
                .HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
