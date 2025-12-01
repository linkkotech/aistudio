# Base image usando Bun (o runtime do Sim)
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# 1. Instalar dependências
# Copiamos tudo primeiro para garantir que o workspace do Bun funcione
COPY . .
# Instala as dependências de todos os pacotes do monorepo
RUN bun install --frozen-lockfile

# 2. Build
ENV NODE_ENV=production
# Gera o cliente do Prisma/Drizzle (importante para o DB funcionar)
RUN cd packages/db && bun run db:generate
# Executa o build do app principal (sim)
# O script "build" no package.json da raiz geralmente dispara o turbo build
RUN bun run build

# 3. Runner (Imagem final mais leve)
FROM oven/bun:1 AS release
WORKDIR /usr/src/app

# Copia os arquivos construídos e node_modules necessários
COPY --from=base /usr/src/app/node_modules ./node_modules
COPY --from=base /usr/src/app/packages ./packages
COPY --from=base /usr/src/app/apps/sim/.next ./apps/sim/.next
COPY --from=base /usr/src/app/apps/sim/public ./apps/sim/public
COPY --from=base /usr/src/app/apps/sim/package.json ./apps/sim/package.json
COPY --from=base /usr/src/app/package.json ./package.json
COPY --from=base /usr/src/app/turbo.json ./turbo.json

# Variáveis de ambiente para produção
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Expõe a porta
EXPOSE 3000

# Comando para iniciar o servidor Next.js standalone ou via script do sim
# Ajustado para rodar a migração do banco antes de iniciar (prática segura)
CMD ["sh", "-c", "cd packages/db && bun run db:push && cd ../../apps/sim && bun run start"]
