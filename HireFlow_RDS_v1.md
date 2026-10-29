# HireFlow --- Requirements Definition Specification (RDS)

**Document version:** 1.0\
**Status:** MVP draft for AI-assisted implementation\
**Product:** HireFlow\
**Frontend:** Flutter / Dart\
**Backend:** ASP.NET Core Web API / C#\
**Database:** SQL Server with Entity Framework Core\
**Primary language of UI:** Vietnamese (unless configured otherwise)

------------------------------------------------------------------------

## 1. Purpose

This document defines the functional and non-functional requirements for
the HireFlow MVP. It is intended to be read by an AI coding agent as the
authoritative project specification.

The agent must implement only the requirements in this document. Do not
invent additional product features or silently change business rules. If
a decision is not specified, follow the defaults and constraints in this
document, isolate the decision in configuration where practical, and
document any assumption.

## 2. Product overview

HireFlow is a platform that connects freelancers with employers who
publish freelance projects. Users can search projects, apply with a PDF
CV, review application status, and use internal credits for selected
actions.

The system has three roles:

-   **Freelancer:** finds projects, maintains a profile and CVs, applies
    to projects, tracks applications, buys credits, and unlocks employer
    contact details.
-   **Employer:** maintains an employer profile, spends credits to
    publish projects, manages owned projects, reviews applicants and PDF
    CVs, and updates application statuses.
-   **Admin:** manages accounts and projects, handles reports, and
    reviews administrative activity. Admin accounts must not be created
    through public registration.

### 2.1 Technology constraints

-   Frontend: Flutter and Dart.
-   Backend: ASP.NET Core Web API using C#.
-   ORM: Entity Framework Core.
-   Database: Microsoft SQL Server.
-   CV files: private file storage; do not store PDF binary content as
    Base64 in SQL Server.
-   Authentication: secure password hashing and token/session handling
    appropriate for the chosen ASP.NET Core authentication design.
-   All business rules and authorization checks must be enforced by the
    backend, not only by Flutter.
-   Use English identifiers for classes, methods, variables, database
    objects and API routes. User-facing UI text should be Vietnamese by
    default.
-   Keep the MVP modular and easy to revise. Do not add microservices
    unless explicitly requested.

## 3. Roles and authorization

### 3.1 Freelancer permissions

A Freelancer can: - Register, log in, log out, request a password reset,
and change their password. - View and edit their own profile. - Upload
and manage their own PDF CV documents. - Browse and search public
projects. - Apply to an eligible project using a CV document. - View
only their own applications and application statuses. - View their own
credit balance and credit transaction history. - Buy a listed credit
package. - Unlock employer contact information by spending credits. -
View contact information that they have already unlocked, without paying
again for the same unlock scope.

A Freelancer cannot: - View another Freelancer's private CV library. -
View employer-only applicant lists. - Change their role to Employer or
Admin through a normal profile update. - Access another user's private
account data.

### 3.2 Employer permissions

An Employer can: - Register, log in, log out, reset a forgotten
password, and change their password. - View and edit their own employer
profile and contact details. - Publish a project for 5 credits per
successful publication. - View, edit, close, and manage projects they
own. - View applicant counts and applications for their own projects. -
View applicant profile information and the CV attached to an application
for their own project. - Download or preview an authorized applicant's
PDF CV. - Update application status for applicants to their own
projects.

An Employer cannot: - View applications or CVs for projects owned by
another Employer. - Publish a project if their credit balance is below
the required cost. - Change application statuses for projects they do
not own. - Access private CV storage through a public, permanent URL.

### 3.3 Admin permissions

An Admin can: - View and manage user accounts. - Suspend or reactivate
accounts according to system rules. - View, hide, or remove projects
that violate platform rules. - Review reports submitted about users or
projects. - Review credit transactions and relevant audit events when
needed.

Admin registration is disabled. Admin accounts must be provisioned
through a controlled administrative process.

The current scope does not require Admin to edit or read all CV contents
by default. Any such access should be added only if explicitly approved.

## 4. Functional requirements

