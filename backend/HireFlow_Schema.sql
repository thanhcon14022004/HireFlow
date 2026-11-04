IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

CREATE TABLE [CreditPackages] (
    [CreditPackageId] int NOT NULL IDENTITY,
    [Name] nvarchar(max) NOT NULL,
    [CreditAmount] int NOT NULL,
    [PriceAmount] decimal(18,2) NOT NULL,
    [CurrencyCode] nvarchar(max) NOT NULL,
    [IsActive] bit NOT NULL,
    [DisplayOrder] int NOT NULL,
    CONSTRAINT [PK_CreditPackages] PRIMARY KEY ([CreditPackageId])
);
GO

CREATE TABLE [Users] (
    [UserId] int NOT NULL IDENTITY,
    [FullName] nvarchar(150) NOT NULL,
    [Email] nvarchar(256) NOT NULL,
    [PasswordHash] nvarchar(max) NOT NULL,
    [Role] nvarchar(50) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY ([UserId])
);
GO

CREATE TABLE [AuditLogs] (
    [AuditLogId] int NOT NULL IDENTITY,
    [ActorUserId] int NULL,
    [Action] nvarchar(max) NOT NULL,
    [EntityType] nvarchar(max) NOT NULL,
    [EntityId] nvarchar(max) NULL,
    [Details] nvarchar(max) NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_AuditLogs] PRIMARY KEY ([AuditLogId]),
    CONSTRAINT [FK_AuditLogs_Users_ActorUserId] FOREIGN KEY ([ActorUserId]) REFERENCES [Users] ([UserId]) ON DELETE SET NULL
);
GO

