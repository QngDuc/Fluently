# Supabase setup

1. Create a project in Supabase.
2. Copy the Project URL and anon/service role keys into the environment variables in .env.
3. In Supabase > Project Settings > Database, copy the connection string and replace the placeholder values in .env.
4. Run Prisma migration:

```bash
npx prisma migrate dev --schema packages/db/prisma/schema.prisma
```

5. Start the app:

```bash
npm --workspace apps/api run dev
npm --workspace apps/web run dev
npm --workspace apps/admin run dev
```
