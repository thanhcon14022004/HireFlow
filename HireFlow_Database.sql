-- ============================================================================
-- HIREFLOW FREELANCE PLATFORM - COMPLETE DATABASE SCRIPT
-- Compatible with Microsoft SQL Server 2019 / 2022 / Azure SQL / LocalDB
-- Database: HireFlowDb
-- ============================================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'HireFlowDb')
BEGIN
    CREATE DATABASE [HireFlowDb];
END;
GO

USE [HireFlowDb];
GO

-- 1. Create Migration History Table (for EF Core alignment)
IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] NVARCHAR(150) NOT NULL,
        [ProductVersion] NVARCHAR(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

-- 2. Drop existing tables if re-initializing in order of foreign key dependency
-- (Leave commented out to prevent accidental deletion in production)
/*
IF OBJECT_ID(N'[PasswordResetTokens]', N'U') IS NOT NULL DROP TABLE [PasswordResetTokens];
IF OBJECT_ID(N'[AuditLogs]', N'U') IS NOT NULL DROP TABLE [AuditLogs];
IF OBJECT_ID(N'[Reports]', N'U') IS NOT NULL DROP TABLE [Reports];
IF OBJECT_ID(N'[ApplicationStatusHistories]', N'U') IS NOT NULL DROP TABLE [ApplicationStatusHistories];
IF OBJECT_ID(N'[Applications]', N'U') IS NOT NULL DROP TABLE [Applications];
IF OBJECT_ID(N'[ProjectSkills]', N'U') IS NOT NULL DROP TABLE [ProjectSkills];
IF OBJECT_ID(N'[ContactUnlocks]', N'U') IS NOT NULL DROP TABLE [ContactUnlocks];
IF OBJECT_ID(N'[Projects]', N'U') IS NOT NULL DROP TABLE [Projects];
IF OBJECT_ID(N'[FreelancerDocuments]', N'U') IS NOT NULL DROP TABLE [FreelancerDocuments];
IF OBJECT_ID(N'[FreelancerSkills]', N'U') IS NOT NULL DROP TABLE [FreelancerSkills];
IF OBJECT_ID(N'[FreelancerProfiles]', N'U') IS NOT NULL DROP TABLE [FreelancerProfiles];
IF OBJECT_ID(N'[EmployerProfiles]', N'U') IS NOT NULL DROP TABLE [EmployerProfiles];
IF OBJECT_ID(N'[CreditPurchases]', N'U') IS NOT NULL DROP TABLE [CreditPurchases];
IF OBJECT_ID(N'[CreditTransactions]', N'U') IS NOT NULL DROP TABLE [CreditTransactions];
IF OBJECT_ID(N'[CreditWallets]', N'U') IS NOT NULL DROP TABLE [CreditWallets];
IF OBJECT_ID(N'[CreditPackages]', N'U') IS NOT NULL DROP TABLE [CreditPackages];
IF OBJECT_ID(N'[Users]', N'U') IS NOT NULL DROP TABLE [Users];
*/

-- ============================================================================
-- TABLE CREATION
-- ============================================================================

-- Table: Users
IF OBJECT_ID(N'[Users]', N'U') IS NULL
BEGIN
    CREATE TABLE [Users] (
        [UserId] INT NOT NULL IDENTITY(1,1),
        [FullName] NVARCHAR(150) NOT NULL,
        [Email] NVARCHAR(256) NOT NULL,
        [PasswordHash] NVARCHAR(MAX) NOT NULL,
        [Role] NVARCHAR(50) NOT NULL, -- Admin, Employer, Freelancer
        [IsActive] BIT NOT NULL CONSTRAINT [DF_Users_IsActive] DEFAULT(1),
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Users_CreatedAt] DEFAULT(SYSUTCDATETIME()),
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Users_UpdatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_Users] PRIMARY KEY ([UserId])
    );
    CREATE UNIQUE NONCLUSTERED INDEX [IX_Users_Email] ON [Users] ([Email]);
