# ─── Base ────────────────────────────────────────────────────────
FROM node:20-alpine AS base
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN npm install -g turbo

# ─── Pruner – Turborepo remote cache pruning ────────────────────
FROM base AS pruner
COPY . .
RUN turbo prune @fluently/api --docker

# ─── Installer ──────────────────────────────────────────────────
FROM base AS installer
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/package-lock.json ./package-lock.json
RUN npm ci

COPY --from=pruner /app/out/full/ .
RUN npx turbo run build --filter=@fluently/api

# ─── Development (hot-reload) ───────────────────────────────────
FROM base AS development
COPY --from=installer /app .
WORKDIR /app/apps/api
CMD ["npm", "run", "start:dev"]

# ─── Production ─────────────────────────────────────────────────
FROM node:20-alpine AS production
RUN apk add --no-cache dumb-init
WORKDIR /app

ENV NODE_ENV=production

COPY --from=installer --chown=node:node /app/apps/api/dist ./dist
COPY --from=installer --chown=node:node /app/node_modules ./node_modules
COPY --from=installer --chown=node:node /app/apps/api/package.json .

USER node
EXPOSE 4000
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/main.js"]
