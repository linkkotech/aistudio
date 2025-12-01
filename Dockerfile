# Base image usando Bun
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# 1. Instalar dependências
COPY . .
RUN bun install --frozen-lockfile

# 2. Build
ENV NODE_ENV=production
# CORREÇÃO AQUI: Usando bunx drizzle-kit generate diretamente
RUN cd packages/db && bunx drizzle-kit generate
# Build do app principal
RUN bun run build

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

# CORREÇÃO AQUI: Usando bunx drizzle-kit push no start
CMD ["sh", "-c", "cd packages/db && bunx drizzle-kit push && cd ../../apps/sim && bun run start"]
