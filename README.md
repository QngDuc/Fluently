# 🚀 Fluently Monorepo

[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D18-339933?logo=node.js&logoColor=white)](#)
[![NestJS](https://img.shields.io/badge/NestJS-E0234E?logo=nestjs&logoColor=white)](#)
[![Prisma](https://img.shields.io/badge/Prisma-2D3748?logo=prisma&logoColor=white)](#)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?logo=typescript&logoColor=white)](#)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)](#)

# Fluently

> Break language barriers. Speak with confidence.

Fluently là nền tảng học ngoại ngữ ứng dụng AI: luyện hội thoại, đánh giá phát âm, theo dõi tiến độ và học theo lộ trình cá nhân. Giai đoạn đầu ưu tiên tiếng Anh.

Repository này là **monorepo** (npm workspaces + Turborepo) gồm API, web, admin và các package dùng chung.

## Trạng thái hiện tại

Dự án đang ở giai đoạn khởi tạo (scaffold):

| Thành phần | Trạng thái |
|---|---|
| `apps/api` | NestJS chạy được. Hiện mới có `GET /health`, Swagger UI và phục vụ file OpenAPI. Các module Auth, Profile, Pronunciation, Conversation, Payment **mới chỉ có trong hợp đồng API** (`fluently-openapi.yaml`), chưa được cài đặt. |
| `apps/web` | Next.js 14, mới có trang chủ placeholder và `ThemeProvider` (light/dark). |
| `apps/admin` | Next.js 14, mới có trang placeholder. |
| `packages/db` | Prisma schema (PostgreSQL/Supabase), chưa có migration. |
| `packages/ui`, `packages/config` | Placeholder. |

## Công nghệ

- **Backend:** NestJS 10, Swagger/OpenAPI, Socket.IO (đã khai báo dependency)
- **Frontend:** Next.js 14 (App Router), React 18, Tailwind CSS
- **Database:** PostgreSQL qua Supabase, ORM Prisma 5
- **Hạ tầng:** Docker Compose (Postgres, Redis), GitHub Actions, Railway
- **Tooling:** Turborepo, TypeScript 5, ESLint, Prettier

## Cấu trúc thư mục

```text
fluently/
├── apps/
│   ├── api/                  # NestJS API (cổng 4000)
│   │   └── src/openapi/      # fluently-openapi.yaml (hợp đồng API)
│   ├── web/                  # Next.js web app (cổng 3000)
│   └── admin/                # Next.js admin dashboard (cổng 3001)
├── packages/
│   ├── db/                   # Prisma schema + client (prisma/schema.prisma)
│   ├── ui/                   # Component dùng chung
│   └── config/               # Cấu hình dùng chung
├── supabase/                 # Cấu hình Supabase CLI
├── .github/workflows/        # ci.yml, security.yml
├── docker-compose.yml
├── Makefile
├── tsconfig.base.json
└── turbo.json
```

> Thư mục `fluent-ai/` là bản thiết kế database trước đó (schema Prisma, migration SQL và seed cho Supabase) và **không thuộc workspace**. Cần quyết định gộp hoặc loại bỏ để tránh hai schema khác nhau.

## Yêu cầu môi trường

- Node.js >= 20
- npm >= 10 (dự án dùng `npm@10.8.2`)
- Docker + Docker Compose (tùy chọn, để chạy toàn bộ stack)
- Tài khoản Supabase hoặc PostgreSQL cục bộ

## Bắt đầu nhanh

### 1. Cài đặt dependency

```bash
npm install
```

### 2. Cấu hình môi trường

```bash
cp .env.example .env
```

Điền các biến cần thiết. Prisma schema yêu cầu cả hai biến sau:

```env
DATABASE_URL="postgresql://..."   # connection string (pooler)
DIRECT_URL="postgresql://..."     # kết nối trực tiếp, dùng cho migration
```

> `.env.example` ở thư mục gốc hiện chưa có `DIRECT_URL`, hãy thêm vào thủ công.

Không commit `.env` hoặc bất kỳ file chứa secret nào.

### 3. Generate Prisma Client

```bash
npm run db:generate
```

Chạy lại lệnh này mỗi khi sửa `packages/db/prisma/schema.prisma` hoặc sau khi clone repo.

### 4. Chạy migration (nếu đã có database)

```bash
npx prisma migrate dev --schema packages/db/prisma/schema.prisma
```

### 5. Chạy ứng dụng

Chạy tất cả bằng Turborepo:

```bash
npm run dev
```

Hoặc chạy riêng từng app:

```bash
npm --workspace apps/api run dev     # http://localhost:4000
npm --workspace apps/web run dev     # http://localhost:3000
npm --workspace apps/admin run dev   # http://localhost:3001
```

### 6. Kiểm tra API

| Đường dẫn | Mô tả |
|---|---|
| `http://localhost:4000/health` | Health check |
| `http://localhost:4000/docs` | Swagger UI |
| `http://localhost:4000/docs/openapi.yaml` | File hợp đồng OpenAPI |

## Chạy bằng Docker

```bash
make dev        # build và chạy toàn bộ stack
make up         # chạy nền
make down       # dừng
make logs s=api # xem log một service
make help       # danh sách lệnh
```

Stack gồm `postgres`, `redis`, `api`, `web` và `admin`. Staging dùng thêm `docker-compose.staging.yml`:

```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml up
```

## Lệnh thường dùng

| Lệnh | Tác dụng |
|---|---|
| `npm run dev` | Chạy các app ở chế độ phát triển |
| `npm run build` | Build toàn bộ workspace |
| `npm run lint` | Kiểm tra lint |
| `npm run type-check` | Kiểm tra kiểu TypeScript |
| `npm run test` | Chạy test |
| `npm run db:generate` | Generate Prisma Client |

Trước khi mở Pull Request, hãy chạy tối thiểu:

```bash
npm run lint && npm run type-check && npm run build
```

## API

Hợp đồng API được viết theo OpenAPI 3.1 tại `apps/api/src/openapi/fluently-openapi.yaml`, gồm 5 module:

- **Auth:** đăng ký, đăng nhập, OAuth (Google/Apple), refresh token, quên/đặt lại mật khẩu
- **Profile & Preferences:** hồ sơ, ảnh đại diện, cài đặt cá nhân
- **Pronunciation:** phân tích phát âm, lịch sử luyện tập
- **Conversation:** phiên hội thoại AI và tin nhắn
- **Payment:** gói cước, thanh toán, webhook, subscription

Lưu ý: file này là hợp đồng thiết kế, một số endpoint và model chưa khớp với Prisma schema hiện tại.

## CI/CD

- `ci.yml`: lint, type-check, test, build và build Docker image (api, web, admin) cho PR và push lên `main`/`develop`.
- `security.yml`: `npm audit` và CodeQL chạy hằng tuần.
- Triển khai: Railway (tự động build từ GitHub).

## Quy ước phát triển

- Không hardcode API key; dùng biến môi trường.
- Không commit `.env`, `supabase/.env`, `.aws/credentials`. Nếu lỡ track file nhạy cảm, dùng `git rm --cached <file>`.
- Bật RLS cho mọi bảng trong schema `public` của Supabase.
- Ghim phiên bản package và commit lockfile.
- Trong VS Code, chọn **Use Workspace Version** cho TypeScript (`Ctrl+Shift+P` → *TypeScript: Select Version*).

## Đóng góp

1. Fork repository và tạo nhánh từ `main` (ví dụ `feature/add-auth`).
2. Commit rõ ràng, kèm issue ID nếu có.
3. Chạy lint, type-check, build trước khi push.
4. Mở Pull Request và chờ review.

## Liên hệ

Maintainer: phamducquang717@gmail.com
