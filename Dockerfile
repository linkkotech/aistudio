# Base image usando Bun
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# 1. Instalar dependências
COPY . .
RUN bun install --frozen-lockfile

# 2. Build
ENV NODE_ENV=production

# VARIÁVEIS "FAKE" PARA O BUILD PASSAR
# O Next.js exige que elas existam na compilação, mas não precisa conectar de verdade agora.
ENV DATABASE_URL="postgresql://postgres:password@localhost:5432/db"
ENV BETTER_AUTH_SECRET="secret_placeholder_for_build"
ENV BETTER_AUTH_URL="http://localhost:3000"

# Essencial para o build
ARG NEXT_PUBLIC_APP_URL
ENV NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL

# Pede para o T3 env (se usado) pular a validação rigorosa
ENV SKIP_ENV_VALIDATION=true
ENV SKIP_ENV_CHECK=true

# Gera arquivos do Drizzle
RUN cd packages/db && bunx drizzle-kit generate
# Build apenas do App Sim
RUN bunx turbo run build --filter=sim

# 3. Runner
FROM oven/bun:1 AS release
WORKDIR /usr/src/app

# Copia os arquivos construídos
COPY --from=base /usr/src/app/node_modules ./node_modules
COPY --from=base /usr/src/app/packages ./packages
COPY --from=base /usr/src/app/apps/sim/.next ./apps/sim/.next
COPY --from=base /usr/src/app/apps/sim/public ./apps/sim/public
COPY --from=base /usr/src/app/apps/sim/package.json ./apps/sim/package.json
COPY --from=base /usr/src/app/package.json ./package.json
COPY --from=base /usr/src/app/turbo.json ./turbo.json

# Variáveis
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

EXPOSE 3000

# Script de inicialização
CMD ["sh", "-c", "cd packages/db && bunx drizzle-kit push && cd ../../apps/sim && bun run start"]