Requirement IDs are stable references for implementation, testing, and
issue tracking.

### 4.1 Account and authentication

-   **AUTH-001:** The system shall allow a user to register as
    Freelancer or Employer.
-   **AUTH-002:** The system shall allow a registered user to log in and
    log out.
-   **AUTH-003:** The system shall provide a password-reset flow using a
    verified mechanism, such as an email reset link or code.
-   **AUTH-004:** The system shall allow an authenticated user to change
    their password after validating the current password or another
    approved verification step.
-   **AUTH-005:** Passwords shall be securely hashed. Plain-text
    passwords must never be stored or logged.
-   **AUTH-006:** The system shall reject public registration as Admin.
-   **AUTH-007:** Protected backend endpoints shall validate
    authentication and authorization independently of the client UI.
-   **AUTH-008:** Suspended or disabled accounts shall not be allowed to
    perform protected business actions.
-   **AUTH-009:** Authentication errors shall not reveal whether a
    password is correct or expose sensitive account details
    unnecessarily.

### 4.2 Freelancer profile and CV documents

-   **PROFILE-001:** A Freelancer shall be able to view and update their
    own profile.
-   **PROFILE-002:** The profile may contain display name, avatar,
    headline, biography, skills, experience years, and relevant
    professional information.
-   **CV-001:** A Freelancer shall be able to upload a CV in PDF format.
-   **CV-002:** The backend shall validate file content, file size, and
    PDF format. It must not trust the filename extension or
    client-supplied MIME type alone.
-   **CV-003:** The initial maximum CV size shall be configurable;
    default to 5 MB unless the project owner changes it.
-   **CV-004:** A Freelancer shall be able to list, preview, download,
    set a default CV, and delete a CV they own, subject to application
    references.
-   **CV-005:** A CV used by an application shall remain associated with
    that application as the submitted version, even if the Freelancer
    later uploads or selects a different CV.
-   **CV-006:** CV files shall be stored privately. Database records
    shall store metadata and a storage key, not a public permanent file
    URL.
-   **CV-007:** Only the owning Freelancer and an Employer authorized
    through an application to one of that Employer's projects may access
    the relevant CV.
-   **CV-008:** If a CV is referenced by an existing application,
    deleting it from the user's library must not silently break the
    application record. Use a safe retention, archival, or soft-delete
    policy.
-   **CV-009:** The system shall not permit arbitrary filesystem paths
    or storage keys supplied by the client.

### 4.3 Project discovery

-   **PROJECT-001:** Users shall be able to browse public projects.
-   **PROJECT-002:** The system shall support keyword search.
-   **PROJECT-003:** The system shall support filtering by
    compensation/budget, required experience, skills, deadline, and
    project status where applicable.
-   **PROJECT-004:** Project details shall include title, description,
    required skills, budget or compensation range, experience
    requirement, deadline, status, and permitted public employer
    information.
-   **PROJECT-005:** Employer private contact information shall not be
    returned by public project list or detail endpoints unless the
    requester has an active authorization to view it.
-   **PROJECT-006:** Projects that are closed, hidden, or removed shall
    not accept new applications.
-   **PROJECT-007:** The project owner shall be able to view and manage
    only their own projects.

### 4.4 Applications

-   **APP-001:** A Freelancer shall be able to apply to an open project
    using a valid PDF CV.
-   **APP-002:** A Freelancer may optionally include a cover letter or
    application message.
-   **APP-003:** Each successful application shall cost 3 credits.
-   **APP-004:** The backend shall verify that the user is a Freelancer,
    the project is eligible and open, the CV belongs to that Freelancer,
    the CV is valid, the Freelancer has sufficient credits, and no
    application already exists for the same Freelancer and project.
-   **APP-005:** The system shall enforce at most one application per
    Freelancer per project in the MVP.
-   **APP-006:** Credit deduction, application creation, and credit
    transaction recording shall be performed atomically in a database
    transaction.
-   **APP-007:** If application creation fails, the system shall not
    leave the user charged without a corresponding successful
    application.
