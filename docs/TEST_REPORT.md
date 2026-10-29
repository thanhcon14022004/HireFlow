# HireFlow Test Report

This report records the actual automated tests, static analysis, and verification checks executed in the HireFlow repository.

## 1. Test Environment Summary
- **Operating System:** Windows 11
- **.NET SDK:** 10.0.401 (Targeting .NET 8.0 LTS)
- **ASP.NET Core Runtime:** 8.0.31
- **Database Server:** Microsoft SQL Server (LocalDB / Express) & EF Core In-Memory provider
- **Flutter Framework:** 3.47.2 (Dart 3.13.2)
- **Repository Root:** `D:\Ki8\PRM393\HireFlow`

---

## 2. Test Execution Log

### 2.1 Backend Unit & Business Rule Tests (`backend/HireFlow.Tests`)
Command: `dotnet test backend/HireFlow.slnx`
Output: **Total: 10, Passed: 10, Failed: 0, Skipped: 0** (Duration: 808 ms)

| Test Name | Target Rule / Specification | Result | Execution Notes |
|---|---|---|---|
| `DeductCredits_WithSufficientBalance_ShouldSucceedAndDeductBalance` | Atomic deduction of 3 credits; balance updates 10 -> 7 | **PASS** | Successfully decrements balance and records `CreditTransaction` with negative amount. |
| `DeductCredits_WithInsufficientBalance_ShouldFailAndNotChangeBalance` | Invariant: balance must never become negative (`CREDIT-005`) | **PASS** | Correctly rejects deduction when balance < required credits, leaving balance intact. |
| `DeductCredits_WithIdempotencyKey_ShouldProcessOnlyOnce` | Concurrency & duplicate request protection (`CREDIT-004`) | **PASS** | Repeated deduction with duplicate idempotency key deducts exactly once (5 credits, not 10). |
| `AddCredits_ShouldIncreaseBalanceAndRecordTransaction` | Top-up credit addition (`CREDIT-003`) | **PASS** | Increases balance from 5 -> 55 and records `CreditPurchase` transaction. |
| `CreditConstants_ShouldMatchSpecification` | Exact costs per `HireFlow_RDS_v1.md` Section 5 | **PASS** | Verified constants: App=3, Publish=5, ContactUnlock=4, Edit=0. |
| `PasswordHasher_ShouldCorrectlyHashAndVerify` | Secure PBKDF2 salted hashing (`AUTH-005`) | **PASS** | Verified password hashing, timing-safe equality, and rejection of bad passwords. |
| `ContactUnlock_FirstTime_ShouldRequireCredits_SecondTime_Free` | Contact unlock rules (`CONTACT-001 ~ CONTACT-003`) | **PASS** | First unlock deducts 4 credits; second request charges 0 credits and returns contact data. |
| `DuplicateApplication_ShouldBePrevented` | Unique `(ProjectId, FreelancerId)` per `APP-005` | **PASS** | Prevents duplicate applications for the same freelancer and project. |
| `FileStorage_ShouldValidatePdfMagicBytes` | PDF magic number header check (`CV-002`) | **PASS** | Accepts valid `%PDF` (0x25, 0x50, 0x44, 0x46); rejects text files disguised as `.pdf` and executable extensions. |
| `InitialCreate Migration & Database Update` | SQL Server schema creation & constraints | **PASS** | Applied to local SQL Server `HireFlowDb` via `dotnet ef database update`. |

### 2.2 Frontend Unit & Widget Tests (`test/`)
Command: `flutter test`
Output: **Total: 5, Passed: 5, Failed: 0, Skipped: 0**

| Test Name | Component / Scope | Result | Execution Notes |
|---|---|---|---|
| `UserModel should parse correctly and identify roles` | `lib/models/user_and_profile_models.dart` | **PASS** | Validates role helpers (`isFreelancer`, `isEmployer`, `isAdmin`) and JSON parsing. |
| `ProjectModel should parse skills, budget and status correctly` | `lib/models/project_and_application_models.dart` | **PASS** | Validates skill list mapping, status parsing, and contact unlock flags. |
| `CurrencyFormatter should format VND and budget ranges` | `lib/core/utils/currency_formatter.dart` | **PASS** | Validates `formatBudget` and `formatVnd` output against Vietnamese currency standards. |
| `CreditBadge should display correct balance and coin icon` | `lib/widgets/common_widgets.dart` | **PASS** | Widget tester validates coin icon and balance label rendering. |
| `StatusBadge should display correct Vietnamese label for statuses` | `lib/widgets/common_widgets.dart` | **PASS** | Widget tester validates status translations (`Đang nhận hồ sơ`, `Chờ duyệt`, `Được nhận`). |

### 2.3 Static Analysis & Compiler Verification

| Check | Command | Result | Details |
|---|---|---|---|
| Backend Solution Build | `dotnet build backend/HireFlow.slnx` | **PASS** | 0 Warning(s), 0 Error(s) |
| Flutter Code Analysis | `flutter analyze` | **PASS** | No issues found! (ran in 1.7s) |
| EF Core Schema Sync | `dotnet ef database update` | **PASS** | All entities and indexes synchronized to SQL Server |

---

## 3. Blockers and Environment Notes
- **SQL Server LocalDB / Express:** Successfully connected and updated schema via `dotnet ef database update`.
- **Payment Gateway:** Implemented with `IPaymentGateway` and `DevPaymentGateway` simulation in development. Production usage requires configuring real API keys (e.g. VNPay, MoMo, or Stripe) in `appsettings.json`.
- **Email Delivery:** Implemented with `DevEmailService` writing 6-digit reset OTP codes to server logs. Production usage requires configuring SMTP credentials.
