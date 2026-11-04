# HireFlow — Nền Tảng Kết Nối Freelancer & Nhà Tuyển Dụng

HireFlow là giải pháp kết nối giữa Freelancer và Nhà tuyển dụng (Employer), hỗ trợ tìm kiếm dự án, nộp hồ sơ ứng tuyển bằng CV PDF bảo mật, quản lý trạng thái hồ sơ theo thời gian thực và quản lý tài khoản với cơ chế tín dụng (credit wallet) an toàn, chống gian lận.

Hệ thống được phát triển tuân thủ nghiêm ngặt theo tài liệu yêu cầu kỹ thuật [`HireFlow_RDS_v1.md`](file:///d:/Ki8/PRM393/HireFlow/HireFlow_RDS_v1.md).

---

## 📌 Tài Liệu Kiểm Tra Giai Đoạn 1 (Slot 6 / B12 Check)

- 📊 **Sơ đồ Cơ Sở Dữ Liệu (ERD):** [docs/DATABASE_ERD.md](docs/DATABASE_ERD.md) *(Xem sơ đồ thực thể quan hệ đồ họa trực quan ngay trên GitHub)*
- 🎨 **Thiết Kế Giao Diện Mockup & Figma:** [docs/UI_MOCKUP_FIGMA.md](docs/UI_MOCKUP_FIGMA.md) *(Sơ đồ luồng màn hình, đặc tả UI & Prototype link)*
- 💾 **Kịch bản Cơ Sở Dữ Liệu SQL Server:** [`HireFlow_Database.sql`](HireFlow_Database.sql)

---

## 1. Kiến Trúc Kỹ Thuật (Architecture)

- **Frontend:** Flutter (Dart 3.13 / Flutter 3.47), Material 3, Quản lý trạng thái đa tầng bằng Provider, giao diện tiếng Việt thân thiện, thiết kế đáp ứng (Responsive).
- **Backend:** ASP.NET Core Web API (Targeting .NET 8.0 LTS), Clean Architecture.
- **ORM & Database:** Entity Framework Core 8.0, Microsoft SQL Server (LocalDB / Express) với đầy đủ Foreign Keys, Constraints, Unique Indexes, và Concurrency Tokens (`RowVersion`).
- **Xác thực & Phân quyền:** JWT Bearer Token, mã hóa mật khẩu PBKDF2 với muối ngẫu nhiên (Salted SHA256, 100,000 vòng lặp), Server-side Role & Resource-ownership Authorization.
- **Lưu trữ CV bảo mật:** Hệ thống lưu trữ tệp riêng biệt (`storage/cvs/`), kiểm tra mã nhận diện định dạng (`magic bytes %PDF-`), giới hạn kích thước tối đa 5 MB, phân quyền tải xuống chặt chẽ (chỉ chủ sở hữu hoặc NTD nhận hồ sơ mới có quyền truy cập).
- **Cơ chế Credit Wallet:** Xử lý giao dịch trừ/cộng credit bên trong Database Transaction nguyên tử (Atomic), ngăn ngừa số dư âm và chống xung đột dữ liệu đồng thời bằng Concurrency Token và Idempotency Key.

---

## 2. Quy Định Chi Phí Credit (Business Rules)

| Hành động | Chi phí | Quy tắc tính phí |
|---|---|---|
| Tìm kiếm, xem danh sách & chi tiết dự án | **0 credit** | Miễn phí công khai |
| Nộp hồ sơ ứng tuyển dự án (`Freelancer`) | **3 credits** | Trừ 1 lần duy nhất cho mỗi dự án (`UNIQUE(ProjectId, FreelancerId)`) |
| Mở khóa thông tin liên hệ NTD (`Freelancer`) | **4 credits** | Trừ 1 lần duy nhất theo phạm vi Nhà tuyển dụng; xem lại không mất thêm phí |
| Đăng tin tuyển dụng mới (`Employer`) | **5 credits** | Trừ nguyên tử khi xuất bản tin thành công; thất bại không trừ |
| Chỉnh sửa tin tuyển dụng (`Employer`) | **0 credit** | Miễn phí trong phạm vi MVP |
| Xem & tải CV ứng viên nộp cho dự án của mình | **0 credit** | Miễn phí cho NTD sở hữu dự án |
| Xem & tải CV trong thư viện cá nhân | **0 credit** | Miễn phí cho Freelancer |

---

## 3. Cấu Trúc Thư Mục Dự Án

```
HireFlow/
├── backend/
│   ├── HireFlow.Api/               # ASP.NET Core Web API Project
│   │   ├── Configuration/          # Credit constants & business rule settings
│   │   ├── Controllers/            # REST API Controllers (Auth, Projects, Applications, Credits, Documents, Admin)
│   │   ├── Data/                   # HireFlowDbContext & DbInitializer (Seed data)
│   │   ├── DTOs/                   # Request/Response Data Transfer Objects
│   │   ├── Entities/               # EF Core Domain Entities
│   │   ├── Middleware/             # Centralized Exception Handling Middleware
│   │   ├── Migrations/             # EF Core Migration history
│   │   ├── Services/               # PasswordHasher, Jwt, FileStorage, Credit, Payment, Audit
│   │   └── appsettings.json        # Database connection & JWT config
│   ├── HireFlow.Tests/             # Automated Unit & Business Rule Test Suite
│   └── HireFlow.slnx               # .NET Solution file
├── lib/                            # Flutter Application
│   ├── core/                       # Constants, App Colors, Vietnamese Formatters
│   ├── models/                     # User, Project, Application, Document, Credit, Report models
│   ├── providers/                  # AuthProvider, ProjectProvider, ApplicationProvider, etc.
│   ├── screens/                    # Freelancer, Employer, Admin & Common Screens
│   ├── services/                   # ApiService, AuthService, ProjectService, etc.
│   ├── widgets/                    # CreditBadge, StatusBadge, EmptyState, etc.
│   └── main.dart                   # Role Gatekeeper & Application Root
├── test/                           # Flutter Unit & Widget Tests
├── docs/
│   ├── DECISIONS.md                # Architectural & Business decisions
│   ├── IMPLEMENTATION_STATUS.md    # Feature status aligned with RDS
│   └── TEST_REPORT.md              # Test execution log and validation
├── .env.example                    # Environment variables template
├── HireFlow_RDS_v1.md              # Authoritative Requirements Specification
└── README.md                       # Main Documentation
```

---

## 4. Hướng Dẫn Cài Đặt & Chạy Ứng Dụng (Getting Started)

### 4.1 Yêu cầu môi trường (Prerequisites)
- **.NET SDK:** .NET 8.0 hoặc cao hơn (.NET 10 SDK đã được cài đặt trên máy)
- **SQL Server:** SQL Server LocalDB (`(localdb)\mssqllocaldb`) hoặc SQL Express (`.\SQLEXPRESS`)
- **Flutter SDK:** Phiên bản 3.24+ (phiên bản hiện tại trên máy: 3.47.2)

### 4.2 Cấu hình Cơ sở dữ liệu & Chạy Migrations
1. Đảm bảo dịch vụ SQL Server LocalDB đang hoạt động:
   ```powershell
   sqllocaldb start mssqllocaldb
   ```
2. Cập nhật schema cơ sở dữ liệu bằng EF Core:
   ```powershell
   dotnet ef database update --project backend/HireFlow.Api/HireFlow.Api.csproj
   ```

### 4.3 Khởi chạy Backend API
1. Chạy Backend Web API từ thư mục gốc:
   ```powershell
   dotnet run --project backend/HireFlow.Api/HireFlow.Api.csproj
   ```
2. API sẽ lắng nghe tại:
   - **Swagger UI:** `http://localhost:5136/swagger`
   - **API Base:** `http://localhost:5136/api`

### 4.4 Chạy Backend Test Suite
Để xác nhận tính toàn vẹn của nghiệp vụ trừ credit, bảo mật mật khẩu, phòng chống ứng tuyển trùng lặp và xác thực CV:
```powershell
dotnet test backend/HireFlow.slnx
```

### 4.5 Khởi chạy Frontend Flutter
1. Cài đặt các gói phụ thuộc:
   ```powershell
   flutter pub get
   ```
2. Kiểm tra chất lượng mã nguồn:
   ```powershell
   flutter analyze
   ```
3. Chạy kiểm thử tự động Frontend:
   ```powershell
   flutter test
   ```
4. Khởi chạy ứng dụng (trên Windows, Web, hoặc thiết bị di động):
   ```powershell
   # Chạy trên Windows Desktop:
   flutter run -d windows

   # Hoặc chạy trên Chrome Web:
   flutter run -d chrome
   ```

---

## 5. Tài Khoản Mẫu Thử Nghiệm Sẵn Có (Seed Accounts)

Hệ thống đã tự động gieo sẵn các tài khoản demo và dữ liệu ban đầu khi khởi động lần đầu:

| Vai trò | Email | Mật khẩu mặc định | Ghi chú |
|---|---|---|---|
| **Admin** | `admin@hireflow.com` | `Admin@HireFlow2026!` | Quyền quản trị tài khoản, kiểm duyệt tin và báo cáo |
| **Employer** | `employer@hireflow.com` | `Employer@123!` | Công ty TechNova Solutions VN, có sẵn 50 credits và 2 tin dự án |
| **Freelancer** | `freelancer@hireflow.com` | `Freelancer@123!` | Nguyễn Văn An (Senior Developer), có sẵn 30 credits |

*Lưu ý:* Màn hình đăng nhập đã tích hợp sẵn các nút chọn tài khoản mẫu (Chip buttons) giúp bạn đăng nhập thử nghiệm nhanh chóng chỉ với 1 cú click.

---

## 6. Tài Liệu Kèm Theo
- [Báo Cáo Tiến Độ & Tính Năng (`docs/IMPLEMENTATION_STATUS.md`)](file:///d:/Ki8/PRM393/HireFlow/docs/IMPLEMENTATION_STATUS.md)
- [Báo Cáo Kiểm Thử Tự Động (`docs/TEST_REPORT.md`)](file:///d:/Ki8/PRM393/HireFlow/docs/TEST_REPORT.md)
- [Quyết Định Kiến Trúc & Thiết Kế (`docs/DECISIONS.md`)](file:///d:/Ki8/PRM393/HireFlow/docs/DECISIONS.md)
