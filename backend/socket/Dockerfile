FROM node:22 AS builder

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@10.11.1 --activate

COPY codebase/package.json ./
COPY codebase/pnpm-lock.yaml ./
COPY codebase/tsconfig.json ./

RUN pnpm install

COPY codebase/src ./src

RUN pnpm run build

FROM node:22

WORKDIR /app

# Copy built code and dependencies from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

CMD ["node", "dist/server.js"]