-   **APP-008:** A Freelancer shall be able to list and view only their
    own applications.
-   **APP-009:** An Employer shall be able to list applications only for
    projects they own.
-   **APP-010:** The system shall show application submission time and
    current status.
-   **APP-011:** The system shall not charge credits merely for viewing
    or downloading an applicant CV.
-   **APP-012:** Duplicate or concurrent application requests shall not
    create duplicate applications or duplicate charges.

### 4.5 Application statuses

The MVP shall support the following statuses:

-   `Pending`: submitted and awaiting review.

-   `Reviewing`: employer is reviewing the application.

-   `Shortlisted`: selected for further consideration.

-   `Accepted`: selected by the employer.

-   `Rejected`: not selected.

-   **APP-STATUS-001:** A new application shall start in `Pending`.

-   **APP-STATUS-002:** Only the Employer who owns the associated
    project may update the application status.

-   **APP-STATUS-003:** A Freelancer shall be able to view the status of
    their own application but shall not set it.

-   **APP-STATUS-004:** Status changes should record the actor and
    timestamp.

-   **APP-STATUS-005:** Status changes shall not charge credits.

-   **APP-STATUS-006:** The application history shall remain available
    after a project closes.

### 4.6 Project publishing and management

-   **PUB-001:** An Employer shall be able to create a project with
    title, description, required skills, budget/compensation range,
    experience requirement, deadline, and status.
-   **PUB-002:** Each successful project publication shall cost 5
    credits.
-   **PUB-003:** Credit deduction and project creation/publication shall
    be atomic. Failed publication shall not charge the Employer.
-   **PUB-004:** The Employer shall be able to view and edit projects
    they own.
-   **PUB-005:** The Employer shall be able to close a project. A closed
    project shall reject new applications while preserving existing
    applications.
-   **PUB-006:** Editing an existing project shall not cost additional
    credits in the MVP.
-   **PUB-007:** Admin shall be able to hide or remove a project
    according to moderation rules.
-   **PUB-008:** Project visibility/approval behavior is not finalized.
    Default MVP assumption: a valid project is published immediately
    unless Admin has hidden or removed it. Keep project status logic
    easy to extend for a future approval workflow.

### 4.7 Employer contact unlock

-   **CONTACT-001:** A Freelancer may unlock the contact details of an
    Employer for 4 credits.
-   **CONTACT-002:** Before charging, the backend shall check whether
    the same contact scope has already been unlocked by that Freelancer.
-   **CONTACT-003:** Re-viewing already unlocked contact details shall
    not charge credits again.
-   **CONTACT-004:** The unlock scope must be explicit and consistent.
    Default MVP scope: unlock the contact details for a specific
    Employer account. If the product owner later chooses per-project
    unlock, update the scope and uniqueness constraint.
-   **CONTACT-005:** The backend shall not expose private contact
    information before authorization.
-   **CONTACT-006:** Credit deduction, unlock record creation, and
    credit transaction recording shall be atomic.
-   **CONTACT-007:** Concurrent unlock requests shall not cause
    duplicate charges.
-   **CONTACT-008:** If the user has insufficient credits, the operation
    shall fail without creating an unlock record or deducting credits.

### 4.8 Credits and transaction history

-   **CREDIT-001:** The system shall maintain a credit balance for each
    eligible user.
-   **CREDIT-002:** The UI shall show the current balance.
-   **CREDIT-003:** The system shall record every credit addition and
    deduction.
-   **CREDIT-004:** Transaction records shall include user, amount,
    transaction type, reason/reference, timestamp, and status where
    applicable.
-   **CREDIT-005:** Credit balances must not become negative due to
    concurrent requests.
-   **CREDIT-006:** Credit spending and its related business operation
    shall be atomic.
-   **CREDIT-007:** The UI shall show the user's transaction history.
-   **CREDIT-008:** Admin may review transactions for administrative
    support and audit purposes.
-   **CREDIT-009:** The backend shall be the authoritative source for
    credit balance and spending decisions; the client must never
    determine or submit the authoritative balance.