END;
GO

-- Table: CreditWallets
IF OBJECT_ID(N'[CreditWallets]', N'U') IS NULL
BEGIN
    CREATE TABLE [CreditWallets] (
        [WalletId] INT NOT NULL IDENTITY(1,1),
        [UserId] INT NOT NULL,
        [Balance] INT NOT NULL CONSTRAINT [DF_CreditWallets_Balance] DEFAULT(0),
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_CreditWallets_UpdatedAt] DEFAULT(SYSUTCDATETIME()),
        [RowVersion] ROWVERSION NULL,
        CONSTRAINT [PK_CreditWallets] PRIMARY KEY ([WalletId]),
        CONSTRAINT [FK_CreditWallets_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
    );
    CREATE UNIQUE NONCLUSTERED INDEX [IX_CreditWallets_UserId] ON [CreditWallets] ([UserId]);
END;
GO

-- Table: CreditPackages
IF OBJECT_ID(N'[CreditPackages]', N'U') IS NULL
BEGIN
    CREATE TABLE [CreditPackages] (
        [CreditPackageId] INT NOT NULL IDENTITY(1,1),
        [Name] NVARCHAR(200) NOT NULL,
        [CreditAmount] INT NOT NULL,
        [PriceAmount] DECIMAL(18,2) NOT NULL,
        [CurrencyCode] NVARCHAR(10) NOT NULL CONSTRAINT [DF_CreditPackages_CurrencyCode] DEFAULT('VND'),
        [IsActive] BIT NOT NULL CONSTRAINT [DF_CreditPackages_IsActive] DEFAULT(1),
        [DisplayOrder] INT NOT NULL CONSTRAINT [DF_CreditPackages_DisplayOrder] DEFAULT(0),
        CONSTRAINT [PK_CreditPackages] PRIMARY KEY ([CreditPackageId])
    );
END;
GO

