# Fluently (monorepo)

Tài liệu ngắn để chạy nhanh dự án và biết vị trí spec OpenAPI / Swagger.

## Tổng quan

- API NestJS: [apps/api](apps/api)
- OpenAPI spec (YAML) đã đặt ở: [apps/api/src/openapi/fluently-openapi.yaml](apps/api/src/openapi/fluently-openapi.yaml)

## Chạy nhanh (API)

1. Cài dependencies ở workspace gốc:

```bash
npm install
```

2. Chạy dev server cho API:

````bash
# 🚀 Fluently (monorepo)

Tài liệu ngắn để chạy nhanh dự án, vị trí OpenAPI/Swagger và các lưu ý bảo mật.

---

## 🧭 Tổng quan

- **API NestJS:** [apps/api](apps/api)
- **OpenAPI spec (YAML):** [apps/api/src/openapi/fluently-openapi.yaml](apps/api/src/openapi/fluently-openapi.yaml)

---

## 🛠️ Cài đặt & chạy nhanh

1. Cài dependencies ở workspace gốc:

```bash
npm install
````

2. Chạy dev server cho API:

```bash
cd apps/api
npm run dev
```

3. Truy cập:

- Swagger UI: `http://localhost:4000/docs`
- OpenAPI YAML: `http://localhost:4000/docs/openapi.yaml`

---

## ✅ Build & kiểm tra

- Kiểm tra types: `cd apps/api && npm run type-check`
- Build production: `cd apps/api && npm run build`

---

## 🔐 Git / Bảo mật

- Đã cập nhật `.gitignore` để bỏ qua file nhạy cảm: `.env*`, `supabase/.env`, `.aws/credentials`, `dist`, v.v.
- Nếu file nhạy cảm đã từng được commit, xóa khỏi index (giữ file cục bộ):

```bash
git rm --cached path/to/file
git commit -m "Remove sensitive file from index"
```

- Để xóa khỏi lịch sử hoàn toàn, dùng `git filter-repo` hoặc `bfg-repo-cleaner` (tôi có thể hỗ trợ nếu cần).

---

## 🧰 Công cụ & DB

- **Prisma:** schema nằm ở `packages/db/prisma/schema.prisma` và `packages/db` chứa code liên quan DB. Generate client:

```bash
npm run db:generate
```

- **Supabase:** config và migrations ở `fluently-openapi.yaml` (repo có thư mục `supabase/` chứa config và migrations).

---

## 🧑‍💻 VS Code / TypeScript

- Nếu bạn đã disable TypeScript language features, editor sẽ mất diagnostics, IntelliSense và code navigation — build vẫn hoạt động.
- Để dùng TypeScript workspace version: Command Palette → "TypeScript: Select TypeScript Version" → chọn "Use Workspace Version".

---

## 🤝 Contributing

- Fork → feature branch → PR vào `master`. Viết rõ ticket/issue, tests nếu cần.

---

## 📞 Liên hệ

- Contact: phamducquang717@gmail.com

---

Nếu bạn muốn thêm icons khác, badge CI, hoặc phần hướng dẫn deploy cụ thể (Supabase / Docker), tôi sẽ thêm tiếp.