### 4.9 Credit packages and purchases

-   **BUY-001:** The system shall display available credit packages with
    listed price and credit quantity.
-   **BUY-002:** Package prices and quantities shall be
    stored/configured on the backend, not hard-coded as trusted values
    in Flutter.
-   **BUY-003:** A user shall be able to select a package and initiate a
    purchase.
-   **BUY-004:** The system shall create a purchase/payment record in a
    pending state before payment confirmation.
-   **BUY-005:** Credits shall be added only after the backend verifies
    successful payment through a trusted provider callback/webhook or
    equivalent verified process.
-   **BUY-006:** A failed, cancelled, or unverified payment shall not
    add credits.
-   **BUY-007:** Payment callbacks shall be idempotent; processing the
    same successful payment event more than once shall not add credits
    more than once.
-   **BUY-008:** The system shall record package, price, credits,
    payment reference, status, and timestamps.
-   **BUY-009:** The exact credit package prices and payment provider
    are not yet specified. Implement a provider abstraction or a clearly
    isolated payment integration; do not invent real package prices or
    claim a real payment integration is configured.
-   **BUY-010:** If no payment provider is configured in development,
    provide a development-only simulated payment flow clearly marked as
    non-production. Never expose an unrestricted fake-payment endpoint
    in production.

### 4.10 Admin and reports

-   **ADMIN-001:** Admin shall be able to list and inspect user
    accounts.
-   **ADMIN-002:** Admin shall be able to suspend/reactivate users
    according to defined rules.
-   **ADMIN-003:** Admin shall be able to list projects and hide/remove
    violating projects.
-   **ADMIN-004:** The system shall provide a basic report-submission
    workflow for users to report suspicious accounts, projects, or
    inappropriate behavior.
-   **ADMIN-005:** Admin shall be able to review and update report
    status.
-   **ADMIN-006:** Important administrative actions shall be recorded in
    an audit log.
-   **ADMIN-007:** Do not add advanced analytics or a complex moderation
    workflow unless explicitly requested.

## 5. Credit pricing rules

  ------------------------------------------------------------------------
  Action                                        Cost Charging rule
  --------------------- ---------------------------- ---------------------
  Browse/search                            0 credits Free
  projects                                           

  View public project                      0 credits Free
  details                                            

  Submit an application                    3 credits Deduct once per
  successfully                                       successful
                                                     application

  Unlock employer                          4 credits Deduct once per
  contact details                                    defined unlock scope

  Publish a project                        5 credits Deduct once per
  successfully                                       successful
                                                     publication

  View/download own CV                     0 credits Free

  Employer                                 0 credits Free
  views/downloads                                    
  applicant CV for an                                
  owned project                                      

  Edit an existing                         0 credits MVP default; no
  project                                            additional charge
  ------------------------------------------------------------------------

All credit costs must be represented in one backend
business-rule/configuration location rather than duplicated as unrelated
constants across controllers and Flutter screens.

## 6. Suggested data model

The AI agent must review and refine this model before generating
migrations. Use proper primary keys, foreign keys, indexes, unique
constraints, timestamps, and appropriate delete behavior.

### 6.1 Core entities

**Users** - `UserId` (PK) - `FullName` - `Email` (unique, normalized) -
`PasswordHash` (or ASP.NET Core Identity-managed fields) - `Role`
(Freelancer, Employer, Admin) - `IsActive` - `CreatedAt` - `UpdatedAt`

Prefer ASP.NET Core Identity if compatible with the project structure.
Do not create a custom weak password-storage scheme.

**FreelancerProfiles** - `ProfileId` (PK) - `UserId` (FK to Users,
unique) - `AvatarStorageKey` (nullable) - `Headline` (nullable) - `Bio`
(nullable) - `ExperienceYears` (nullable) - `UpdatedAt`

**FreelancerSkills** - `FreelancerSkillId` (PK) - `FreelancerId` (FK) -
`SkillName`

Use a separate skills table rather than a comma-separated string if
skills will be searched or filtered.