-- Table: CreditPurchases
IF OBJECT_ID(N'[CreditPurchases]', N'U') IS NULL
BEGIN
    CREATE TABLE [CreditPurchases] (
        [CreditPurchaseId] INT NOT NULL IDENTITY(1,1),
        [UserId] INT NOT NULL,
        [CreditPackageId] INT NOT NULL,
        [CreditsPurchased] INT NOT NULL,
        [PriceAmount] DECIMAL(18,2) NOT NULL,
        [CurrencyCode] NVARCHAR(10) NOT NULL CONSTRAINT [DF_CreditPurchases_CurrencyCode] DEFAULT('VND'),
        [PaymentProvider] NVARCHAR(100) NOT NULL,
        [ProviderReference] NVARCHAR(250) NULL,
        [Status] NVARCHAR(50) NOT NULL, -- Pending, Paid, Failed, Cancelled
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_CreditPurchases_CreatedAt] DEFAULT(SYSUTCDATETIME()),
        [PaidAt] DATETIME2 NULL,
        CONSTRAINT [PK_CreditPurchases] PRIMARY KEY ([CreditPurchaseId]),
        CONSTRAINT [FK_CreditPurchases_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION,
        CONSTRAINT [FK_CreditPurchases_CreditPackages_CreditPackageId] FOREIGN KEY ([CreditPackageId]) REFERENCES [CreditPackages] ([CreditPackageId]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_CreditPurchases_UserId] ON [CreditPurchases] ([UserId]);
    CREATE NONCLUSTERED INDEX [IX_CreditPurchases_CreditPackageId] ON [CreditPurchases] ([CreditPackageId]);
END;
GO

-- Table: CreditTransactions
IF OBJECT_ID(N'[CreditTransactions]', N'U') IS NULL
BEGIN
    CREATE TABLE [CreditTransactions] (
        [TransactionId] INT NOT NULL IDENTITY(1,1),
        [UserId] INT NOT NULL,
        [Amount] INT NOT NULL,
        [TransactionType] NVARCHAR(100) NOT NULL, -- ApplicationFee, ContactUnlock, ProjectPublish, CreditPurchase, AdminAdjustment
        [ReferenceType] NVARCHAR(100) NOT NULL,
        [ReferenceId] NVARCHAR(250) NULL,
        [Description] NVARCHAR(500) NOT NULL,
        [IdempotencyKey] NVARCHAR(250) NULL,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_CreditTransactions_CreatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_CreditTransactions] PRIMARY KEY ([TransactionId]),
        CONSTRAINT [FK_CreditTransactions_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
    );
    CREATE NONCLUSTERED INDEX [IX_CreditTransactions_UserId] ON [CreditTransactions] ([UserId]);
    CREATE NONCLUSTERED INDEX [IX_CreditTransactions_IdempotencyKey] ON [CreditTransactions] ([IdempotencyKey]);
END;
GO

-- Table: FreelancerProfiles
IF OBJECT_ID(N'[FreelancerProfiles]', N'U') IS NULL
BEGIN
    CREATE TABLE [FreelancerProfiles] (
        [ProfileId] INT NOT NULL IDENTITY(1,1),
        [UserId] INT NOT NULL,
        [AvatarStorageKey] NVARCHAR(500) NULL,
        [Headline] NVARCHAR(250) NULL,
        [Bio] NVARCHAR(MAX) NULL,
        [ExperienceYears] INT NULL,
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_FreelancerProfiles_UpdatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_FreelancerProfiles] PRIMARY KEY ([ProfileId]),
        CONSTRAINT [FK_FreelancerProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
    );
    CREATE UNIQUE NONCLUSTERED INDEX [IX_FreelancerProfiles_UserId] ON [FreelancerProfiles] ([UserId]);
END;
GO

-- Table: FreelancerSkills
IF OBJECT_ID(N'[FreelancerSkills]', N'U') IS NULL
BEGIN
    CREATE TABLE [FreelancerSkills] (
        [SkillId] INT NOT NULL IDENTITY(1,1),
        [FreelancerProfileId] INT NOT NULL,
        [SkillName] NVARCHAR(100) NOT NULL,
        CONSTRAINT [PK_FreelancerSkills] PRIMARY KEY ([SkillId]),
        CONSTRAINT [FK_FreelancerSkills_FreelancerProfiles_FreelancerProfileId] FOREIGN KEY ([FreelancerProfileId]) REFERENCES [FreelancerProfiles] ([ProfileId]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_FreelancerSkills_FreelancerProfileId] ON [FreelancerSkills] ([FreelancerProfileId]);
END;
GO

-- Table: EmployerProfiles
IF OBJECT_ID(N'[EmployerProfiles]', N'U') IS NULL
BEGIN
    CREATE TABLE [EmployerProfiles] (
        [EmployerProfileId] INT NOT NULL IDENTITY(1,1),
        [UserId] INT NOT NULL,
        [CompanyName] NVARCHAR(200) NULL,
        [Description] NVARCHAR(MAX) NULL,
        [PublicDisplayName] NVARCHAR(150) NOT NULL,
        [ContactEmail] NVARCHAR(256) NOT NULL,
        [ContactPhone] NVARCHAR(50) NULL,
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_EmployerProfiles_UpdatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_EmployerProfiles] PRIMARY KEY ([EmployerProfileId]),
        CONSTRAINT [FK_EmployerProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
    );
    CREATE UNIQUE NONCLUSTERED INDEX [IX_EmployerProfiles_UserId] ON [EmployerProfiles] ([UserId]);
END;
GO

-- Table: FreelancerDocuments (PDF CVs)
IF OBJECT_ID(N'[FreelancerDocuments]', N'U') IS NULL
BEGIN
    CREATE TABLE [FreelancerDocuments] (
        [DocumentId] INT NOT NULL IDENTITY(1,1),
        [FreelancerId] INT NOT NULL,
        [StorageKey] NVARCHAR(500) NOT NULL,
        [OriginalFileName] NVARCHAR(250) NOT NULL,
        [ContentType] NVARCHAR(100) NOT NULL,
        [FileSize] BIGINT NOT NULL,
        [FileHash] NVARCHAR(128) NOT NULL,
        [IsDefault] BIT NOT NULL CONSTRAINT [DF_FreelancerDocuments_IsDefault] DEFAULT(0),
        [IsDeleted] BIT NOT NULL CONSTRAINT [DF_FreelancerDocuments_IsDeleted] DEFAULT(0),
        [UploadedAt] DATETIME2 NOT NULL CONSTRAINT [DF_FreelancerDocuments_UploadedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_FreelancerDocuments] PRIMARY KEY ([DocumentId]),
        CONSTRAINT [FK_FreelancerDocuments_Users_FreelancerId] FOREIGN KEY ([FreelancerId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_FreelancerDocuments_FreelancerId] ON [FreelancerDocuments] ([FreelancerId]);
END;
GO

-- Table: Projects
IF OBJECT_ID(N'[Projects]', N'U') IS NULL
BEGIN
    CREATE TABLE [Projects] (
        [ProjectId] INT NOT NULL IDENTITY(1,1),
        [EmployerId] INT NOT NULL,
        [Title] NVARCHAR(250) NOT NULL,
        [Description] NVARCHAR(MAX) NOT NULL,
        [BudgetMin] DECIMAL(18,2) NULL,
        [BudgetMax] DECIMAL(18,2) NULL,
        [CurrencyCode] NVARCHAR(10) NOT NULL CONSTRAINT [DF_Projects_CurrencyCode] DEFAULT('VND'),
        [ExperienceLevel] NVARCHAR(100) NULL,
        [Deadline] DATETIME2 NULL,
        [Status] NVARCHAR(50) NOT NULL CONSTRAINT [DF_Projects_Status] DEFAULT('Open'), -- Open, Closed, Hidden, Removed
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Projects_CreatedAt] DEFAULT(SYSUTCDATETIME()),
        [PublishedAt] DATETIME2 NULL,
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Projects_UpdatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_Projects] PRIMARY KEY ([ProjectId]),
        CONSTRAINT [FK_Projects_Users_EmployerId] FOREIGN KEY ([EmployerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
    );
    CREATE NONCLUSTERED INDEX [IX_Projects_EmployerId] ON [Projects] ([EmployerId]);
    CREATE NONCLUSTERED INDEX [IX_Projects_Status] ON [Projects] ([Status]);
END;
GO

-- Table: ProjectSkills
IF OBJECT_ID(N'[ProjectSkills]', N'U') IS NULL
BEGIN
    CREATE TABLE [ProjectSkills] (
        [ProjectSkillId] INT NOT NULL IDENTITY(1,1),
        [ProjectId] INT NOT NULL,
        [SkillName] NVARCHAR(100) NOT NULL,
        CONSTRAINT [PK_ProjectSkills] PRIMARY KEY ([ProjectSkillId]),
        CONSTRAINT [FK_ProjectSkills_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([ProjectId]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_ProjectSkills_ProjectId] ON [ProjectSkills] ([ProjectId]);
END;
GO

-- Table: Applications
IF OBJECT_ID(N'[Applications]', N'U') IS NULL
BEGIN
    CREATE TABLE [Applications] (
        [ApplicationId] INT NOT NULL IDENTITY(1,1),
        [ProjectId] INT NOT NULL,
        [FreelancerId] INT NOT NULL,
        [DocumentId] INT NOT NULL,
        [CoverLetter] NVARCHAR(MAX) NULL,
        [Status] NVARCHAR(50) NOT NULL CONSTRAINT [DF_Applications_Status] DEFAULT('Pending'), -- Pending, Reviewing, Shortlisted, Accepted, Rejected
        [AppliedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Applications_AppliedAt] DEFAULT(SYSUTCDATETIME()),
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Applications_UpdatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_Applications] PRIMARY KEY ([ApplicationId]),
        CONSTRAINT [FK_Applications_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([ProjectId]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Applications_Users_FreelancerId] FOREIGN KEY ([FreelancerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Applications_FreelancerDocuments_DocumentId] FOREIGN KEY ([DocumentId]) REFERENCES [FreelancerDocuments] ([DocumentId]) ON DELETE NO ACTION
    );
    CREATE UNIQUE NONCLUSTERED INDEX [IX_Applications_ProjectId_FreelancerId] ON [Applications] ([ProjectId], [FreelancerId]);
    CREATE NONCLUSTERED INDEX [IX_Applications_FreelancerId] ON [Applications] ([FreelancerId]);
    CREATE NONCLUSTERED INDEX [IX_Applications_DocumentId] ON [Applications] ([DocumentId]);
END;
GO

-- Table: ApplicationStatusHistories
IF OBJECT_ID(N'[ApplicationStatusHistories]', N'U') IS NULL
BEGIN
    CREATE TABLE [ApplicationStatusHistories] (
        [HistoryId] INT NOT NULL IDENTITY(1,1),
        [ApplicationId] INT NOT NULL,
        [OldStatus] NVARCHAR(50) NOT NULL,
        [NewStatus] NVARCHAR(50) NOT NULL,
        [ChangedByUserId] INT NOT NULL,
        [ChangedAt] DATETIME2 NOT NULL CONSTRAINT [DF_ApplicationStatusHistories_ChangedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_ApplicationStatusHistories] PRIMARY KEY ([HistoryId]),
        CONSTRAINT [FK_ApplicationStatusHistories_Applications_ApplicationId] FOREIGN KEY ([ApplicationId]) REFERENCES [Applications] ([ApplicationId]) ON DELETE CASCADE,
        CONSTRAINT [FK_ApplicationStatusHistories_Users_ChangedByUserId] FOREIGN KEY ([ChangedByUserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
    );
    CREATE NONCLUSTERED INDEX [IX_ApplicationStatusHistories_ApplicationId] ON [ApplicationStatusHistories] ([ApplicationId]);
    CREATE NONCLUSTERED INDEX [IX_ApplicationStatusHistories_ChangedByUserId] ON [ApplicationStatusHistories] ([ChangedByUserId]);
END;
GO

-- Table: ContactUnlocks
IF OBJECT_ID(N'[ContactUnlocks]', N'U') IS NULL
BEGIN
    CREATE TABLE [ContactUnlocks] (
        [ContactUnlockId] INT NOT NULL IDENTITY(1,1),
        [FreelancerId] INT NOT NULL,
        [EmployerId] INT NOT NULL,
        [ProjectId] INT NULL,
        [UnlockedAt] DATETIME2 NOT NULL CONSTRAINT [DF_ContactUnlocks_UnlockedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_ContactUnlocks] PRIMARY KEY ([ContactUnlockId]),
        CONSTRAINT [FK_ContactUnlocks_Users_FreelancerId] FOREIGN KEY ([FreelancerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION,
        CONSTRAINT [FK_ContactUnlocks_Users_EmployerId] FOREIGN KEY ([EmployerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
    );
    CREATE UNIQUE NONCLUSTERED INDEX [IX_ContactUnlocks_FreelancerId_EmployerId] ON [ContactUnlocks] ([FreelancerId], [EmployerId]);
    CREATE NONCLUSTERED INDEX [IX_ContactUnlocks_EmployerId] ON [ContactUnlocks] ([EmployerId]);
END;
GO

-- Table: Reports
IF OBJECT_ID(N'[Reports]', N'U') IS NULL
BEGIN
    CREATE TABLE [Reports] (
        [ReportId] INT NOT NULL IDENTITY(1,1),
        [ReporterUserId] INT NOT NULL,
        [TargetType] NVARCHAR(50) NOT NULL, -- Project, User, Document
        [TargetId] INT NOT NULL,
        [Reason] NVARCHAR(250) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [Status] NVARCHAR(50) NOT NULL CONSTRAINT [DF_Reports_Status] DEFAULT('Pending'), -- Pending, Reviewing, Resolved, Rejected
        [ResolvedByUserId] INT NULL,
        [ResolvedAt] DATETIME2 NULL,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Reports_CreatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_Reports] PRIMARY KEY ([ReportId]),
        CONSTRAINT [FK_Reports_Users_ReporterUserId] FOREIGN KEY ([ReporterUserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Reports_Users_ResolvedByUserId] FOREIGN KEY ([ResolvedByUserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
    );
    CREATE NONCLUSTERED INDEX [IX_Reports_ReporterUserId] ON [Reports] ([ReporterUserId]);
    CREATE NONCLUSTERED INDEX [IX_Reports_ResolvedByUserId] ON [Reports] ([ResolvedByUserId]);
END;
GO

-- Table: AuditLogs
IF OBJECT_ID(N'[AuditLogs]', N'U') IS NULL
BEGIN
    CREATE TABLE [AuditLogs] (
        [AuditLogId] INT NOT NULL IDENTITY(1,1),
        [ActorUserId] INT NULL,
        [Action] NVARCHAR(100) NOT NULL,
        [EntityType] NVARCHAR(100) NOT NULL,
        [EntityId] NVARCHAR(250) NULL,
        [Details] NVARCHAR(MAX) NULL,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_AuditLogs_CreatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_AuditLogs] PRIMARY KEY ([AuditLogId]),
        CONSTRAINT [FK_AuditLogs_Users_ActorUserId] FOREIGN KEY ([ActorUserId]) REFERENCES [Users] ([UserId]) ON DELETE SET NULL
    );
    CREATE NONCLUSTERED INDEX [IX_AuditLogs_ActorUserId] ON [AuditLogs] ([ActorUserId]);
END;
GO

-- Table: PasswordResetTokens
IF OBJECT_ID(N'[PasswordResetTokens]', N'U') IS NULL
BEGIN
    CREATE TABLE [PasswordResetTokens] (
        [TokenId] INT NOT NULL IDENTITY(1,1),
        [UserId] INT NOT NULL,
        [Code] NVARCHAR(50) NOT NULL,
        [TokenHash] NVARCHAR(MAX) NOT NULL,
        [ExpiresAt] DATETIME2 NOT NULL,
        [IsUsed] BIT NOT NULL CONSTRAINT [DF_PasswordResetTokens_IsUsed] DEFAULT(0),
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_PasswordResetTokens_CreatedAt] DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT [PK_PasswordResetTokens] PRIMARY KEY ([TokenId]),
        CONSTRAINT [FK_PasswordResetTokens_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_PasswordResetTokens_UserId] ON [PasswordResetTokens] ([UserId]);
END;
GO

-- Mark Initial Migration as applied
IF NOT EXISTS (SELECT * FROM [__EFMigrationsHistory] WHERE [MigrationId] = N'20261029205450_InitialCreate')
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261029205450_InitialCreate', N'8.0.0');
END;
GO

-- ============================================================================
-- SEED INITIAL DATA (DEFAULT PACKAGES, USERS, PROFILES, PROJECTS)
-- ============================================================================

-- 1. Seed Credit Packages
IF NOT EXISTS (SELECT 1 FROM [CreditPackages])
BEGIN
    INSERT INTO [CreditPackages] ([Name], [CreditAmount], [PriceAmount], [CurrencyCode], [IsActive], [DisplayOrder])
    VALUES 
        (N'Gói Khởi Đầu (10 Credits)', 10, 20000.00, N'VND', 1, 1),
        (N'Gói Tiêu Chuẩn (50 Credits)', 50, 100000.00, N'VND', 1, 2),
        (N'Gói Doanh Nghiệp (150 Credits)', 150, 300000.00, N'VND', 1, 3);
END;
GO

-- 2. Seed Admin Account
-- Email: admin@hireflow.com
-- Password: Admin@HireFlow2026!
IF NOT EXISTS (SELECT 1 FROM [Users] WHERE [Email] = N'admin@hireflow.com')
BEGIN
    INSERT INTO [Users] ([FullName], [Email], [PasswordHash], [Role], [IsActive], [CreatedAt], [UpdatedAt])
    VALUES (
        N'Quản Trị Viên Hệ Thống',
        N'admin@hireflow.com',
        N'100000.Yg/9brzyw+TRdzlqsKa7FQ==.nQVN0Sb1JqlirVol3rLkeIArtSJU6GRKFgez9GKIjm4=',
        N'Admin',
        1,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    DECLARE @AdminUserId INT = SCOPE_IDENTITY();
    INSERT INTO [CreditWallets] ([UserId], [Balance], [UpdatedAt])
    VALUES (@AdminUserId, 9999, SYSUTCDATETIME());
END;
GO

-- 3. Seed Employer Account
-- Email: employer@hireflow.com
-- Password: Employer@123!
IF NOT EXISTS (SELECT 1 FROM [Users] WHERE [Email] = N'employer@hireflow.com')
BEGIN
    INSERT INTO [Users] ([FullName], [Email], [PasswordHash], [Role], [IsActive], [CreatedAt], [UpdatedAt])
    VALUES (
        N'Nguyễn Văn Doanh',
        N'employer@hireflow.com',
        N'100000.SnXURdWXLRXH3bhe+nZpOQ==./9N14U6iAQP2mLGwxDfqIy+9Y1X0LCy759I7Avi4NZw=',
        N'Employer',
        1,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    DECLARE @EmployerUserId INT = SCOPE_IDENTITY();
    INSERT INTO [CreditWallets] ([UserId], [Balance], [UpdatedAt])
    VALUES (@EmployerUserId, 50, SYSUTCDATETIME());

    INSERT INTO [EmployerProfiles] ([UserId], [CompanyName], [PublicDisplayName], [Description], [ContactEmail], [ContactPhone], [UpdatedAt])
    VALUES (
        @EmployerUserId,
        N'Công ty Công nghệ TechNova',
        N'TechNova Solutions VN',
        N'Công ty phát triển phần mềm doanh nghiệp và giải pháp số hàng đầu tại TP.HCM.',
        N'contact@technova.vn',
        N'0909123456',
        SYSUTCDATETIME()
    );

    -- Seed Sample Project 1
    INSERT INTO [Projects] ([EmployerId], [Title], [Description], [BudgetMin], [BudgetMax], [CurrencyCode], [ExperienceLevel], [Deadline], [Status], [CreatedAt], [PublishedAt], [UpdatedAt])
    VALUES (
        @EmployerUserId,
        N'Xây dựng Hệ thống Quản lý Bán hàng Đa kênh (Omnichannel) với .NET 8',
        N'Chúng tôi đang tìm kiếm Senior .NET Developer để xây dựng hệ thống quản lý đơn hàng tập trung, tích hợp Shopee, TikTok Shop và POS cửa hàng. Yêu cầu thành thạo Clean Architecture, EF Core, SQL Server và RabbitMQ.',
        20000000.00,
        35000000.00,
        N'VND',
        N'Cao cấp (3+ năm)',
        DATEADD(DAY, 45, SYSUTCDATETIME()),
        N'Open',
        SYSUTCDATETIME(),
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );
    DECLARE @Proj1Id INT = SCOPE_IDENTITY();
    INSERT INTO [ProjectSkills] ([ProjectId], [SkillName])
    VALUES (@Proj1Id, N'.NET 8'), (@Proj1Id, N'C#'), (@Proj1Id, N'SQL Server'), (@Proj1Id, N'Clean Architecture');

    -- Seed Sample Project 2
    INSERT INTO [Projects] ([EmployerId], [Title], [Description], [BudgetMin], [BudgetMax], [CurrencyCode], [ExperienceLevel], [Deadline], [Status], [CreatedAt], [PublishedAt], [UpdatedAt])
    VALUES (
        @EmployerUserId,
        N'Phát triển Ứng dụng Di động Flutter Thương mại Điện tử',
        N'Cần một lập trình viên Flutter có kinh nghiệm để xây dựng ứng dụng mua sắm trực tuyến kết nối REST API, tích hợp cổng thanh toán và thông báo đẩy. Yêu cầu clean architecture và Riverpod/Provider.',
        15000000.00,
        25000000.00,
        N'VND',
        N'Trung cấp (2-3 năm)',
        DATEADD(DAY, 30, SYSUTCDATETIME()),
        N'Open',
        SYSUTCDATETIME(),
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );
    DECLARE @Proj2Id INT = SCOPE_IDENTITY();
    INSERT INTO [ProjectSkills] ([ProjectId], [SkillName])
    VALUES (@Proj2Id, N'Flutter'), (@Proj2Id, N'Dart'), (@Proj2Id, N'REST API'), (@Proj2Id, N'State Management');
END;
GO

-- 4. Seed Freelancer Account
-- Email: freelancer@hireflow.com
-- Password: Freelancer@123!
IF NOT EXISTS (SELECT 1 FROM [Users] WHERE [Email] = N'freelancer@hireflow.com')
BEGIN
    INSERT INTO [Users] ([FullName], [Email], [PasswordHash], [Role], [IsActive], [CreatedAt], [UpdatedAt])
    VALUES (
        N'Trần Minh Khôi',
        N'freelancer@hireflow.com',
        N'100000.fipwmHfuEy20hcbepqpPqQ==.B4Tk+1AvqyO62OuIVGuLD6nflM/M6oEBtery6H88MPo=',
        N'Freelancer',
        1,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    DECLARE @FreelancerUserId INT = SCOPE_IDENTITY();
    INSERT INTO [CreditWallets] ([UserId], [Balance], [UpdatedAt])
    VALUES (@FreelancerUserId, 30, SYSUTCDATETIME());

    INSERT INTO [FreelancerProfiles] ([UserId], [Headline], [Bio], [ExperienceYears], [UpdatedAt])
    VALUES (
        @FreelancerUserId,
        N'Fullstack Developer (.NET Core & Flutter)',
        N'Lập trình viên với hơn 4 năm kinh nghiệm xây dựng ứng dụng web API ASP.NET Core hiệu năng cao và ứng dụng di động Flutter đa nền tảng.',
        4,
        SYSUTCDATETIME()
    );

    DECLARE @FreelancerProfileId INT = SCOPE_IDENTITY();
    INSERT INTO [FreelancerSkills] ([FreelancerProfileId], [SkillName])
    VALUES 
        (@FreelancerProfileId, N'C#'),
        (@FreelancerProfileId, N'.NET Core'),
        (@FreelancerProfileId, N'Flutter'),
        (@FreelancerProfileId, N'Dart'),
        (@FreelancerProfileId, N'SQL Server'),
        (@FreelancerProfileId, N'REST API');
END;
GO

PRINT N'========================================================================';
PRINT N'HireFlow Database Schema and Seed Data executed successfully!';
PRINT N'Default Accounts Ready:';
PRINT N'  1. Admin:      admin@hireflow.com      / Admin@HireFlow2026!';
PRINT N'  2. Employer:   employer@hireflow.com   / Employer@123!';
PRINT N'  3. Freelancer: freelancer@hireflow.com / Freelancer@123!';
PRINT N'========================================================================';
GO

