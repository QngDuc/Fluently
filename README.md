# 🚀 Fluently Monorepo

[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D18-339933?logo=node.js&logoColor=white)](#)
[![NestJS](https://img.shields.io/badge/NestJS-E0234E?logo=nestjs&logoColor=white)](#)
[![Prisma](https://img.shields.io/badge/Prisma-2D3748?logo=prisma&logoColor=white)](#)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?logo=typescript&logoColor=white)](#)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)](#)

Tài liệu hướng dẫn khởi chạy, cấu trúc kiến trúc và quy chuẩn phát triển cho dự án Fluently.

## 🏗 Tổng quan kiến trúc & Công nghệ

Dự án được xây dựng theo kiến trúc **Monorepo**, tách biệt rõ ràng giữa các ứng dụng (apps) và các gói dùng chung (packages).

- **Backend Framework:** NestJS (`apps/api`)
- **Database & ORM:** PostgreSQL (via Supabase) & Prisma (`packages/db`)
- **API Documentation:** OpenAPI 3.0 / Swagger

---

## 📂 Cấu trúc thư mục

```text
fluently/
├── apps/
│   └── api/                # Core NestJS API application
│       └── src/openapi/    # Nơi chứa file fluently-openapi.yaml
├── packages/
│   └── db/                 # Prisma schema & Database logic
├── supabase/               # Cấu hình & Migrations của Supabase
└── package.json            # Cấu hình Monorepo Workspace
```

---

⚙️ Yêu cầu môi trường (Prerequisites)
Trước khi chạy dự án, hãy đảm bảo máy bạn đã cài đặt:

Node.js (Phiên bản >= 18.x)

npm (Phiên bản >= 9.x)

Khuyến nghị cài đặt thêm extension Prisma trên VS Code.

🚀 Hướng dẫn khởi chạy (Local Development)
Bước 1: Cài đặt dependencies
Tại thư mục gốc của dự án, chạy lệnh:

Bash
npm install
Bước 2: Thiết lập môi trường
Sao chép file .env.example thành .env (nếu có) và điền các thông số kết nối Database (Supabase URL, Database Password,...).

Bash
cp .env.example .env
Bước 3: Generate Prisma Client
Mỗi khi có thay đổi trong schema.prisma hoặc sau khi clone source code, bạn cần tạo lại Prisma Client:

Bash
npm run db:generate
Bước 4: Khởi động API Server

Bash
cd apps/api
npm run dev
Bước 5: Truy cập API Documentation
Sau khi server báo Successfully started, truy cập:

📖 Swagger UI: http://localhost:4000/docs

📄 OpenAPI YAML: http://localhost:4000/docs/openapi.yaml

✅ Quy trình Build & Kiểm tra (CI/CD)
Trước khi push code lên repo hoặc tạo Pull Request, hãy đảm bảo code của bạn không có lỗi syntax hay type:

Bash

# Di chuyển vào thư mục API

cd apps/api

# Kiểm tra chặt chẽ định dạng TypeScript

npm run type-check

# Build bản production

npm run build
💻 Hướng dẫn cho Developer (DX)
Cấu hình VS Code: Để IntelliSense và code navigation hoạt động hoàn hảo trong môi trường Monorepo, hãy sử dụng phiên bản TypeScript của workspace.
(Command Palette Ctrl+Shift+P → TypeScript: Select TypeScript Version → Chọn Use Workspace Version).

Bảo mật (Security):

Tuyệt đối KHÔNG commit các file chứa secret keys như .env, supabase/.env, .aws/credentials.

Nếu lỡ track nhầm file nhạy cảm vào Git, sử dụng lệnh git rm --cached <đường-dẫn-file> để gỡ bỏ khỏi index mà không xóa file ở local.

🤝 Đóng góp (Contributing)
Fork repository.

Tạo feature branch mới từ nhánh master (ví dụ: feature/add-new-auth).

Commit thay đổi với message rõ ràng, kèm ticket/issue ID nếu có.

Mở Pull Request và chờ review.

📧 Liên hệ (Maintainer): phamducquang717@gmail.com

---