**EmployerProfiles** - `EmployerProfileId` (PK) - `UserId` (FK to Users,
unique) - `CompanyName` (nullable) - `Description` (nullable) -
`PublicDisplayName` (nullable) - `ContactEmail` (private by default) -
`ContactPhone` (private by default) - `UpdatedAt`

**Projects** - `ProjectId` (PK) - `EmployerId` (FK to Users) - `Title` -
`Description` - `BudgetMin` (nullable if fixed salary/rate model is
later selected) - `BudgetMax` (nullable) - `CurrencyCode` -
`ExperienceLevel` (nullable) - `Deadline` (nullable) - `Status` (Open,
Closed, Hidden, Removed) - `CreatedAt` - `UpdatedAt` - `PublishedAt`
(nullable)

**ProjectSkills** - `ProjectSkillId` (PK) - `ProjectId` (FK) -
`SkillName`

**FreelancerDocuments** - `DocumentId` (PK) - `FreelancerId` (FK to
Users) - `OriginalFileName` - `StorageKey` - `ContentType` -
`FileSize` - `ContentHash` (optional) - `IsDefault` - `UploadedAt` -
`IsDeleted` or archival metadata as needed

**Applications** - `ApplicationId` (PK) - `ProjectId` (FK) -
`FreelancerId` (FK to Users) - `DocumentId` (FK to
FreelancerDocuments) - `CoverLetter` (nullable) - `Status` (Pending,
Reviewing, Shortlisted, Accepted, Rejected) - `AppliedAt` - `UpdatedAt`

Add a unique constraint on `(ProjectId, FreelancerId)`.

**ApplicationStatusHistories** - `HistoryId` (PK) - `ApplicationId`
(FK) - `OldStatus` (nullable) - `NewStatus` - `ChangedByUserId` (FK to
Users) - `ChangedAt`

**CreditWallets** - `WalletId` (PK) - `UserId` (FK, unique) - `Balance`
(integer, non-negative) - `UpdatedAt` - Add a concurrency strategy or
locking approach to prevent lost updates and negative balances.

**CreditTransactions** - `TransactionId` (PK) - `UserId` (FK) - `Amount`
(signed integer or separate direction/type with positive amount; choose
one convention consistently) - `TransactionType` (ApplicationFee,
ContactUnlock, ProjectPublish, CreditPurchase, AdminAdjustment, Refund
if added later) - `ReferenceType` - `ReferenceId` (nullable) -
`Description` - `IdempotencyKey` (nullable but unique when supplied) -
`CreatedAt`

**ContactUnlocks** - `ContactUnlockId` (PK) - `FreelancerId` (FK to
Users) - `EmployerId` (FK to Users) - `ProjectId` (nullable; use only if
the product later chooses per-project unlock) - `UnlockedAt`

For default employer-level unlock scope, add a unique constraint on
`(FreelancerId, EmployerId)`. If per-project scope is selected later,
replace it with the correct uniqueness constraint. Do not implement both
scopes accidentally.

**CreditPackages** - `CreditPackageId` (PK) - `Name` - `CreditAmount` -
`PriceAmount` - `CurrencyCode` - `IsActive` - `DisplayOrder`

**CreditPurchases** - `CreditPurchaseId` (PK) - `UserId` (FK) -
`CreditPackageId` (FK or package snapshot fields) - `CreditsPurchased` -
`PriceAmount` - `CurrencyCode` - `PaymentProvider` - `ProviderReference`
(unique when present) - `Status` (Pending, Paid, Failed, Cancelled) -
`CreatedAt` - `PaidAt` (nullable)

Store a snapshot of the package's price and credit amount in the
purchase so later package changes do not rewrite past purchases.

**Reports** - `ReportId` (PK) - `ReporterUserId` (FK) - `TargetType`
(User, Project, Other) - `TargetId` - `Reason` - `Description`
(nullable) - `Status` (Pending, Reviewing, Resolved, Rejected) -
`CreatedAt` - `ResolvedAt` (nullable) - `ResolvedByUserId` (nullable FK)

