# Architectural and Business Decisions (HireFlow MVP)

This document records the architectural and business decisions made for unspecified or open requirements, following Section 13 of `HireFlow_RDS_v1.md`.

## 1. Credit Package Configuration & Defaults
- **Requirement:** Section 13.1 – Credit package prices and quantities are backend-managed.
- **Decision:** Seeded default credit packages for development and testing:
  - **Gói Khởi Đầu (Starter):** 10 credits — 50,000 VND (5,000 VND/credit)
  - **Gói Phổ Thông (Pro):** 50 credits — 200,000 VND (4,000 VND/credit, 20% discount)
  - **Gói Doanh Nghiệp (Enterprise):** 150 credits — 500,000 VND (~3,333 VND/credit, 33% discount)
- Packages are stored in the database (`CreditPackages`) with snapshots copied to `CreditPurchases` upon order creation to ensure historical immutability.

## 2. Payment Integration Architecture & Dev Simulator
- **Requirement:** Section 13.2 & 8.4 – Abstract payment provider with server-side verification and idempotent webhook/callback handling.
- **Decision:** Implemented `IPaymentGateway` with a concrete `DevSimulatedPaymentGateway` for development and automated testing.
  - In development, simulated checkout URLs and a dedicated webhook verification endpoint (`/api/credits/purchases/{id}/simulate-success`) allow end-to-end testing without external payment gateway accounts.
  - The simulator is guarded by `IHostEnvironment.IsDevelopment()` or explicit configuration flags, preventing execution in production.
  - Each payment transaction uses an idempotent provider reference check to prevent duplicate credit rewards.

## 3. Contact Unlock Scope
- **Requirement:** Section 13.3 & 4.7 – Unlock scope must be explicit and consistent.
- **Decision:** Implemented **Employer-level** unlock scope. Unlocking an employer's contact details costs 4 credits and grants permanent access to that employer's private contact phone and email for that freelancer across all of that employer's projects.
- Database uniqueness constraint: `UNIQUE(FreelancerId, EmployerId)` on `ContactUnlocks`. Re-requesting the employer contact returns authorized details with 0 credit deduction.

## 4. Project Publication & Moderation Workflow
- **Requirement:** Section 13.4 & 4.6 – Immediate publication vs. moderation approval.
- **Decision:** A project is published immediately with status `Open` upon successful deduction of 5 credits. Admin can moderate any project by changing status to `Hidden` or `Removed`. Closed projects (`Closed`) reject new applications but preserve existing applicant history.

## 5. Compensation & Budget Representation
- **Requirement:** Section 13.5 – Modeling flexible compensation/budget.
- **Decision:** Projects store `BudgetMin`, `BudgetMax`, and `CurrencyCode` (defaulting to `"VND"`). If `BudgetMin == BudgetMax`, it represents a fixed rate; if different, a budget range.

## 6. Private CV Storage & Security
- **Requirement:** Section 13.6, 4.2 & 7 – Private CV storage, no public URLs.
- **Decision:** CV files are stored on disk in a private directory (`storage/cvs`) abstracted by `IFileStorageService`.
  - Stored files are named with random GUID keys (e.g. `{guid}.pdf`).
  - Validation ensures:
    - Maximum file size: 5 MB.
    - File extension: `.pdf`.
    - Magic number / file signature check: First 4 bytes must be `%PDF` (`0x25, 0x50, 0x44, 0x46`).
  - Access is mediated exclusively through authorized API endpoints (`/api/documents/{id}/download` and `/api/applications/{id}/cv`). Unauthorized users receive `403 Forbidden` or `404 Not Found`.

## 7. Password Recovery & Verification
- **Requirement:** Section 13.7 & 4.1 – Password reset using verified mechanism.
- **Decision:** Implemented token/code-based reset flow. In development, reset tokens/verification codes are emitted via `IEmailService` (logging to development console and audit log). In production, an SMTP/SendGrid provider can be plugged in without changing domain logic.

## 8. Application Lifecycle & Immutability
- **Requirement:** Section 13.8 & 4.4 – Application editing and withdrawal.
- **Decision:** In the MVP, applications cannot be withdrawn or resubmitted for the same project (`(ProjectId, FreelancerId)` is unique). Submitting an application creates a permanent snapshot of the CV version referenced by `DocumentId`. If the freelancer deletes their CV from their library, soft-deletion/archival retains the physical file for employers reviewing past applications.

## 9. Non-Refund Policy
- **Requirement:** Section 13.9 – Credit refunds.
- **Decision:** In accordance with RDS defaults, credits spent on applications (3 credits), project publishing (5 credits), or contact unlocks (4 credits) are non-refundable even if a project is rejected, closed, or moderated.

## 10. Database Concurrency & Atomicity
- **Requirement:** Section 8 – Atomic deductions, no negative balances.
- **Decision:** All credit operations execute inside EF Core database transactions with row-level locks or explicit concurrency checks (`Balance >= cost` in update predicate). Transactions record corresponding audit rows in `CreditTransactions` with matching `ReferenceType` and `ReferenceId`.