CREATE TABLE [ContactUnlocks] (
    [ContactUnlockId] int NOT NULL IDENTITY,
    [FreelancerId] int NOT NULL,
    [EmployerId] int NOT NULL,
    [ProjectId] int NULL,
    [UnlockedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_ContactUnlocks] PRIMARY KEY ([ContactUnlockId]),
    CONSTRAINT [FK_ContactUnlocks_Users_EmployerId] FOREIGN KEY ([EmployerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_ContactUnlocks_Users_FreelancerId] FOREIGN KEY ([FreelancerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
);
GO

CREATE TABLE [CreditPurchases] (
    [CreditPurchaseId] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [CreditPackageId] int NOT NULL,
    [CreditsPurchased] int NOT NULL,
    [PriceAmount] decimal(18,2) NOT NULL,
    [CurrencyCode] nvarchar(max) NOT NULL,
    [PaymentProvider] nvarchar(max) NOT NULL,
    [ProviderReference] nvarchar(450) NULL,
    [Status] nvarchar(max) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [PaidAt] datetime2 NULL,
    CONSTRAINT [PK_CreditPurchases] PRIMARY KEY ([CreditPurchaseId]),
    CONSTRAINT [FK_CreditPurchases_CreditPackages_CreditPackageId] FOREIGN KEY ([CreditPackageId]) REFERENCES [CreditPackages] ([CreditPackageId]) ON DELETE CASCADE,
    CONSTRAINT [FK_CreditPurchases_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
);
GO

CREATE TABLE [CreditTransactions] (
    [TransactionId] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [Amount] int NOT NULL,
    [TransactionType] nvarchar(max) NOT NULL,
    [ReferenceType] nvarchar(max) NOT NULL,
    [ReferenceId] nvarchar(max) NULL,
    [Description] nvarchar(max) NOT NULL,
    [IdempotencyKey] nvarchar(450) NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_CreditTransactions] PRIMARY KEY ([TransactionId]),
    CONSTRAINT [FK_CreditTransactions_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
);
GO

CREATE TABLE [CreditWallets] (
    [WalletId] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [Balance] int NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    [RowVersion] rowversion NULL,
    CONSTRAINT [PK_CreditWallets] PRIMARY KEY ([WalletId]),
    CONSTRAINT [FK_CreditWallets_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
);
GO

CREATE TABLE [EmployerProfiles] (
    [EmployerProfileId] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [CompanyName] nvarchar(max) NULL,
    [Description] nvarchar(max) NULL,
    [PublicDisplayName] nvarchar(max) NULL,
    [ContactEmail] nvarchar(max) NULL,
    [ContactPhone] nvarchar(max) NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_EmployerProfiles] PRIMARY KEY ([EmployerProfileId]),
    CONSTRAINT [FK_EmployerProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
);
GO

CREATE TABLE [FreelancerDocuments] (
    [DocumentId] int NOT NULL IDENTITY,
    [FreelancerId] int NOT NULL,
    [OriginalFileName] nvarchar(255) NOT NULL,
    [StorageKey] nvarchar(255) NOT NULL,
    [ContentType] nvarchar(max) NOT NULL,
    [FileSize] bigint NOT NULL,
    [ContentHash] nvarchar(max) NULL,
    [IsDefault] bit NOT NULL,
    [UploadedAt] datetime2 NOT NULL,
    [IsDeleted] bit NOT NULL,
    CONSTRAINT [PK_FreelancerDocuments] PRIMARY KEY ([DocumentId]),
    CONSTRAINT [FK_FreelancerDocuments_Users_FreelancerId] FOREIGN KEY ([FreelancerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
);
GO

CREATE TABLE [FreelancerProfiles] (
    [ProfileId] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [AvatarStorageKey] nvarchar(max) NULL,
    [Headline] nvarchar(max) NULL,
    [Bio] nvarchar(max) NULL,
    [ExperienceYears] int NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_FreelancerProfiles] PRIMARY KEY ([ProfileId]),
    CONSTRAINT [FK_FreelancerProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
);
GO

CREATE TABLE [PasswordResetTokens] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [TokenHash] nvarchar(max) NOT NULL,
    [Code] nvarchar(max) NOT NULL,
    [ExpiresAt] datetime2 NOT NULL,
    [IsUsed] bit NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_PasswordResetTokens] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PasswordResetTokens_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([UserId]) ON DELETE CASCADE
);
GO

CREATE TABLE [Projects] (
    [ProjectId] int NOT NULL IDENTITY,
    [EmployerId] int NOT NULL,
    [Title] nvarchar(250) NOT NULL,
    [Description] nvarchar(max) NOT NULL,
    [BudgetMin] decimal(18,2) NULL,
    [BudgetMax] decimal(18,2) NULL,
    [CurrencyCode] nvarchar(max) NOT NULL,
    [ExperienceLevel] nvarchar(max) NULL,
    [Deadline] datetime2 NULL,
    [Status] nvarchar(max) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    [PublishedAt] datetime2 NULL,
    CONSTRAINT [PK_Projects] PRIMARY KEY ([ProjectId]),
    CONSTRAINT [FK_Projects_Users_EmployerId] FOREIGN KEY ([EmployerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
);
GO

CREATE TABLE [Reports] (
    [ReportId] int NOT NULL IDENTITY,
    [ReporterUserId] int NOT NULL,
    [TargetType] nvarchar(max) NOT NULL,
    [TargetId] int NOT NULL,
    [Reason] nvarchar(max) NOT NULL,
    [Description] nvarchar(max) NULL,
    [Status] nvarchar(max) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [ResolvedAt] datetime2 NULL,
    [ResolvedByUserId] int NULL,
    CONSTRAINT [PK_Reports] PRIMARY KEY ([ReportId]),
    CONSTRAINT [FK_Reports_Users_ReporterUserId] FOREIGN KEY ([ReporterUserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Reports_Users_ResolvedByUserId] FOREIGN KEY ([ResolvedByUserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
);
GO

CREATE TABLE [FreelancerSkills] (
    [FreelancerSkillId] int NOT NULL IDENTITY,
    [FreelancerProfileId] int NOT NULL,
    [SkillName] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_FreelancerSkills] PRIMARY KEY ([FreelancerSkillId]),
    CONSTRAINT [FK_FreelancerSkills_FreelancerProfiles_FreelancerProfileId] FOREIGN KEY ([FreelancerProfileId]) REFERENCES [FreelancerProfiles] ([ProfileId]) ON DELETE CASCADE
);
GO

CREATE TABLE [Applications] (
    [ApplicationId] int NOT NULL IDENTITY,
    [ProjectId] int NOT NULL,
    [FreelancerId] int NOT NULL,
    [DocumentId] int NOT NULL,
    [CoverLetter] nvarchar(max) NULL,
    [Status] nvarchar(max) NOT NULL,
    [AppliedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Applications] PRIMARY KEY ([ApplicationId]),
    CONSTRAINT [FK_Applications_FreelancerDocuments_DocumentId] FOREIGN KEY ([DocumentId]) REFERENCES [FreelancerDocuments] ([DocumentId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Applications_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([ProjectId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Applications_Users_FreelancerId] FOREIGN KEY ([FreelancerId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
);
GO

CREATE TABLE [ProjectSkills] (
    [ProjectSkillId] int NOT NULL IDENTITY,
    [ProjectId] int NOT NULL,
    [SkillName] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_ProjectSkills] PRIMARY KEY ([ProjectSkillId]),
    CONSTRAINT [FK_ProjectSkills_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([ProjectId]) ON DELETE CASCADE
);
GO

CREATE TABLE [ApplicationStatusHistories] (
    [HistoryId] int NOT NULL IDENTITY,
    [ApplicationId] int NOT NULL,
    [OldStatus] nvarchar(max) NULL,
    [NewStatus] nvarchar(max) NOT NULL,
    [ChangedByUserId] int NOT NULL,
    [ChangedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_ApplicationStatusHistories] PRIMARY KEY ([HistoryId]),
    CONSTRAINT [FK_ApplicationStatusHistories_Applications_ApplicationId] FOREIGN KEY ([ApplicationId]) REFERENCES [Applications] ([ApplicationId]) ON DELETE CASCADE,
    CONSTRAINT [FK_ApplicationStatusHistories_Users_ChangedByUserId] FOREIGN KEY ([ChangedByUserId]) REFERENCES [Users] ([UserId]) ON DELETE NO ACTION
);
GO

CREATE INDEX [IX_Applications_DocumentId] ON [Applications] ([DocumentId]);
GO

CREATE INDEX [IX_Applications_FreelancerId] ON [Applications] ([FreelancerId]);
GO

CREATE UNIQUE INDEX [IX_Applications_ProjectId_FreelancerId] ON [Applications] ([ProjectId], [FreelancerId]);
GO

CREATE INDEX [IX_ApplicationStatusHistories_ApplicationId] ON [ApplicationStatusHistories] ([ApplicationId]);
GO

CREATE INDEX [IX_ApplicationStatusHistories_ChangedByUserId] ON [ApplicationStatusHistories] ([ChangedByUserId]);
GO

CREATE INDEX [IX_AuditLogs_ActorUserId] ON [AuditLogs] ([ActorUserId]);
GO

CREATE INDEX [IX_ContactUnlocks_EmployerId] ON [ContactUnlocks] ([EmployerId]);
GO

CREATE UNIQUE INDEX [IX_ContactUnlocks_FreelancerId_EmployerId] ON [ContactUnlocks] ([FreelancerId], [EmployerId]);
GO

CREATE INDEX [IX_CreditPurchases_CreditPackageId] ON [CreditPurchases] ([CreditPackageId]);
GO

CREATE UNIQUE INDEX [IX_CreditPurchases_ProviderReference] ON [CreditPurchases] ([ProviderReference]) WHERE [ProviderReference] IS NOT NULL;
GO

CREATE INDEX [IX_CreditPurchases_UserId] ON [CreditPurchases] ([UserId]);
GO

CREATE UNIQUE INDEX [IX_CreditTransactions_IdempotencyKey] ON [CreditTransactions] ([IdempotencyKey]) WHERE [IdempotencyKey] IS NOT NULL;
GO

CREATE INDEX [IX_CreditTransactions_UserId] ON [CreditTransactions] ([UserId]);
GO

CREATE UNIQUE INDEX [IX_CreditWallets_UserId] ON [CreditWallets] ([UserId]);
GO

CREATE UNIQUE INDEX [IX_EmployerProfiles_UserId] ON [EmployerProfiles] ([UserId]);
GO

CREATE INDEX [IX_FreelancerDocuments_FreelancerId] ON [FreelancerDocuments] ([FreelancerId]);
GO

CREATE UNIQUE INDEX [IX_FreelancerProfiles_UserId] ON [FreelancerProfiles] ([UserId]);
GO

CREATE INDEX [IX_FreelancerSkills_FreelancerProfileId] ON [FreelancerSkills] ([FreelancerProfileId]);
GO

CREATE INDEX [IX_PasswordResetTokens_UserId] ON [PasswordResetTokens] ([UserId]);
GO

CREATE INDEX [IX_Projects_EmployerId] ON [Projects] ([EmployerId]);
GO

CREATE INDEX [IX_ProjectSkills_ProjectId] ON [ProjectSkills] ([ProjectId]);
GO

CREATE INDEX [IX_Reports_ReporterUserId] ON [Reports] ([ReporterUserId]);
GO

CREATE INDEX [IX_Reports_ResolvedByUserId] ON [Reports] ([ResolvedByUserId]);
GO

CREATE UNIQUE INDEX [IX_Users_Email] ON [Users] ([Email]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20261029205450_InitialCreate', N'8.0.12');
GO

COMMIT;
GO