**AuditLogs** - `AuditLogId` (PK) - `ActorUserId` (nullable FK) -
`Action` - `EntityType` - `EntityId` (nullable) - `Details` (avoid
secrets and sensitive CV contents) - `CreatedAt`

### 6.2 Storage rule

CV file bytes must be stored in private file storage. SQL Server stores
the file metadata and a server-generated `StorageKey`. All CV retrieval
must pass through an authorization check. Do not expose the physical
path or allow a client to choose a path.

## 7. API design baseline

Use REST-style routes and DTOs. Exact routes can be adjusted to match
the existing repository, but equivalent operations and authorization
must exist.

### Authentication

-   `POST /api/auth/register`
-   `POST /api/auth/login`
-   `POST /api/auth/logout` if server-side session/revocation is
    implemented
-   `POST /api/auth/forgot-password`
-   `POST /api/auth/reset-password`
-   `POST /api/auth/change-password`
-   `GET /api/auth/me`

### Profiles and documents

-   `GET /api/freelancer/profile`
-   `PUT /api/freelancer/profile`
-   `GET /api/employer/profile`
-   `PUT /api/employer/profile`
-   `POST /api/documents/cv`
-   `GET /api/documents/my-cvs`
-   `GET /api/documents/{documentId}`
-   `PUT /api/documents/{documentId}/default`
-   `DELETE /api/documents/{documentId}`

### Projects

-   `GET /api/projects`
-   `GET /api/projects/{projectId}`
-   `POST /api/projects` (Employer; 5 credits)
-   `PUT /api/projects/{projectId}` (owner only)
-   `POST /api/projects/{projectId}/close` (owner only)
-   `GET /api/employer/projects`

### Applications

-   `POST /api/projects/{projectId}/applications` (Freelancer; 3
    credits)
-   `GET /api/applications/my` (Freelancer)
-   `GET /api/applications/{applicationId}` (authorized Freelancer or
    owning Employer)
-   `GET /api/projects/{projectId}/applications` (owning Employer)
-   `GET /api/applications/{applicationId}/cv` (authorized access only)
-   `PATCH /api/applications/{applicationId}/status` (owning Employer)

### Credits and purchases

-   `GET /api/credits/balance`
-   `GET /api/credits/transactions`
-   `GET /api/credits/packages`
-   `POST /api/credits/purchases`
-   `GET /api/credits/purchases/{purchaseId}`
-   `POST /api/projects/{projectId}/contact-unlock` (Freelancer; 4
    credits)
-   `GET /api/projects/{projectId}/employer-contact` (authorized after
    unlock)
-   `GET /api/employers/{employerId}/contact` only if the authorization
    model is explicitly implemented and checked

### Admin

-   `GET /api/admin/users`
-   `PATCH /api/admin/users/{userId}/status`
-   `GET /api/admin/projects`
-   `PATCH /api/admin/projects/{projectId}/moderation`
-   `GET /api/admin/reports`
-   `PATCH /api/admin/reports/{reportId}`
-   `GET /api/admin/credit-transactions`
-   `GET /api/admin/audit-logs`

For list endpoints, implement pagination and validated filtering. Use
DTOs; do not return EF Core entities directly.

## 8. Transactional business rules

These rules are mandatory.

### 8.1 Application charge

Within a safe transaction: 1. Verify the user is an active Freelancer.
2. Verify the project exists and is Open. 3. Verify the selected CV
belongs to the Freelancer and is valid. 4. Verify there is no existing
application for `(ProjectId, FreelancerId)`. 5. Verify the balance is at
least 3 credits. 6. Deduct 3 credits using a concurrency-safe operation.
7. Create the application. 8. Create a credit transaction referencing
the application. 9. Commit all changes together.

If any step fails, roll back the transaction. Use a database unique
constraint as a final defense against concurrent duplicate applications.

### 8.2 Project publication charge

Within a safe transaction: 1. Verify the user is an active Employer. 2.
Validate project fields. 3. Verify the balance is at least 5 credits. 4.
Create and publish the project. 5. Deduct 5 credits and record a
transaction referencing the project. 6. Commit together.

