# HireFlow Implementation Status

This status document tracks progress against the requirements specified in `HireFlow_RDS_v1.md`.

## Legend
- [x] Completed and verified
- [/] In Progress
- [ ] Not Started / Blocked

---

## 1. Foundation & Architecture
- [x] Solution & project initialization (.NET 8 Web API & Flutter 3.47)
- [x] Architectural decisions document (`docs/DECISIONS.md`)
- [x] Test report document (`docs/TEST_REPORT.md`)
- [x] Environment configuration template (`.env.example` & `appsettings.json`)
- [x] EF Core DbContext with SQL Server & In-Memory configuration
- [x] Database schema definitions, constraints, indexes & EF Core Migrations (`InitialCreate`)
- [x] Centralized exception handling middleware & consistent error envelope (`code`, `message`)
- [x] Authentication & JWT token infrastructure with PBKDF2 salted password hashing

---

## 2. Authentication & Accounts (AUTH-001 ~ AUTH-009)
- [x] User registration for Freelancer and Employer (`/api/auth/register`)
- [x] Public Admin registration disabled and rejected with 403 Forbidden (`AUTH-006`)
- [x] Login with JWT token issuance, claims, and role assignment (`/api/auth/login`)
- [x] Current user profile and wallet balance retrieval (`/api/auth/me`)
- [x] Password reset request emitting 6-digit OTP code (`/api/auth/forgot-password`)
- [x] Password reset completion with token/code verification (`/api/auth/reset-password`)
- [x] Authenticated password change with current password check (`/api/auth/change-password`)
- [x] Suspended user enforcement (inactive users blocked with 403 Forbidden)
- [x] User profiles management (`/api/freelancer/profile`, `/api/employer/profile`)

---

## 3. Documents & Private CV Storage (CV-001 ~ CV-009)
- [x] Private file storage abstraction & local storage provider (`storage/cvs`)
- [x] File validation: magic bytes `%PDF` (0x25, 0x50, 0x44, 0x46), extension `.pdf`, size <= 5 MB
- [x] Upload CV endpoint with SHA256 hash generation (`/api/documents/cv`)
- [x] List my CVs, set default CV, delete CV (`/api/documents/my-cvs`, `/api/documents/{id}`)
- [x] Soft-delete retention policy for CVs referenced in applications (`CV-008`)
- [x] Authorization-controlled CV download / preview (Owner & authorized Employer only)

---

## 4. Projects (PROJECT-001 ~ PROJECT-007, PUB-001 ~ PUB-008)
- [x] Public project browsing & search with multi-criteria filtering (keyword, skills, budget, exp)
- [x] Public project detail endpoint masking private employer contact details until unlocked
- [x] Employer create/publish project with atomic 5-credit deduction (`PUB-002`)
- [x] Employer edit owned project (0 credits in MVP)
- [x] Employer close owned project (rejects new applications, preserves existing records)
- [x] Employer view owned projects with applicant counts
- [x] Admin moderation (hide / remove violating projects)

---

## 5. Applications & Workflow (APP-001 ~ APP-012, APP-STATUS-001 ~ APP-STATUS-006)
- [x] Freelancer apply to project with valid PDF CV & optional cover letter
- [x] Atomic 3-credit deduction on application submission (`APP-003`, `APP-006`)
- [x] Strict one-application-per-project enforcement (`UNIQUE(ProjectId, FreelancerId)`)
- [x] Freelancer view own applications & status history (`/api/applications/my`)
- [x] Employer view applicants for owned projects (`/api/projects/{id}/applications`)
- [x] Employer update application status (`Pending` -> `Reviewing` -> `Shortlisted` -> `Accepted` / `Rejected`)
- [x] Status change history logging with actor & timestamp in `ApplicationStatusHistory`

---

## 6. Credits & Contact Unlock (CREDIT-001 ~ CREDIT-009, CONTACT-001 ~ CONTACT-008)
- [x] Credit wallet & transaction history recording (`CreditWallets`, `CreditTransactions`)
- [x] Concurrency-safe, atomic credit deduction preventing negative balances
- [x] Contact unlock endpoint with 4-credit charge and employer-level scope (`UNIQUE(FreelancerId, EmployerId)`)
- [x] Free re-access for already unlocked contacts (0 credits, idempotent) (`CONTACT-003`)
- [x] Private contact details endpoint after unlock verification (`/api/projects/{id}/employer-contact`)

---

## 7. Purchases & Payment Integration (BUY-001 ~ BUY-010)
- [x] Backend credit package listing (Starter: 10cr, Pro: 50cr, Enterprise: 150cr)
- [x] Purchase creation (pending state with price & credit snapshot)
- [x] Payment verification architecture (`IPaymentGateway`)
- [x] Development-only simulated payment verification (`/api/credits/purchases/{id}/simulate-success`)
- [x] Idempotent payment callback processing (prevents duplicate credit grants)

---

## 8. Admin & Reporting (ADMIN-001 ~ ADMIN-007)
- [x] Seed default Admin account (`admin@hireflow.com`) and credit packages
- [x] Admin list and toggle user account status (suspend / reactivate)
- [x] Admin project moderation (`Open`, `Hidden`, `Removed`)
- [x] User report submission endpoint (`/api/reports`)
- [x] Admin report review & status update (`Reviewing`, `Resolved`, `Rejected`)
- [x] Audit logging for critical system actions (`AuditLogs`)
- [x] Admin credit transaction inspection

---

## 9. Flutter Frontend Implementation
- [x] Polished, responsive interface localized in Vietnamese
- [x] Authentication screens: Login (with quick demo chips), Register, Forgot Password, Reset Password
- [x] Freelancer UI:
  - Discovery & Search tab with keyword & skill filter chips
  - Project detail screen with skills badges, budget, and deadline
  - Apply modal with CV dropdown & cover letter (-3 credits)
  - Employer contact unlock card (-4 credits) & revealed email/phone
  - CV Management tab: PDF upload with file picker, set default, delete
  - My Applications tab with color-coded status badges
  - Freelancer profile editing (headline, bio, experience years, skills)
- [x] Employer UI:
  - My Projects tab with applicant counts and close project button
  - Post project tab with 5-credit publication fee warning
  - Project applicants screen with candidate details & status update sheet
  - Employer profile editing (company name, public display, private contacts)
- [x] Admin UI:
  - User accounts management tab with search, role filter, and suspend switch
  - Project moderation tab with Open, Hidden, Removed actions
  - User reports tab with review and resolution actions
  - Audit logs tab with administrative history
- [x] Common UI:
  - Wallet screen with current credit balance card
  - Buy packages modal with 3 packages & instant simulated purchase flow
  - Fee schedule info dialog
  - Change password dialog
  - User/Project report submission dialog
- [x] Role Gatekeeper routing users to Freelancer, Employer, or Admin home based on JWT claims

---

## 10. Automated Testing & Verification
- [x] Backend business rules unit tests (`HireFlow.Tests`): 10 passed, 0 failed
- [x] Frontend unit and model tests (`test/model_test.dart`, `test/widget_test.dart`): 5 passed, 0 failed
- [x] Flutter static analysis (`flutter analyze`): 0 errors, 0 warnings, clean
- [x] Backend compilation (`dotnet build backend/HireFlow.slnx`): 0 warnings, 0 errors
- [x] EF Core migration (`InitialCreate`) applied to SQL Server LocalDB
