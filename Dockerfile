# Base image usando Bun
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# 1. Instalar dependências
COPY . .
RUN bun install --frozen-lockfile

# 2. Build
ENV NODE_ENV=production

# Gerar arquivos do Drizzle (Schema do banco)
RUN cd packages/db && bunx drizzle-kit generate

# --- CORREÇÃO INFALÍVEL ---
# Passamos TODAS as variáveis exigidas na mesma linha do comando.
# Isso garante que o build passe, independentemente da configuração do servidor.
RUN DATABASE_URL="postgresql://postgres:password@localhost:5432/db" \
    NEXT_PUBLIC_APP_URL="https://sim.example.com" \
    BETTER_AUTH_SECRET="secret_placeholder_for_build_12345" \
    BETTER_AUTH_URL="http://localhost:3000" \
    SKIP_ENV_VALIDATION=true \
    SKIP_ENV_CHECK=true \
    bunx turbo run build --filter=sim

# 3. Runner (Imagem Final)
FROM oven/bun:1 AS release
WORKDIR /usr/src/app

# Copia os arquivos construídos para a imagem final
COPY --from=base /usr/src/app/node_modules ./node_modules
COPY --from=base /usr/src/app/packages ./packages
COPY --from=base /usr/src/app/apps/sim/.next ./apps/sim/.next
COPY --from=base /usr/src/app/apps/sim/public ./apps/sim/public
COPY --from=base /usr/src/app/apps/sim/package.json ./apps/sim/package.json
COPY --from=base /usr/src/app/package.json ./package.json
COPY --from=base /usr/src/app/turbo.json ./turbo.json

# Variáveis de Runtime (Aqui ele vai ler do Easypanel quando rodar de verdade)
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

EXPOSE 3000

# Script de inicialização (Roda a migração real e inicia o app)
CMD ["sh", "-c", "cd packages/db && bunx drizzle-kit push && cd ../../apps/sim && bun run start"]