If the project is not successfully created/published, do not charge.

### 8.3 Contact unlock charge

Within a safe transaction: 1. Verify the user is an active Freelancer.
2. Verify the target Employer exists and is active. 3. Check whether the
Freelancer has already unlocked the configured contact scope. 4. If
already unlocked, return authorized contact information without charging
again. 5. Verify balance is at least 4 credits. 6. Deduct 4 credits. 7.
Create the unlock record and credit transaction. 8. Commit and return
only the allowed contact fields.

Add database constraints and concurrency-safe handling so two
simultaneous requests cannot charge twice for the same unlock.

### 8.4 Purchase confirmation

1.  Create a pending purchase using package details read from the
    backend.
2.  Never trust the client to provide the credit quantity or price as
    authoritative values.
3.  Verify the payment with the provider's authenticated
    callback/webhook or equivalent server-side verification.
4.  Mark the purchase Paid and add credits in one transaction.
5.  Enforce idempotency using a unique provider event/reference and/or
    unique credit transaction reference.
6.  A repeated callback must not add credits twice.

## 9. Non-functional requirements

-   **SEC-001:** Enforce server-side role and ownership authorization on
    every protected endpoint.
-   **SEC-002:** Never store plain-text passwords, payment secrets,
    access tokens, or private CV URLs in logs.
-   **SEC-003:** Validate and normalize all user input on the backend.
-   **SEC-004:** Use parameterized database access through EF Core; do
    not concatenate user input into SQL.
-   **SEC-005:** Protect against IDOR by checking resource ownership,
    not merely authentication.
-   **SEC-006:** Use HTTPS in deployed environments.
-   **SEC-007:** Store secrets in environment variables or a secrets
    manager, not in source control.
-   **SEC-008:** Handle file upload errors, database failures, and
    payment failures without leaving partial business state.
-   **SEC-009:** Implement pagination for potentially large lists.
-   **SEC-010:** Provide clear Vietnamese error messages in the UI
    without leaking stack traces.
-   **SEC-011:** Add structured logging and useful error responses.
    Never expose internal exception details to clients in production.
-   **SEC-012:** Add tests for credit deductions, role authorization,
    ownership, duplicate applications, CV access, and payment
    idempotency.
-   **SEC-013:** Database schema changes must be implemented through EF
    Core migrations.
-   **SEC-014:** Do not commit real payment credentials, production
    connection strings, or secrets.
-   **SEC-015:** UI state must not be treated as proof of authorization
    or payment success.

## 10. Error handling expectations

Use appropriate HTTP status codes: - `400 Bad Request`: invalid input or
invalid business state. - `401 Unauthorized`: unauthenticated request. -
`403 Forbidden`: authenticated but lacks permission. - `404 Not Found`:
resource does not exist or should not be disclosed to the requester. -
`409 Conflict`: duplicate application, duplicate operation, or
conflicting state. - `422 Unprocessable Entity`: optionally use for
domain validation if consistently applied. -
`500 Internal Server Error`: unexpected server error, with details
logged server-side only.

Return a consistent API error shape, for example:

``` json
{
  "code": "INSUFFICIENT_CREDITS",
  "message": "Bạn không đủ credit để thực hiện thao tác này."
}
```

Do not expose whether a private resource exists when doing so would
create an authorization leak.

## 11. Minimum acceptance criteria

The MVP is not complete until all the following are true:

1.  Freelancer and Employer can register and log in; Admin cannot
    register publicly.
2.  Forgot-password and change-password flows work using a configured
    verification mechanism.
3.  Freelancer can create/update their profile and upload a valid PDF
    CV.
4.  Invalid file types and oversized CVs are rejected.
5.  Freelancer can search and view public projects.
6.  Employer can publish a project only when they have at least 5
    credits; successful publication charges exactly 5 credits.
7.  Freelancer can apply only to an open project using their own CV;
    successful application charges exactly 3 credits.
8.  A Freelancer cannot apply to the same project twice, including
    through concurrent requests.
9.  Failed application or publication does not leave a credit deduction
    behind.
10. Employer can view the applicant list only for projects they own.
11. Employer can preview/download CVs attached to applications for their
    own projects.
12. A Freelancer cannot view another Freelancer's CV.
13. Employer can update applicant status; Freelancer can only view it.
14. Contact unlock costs 4 credits once per configured unlock scope;
    revisiting an unlocked contact does not charge again.
15. Public project responses do not leak private employer contact
    details.
16. Credit balance and transaction history remain consistent after
    concurrent operations.
17. The system lists credit packages and only adds credit after verified
    payment success.
18. Repeated payment notifications do not add duplicate credit.
19. Admin can manage accounts/projects and review reports.
20. Critical authorization and credit rules have automated tests.

## 12. Implementation guidance for the AI coding agent

Before coding: 1. Inspect the existing repository and identify the
current Flutter, ASP.NET Core, EF Core, SQL Server, authentication, and
file-storage setup. 2. Preserve working code and conventions where
possible. Do not overwrite the repository with a new template without
need. 3. Report the existing architecture, missing requirements, and any
conflicts with this document. 4. Create a phased implementation plan and
identify unresolved decisions.

Implementation order: 1. Solution structure, configuration, database
connection, EF Core migrations, and shared error handling. 2.
Authentication, roles, account state, and profile APIs. 3. Credit wallet
and transaction infrastructure with tests. 4. Project CRUD,
search/filter, and 5-credit publication. 5. Private PDF upload/storage
and document management. 6. Application workflow with 3-credit charge
and concurrency protection. 7. Employer applicant management, secure CV
preview/download, and status updates. 8. Contact unlock with 4-credit
charge. 9. Credit packages and payment integration or development-only
simulation. 10. Admin moderation, reports, audit logging, UI
integration, and end-to-end tests.

For each phase: - Implement backend rules first, then Flutter screens. -
Add or update EF Core migrations. - Add tests for business rules and
authorization. - Build and run the relevant projects. - Fix build/test
failures before moving on. - Summarize files changed, endpoints added,
migrations created, tests run, and known gaps. - Do not claim a feature
works unless it has been built and tested.

## 13. Open decisions and explicit defaults

The following decisions are not fully specified yet. Do not invent final
business values.

1.  **Credit package prices and quantities:** not provided. Store
    packages as backend-managed data and seed clearly labeled
    development examples only if needed.
2.  **Payment provider:** not selected. Keep integration isolated. Do
    not claim real payment support before provider configuration and
    verification are implemented.
3.  **Contact unlock scope:** default to one unlock per
    Freelancer--Employer pair. If product owner intends one unlock per
    project, change the model and constraints explicitly.
4.  **Project approval:** default to immediate publication after
    successful validation; Admin can later hide/remove a project.
5.  **Salary versus project budget:** the requirements mention salary
    and budget. Model a flexible compensation range and currency so the
    UI can distinguish fixed salary from project budget if required.
6.  **CV storage provider:** use a private local storage adapter for
    development if necessary, and make it replaceable with private cloud
    storage for deployment.
7.  **Email service:** password reset requires a configured
    email/verification service. Use a development-only mock or console
    adapter only in local development; do not claim production email
    delivery without configuration.
8.  **Application withdrawal/editing:** not specified. Do not add
    withdrawal or re-application functionality in the MVP unless
    approved.
9.  **Refund policy:** not specified. Do not automatically refund credit
    for rejected applications, closed projects, or removed projects
    unless a refund rule is approved.
10. **Employer registration verification:** not specified. Do not add
    mandatory business-document verification unless approved.

## 14. Definition of done

A requirement is done only when: - Backend behavior is implemented. -
Authorization and validation are enforced server-side. - Database schema
and migrations are updated if needed. - Flutter UI is connected to the
real API (unless clearly marked as a development mock). - Success and
error states are handled. - Automated tests cover the critical business
rules. - The feature builds and relevant tests pass. - Documentation is
updated to reflect actual behavior.

**End of specification.**
