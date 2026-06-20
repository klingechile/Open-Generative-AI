FROM node:20-alpine AS base

WORKDIR /app

RUN apk add --no-cache git

FROM base AS deps

COPY package*.json ./

RUN mkdir -p packages && \
    rm -rf packages/Vibe-Workflow packages/Open-Poe-AI packages/Open-AI-Design-Agent && \
    git clone --depth 1 https://github.com/SamurAIGPT/Vibe-Workflow.git packages/Vibe-Workflow && \
    git clone --depth 1 https://github.com/Anil-matcha/Open-Poe-AI.git packages/Open-Poe-AI && \
    git clone --depth 1 https://github.com/Anil-matcha/Open-AI-Design-Agent.git packages/Open-AI-Design-Agent

COPY packages/studio/package*.json ./packages/studio/

RUN npm install

FROM deps AS builder

COPY . .

RUN test -f packages/Vibe-Workflow/packages/workflow-builder/package.json || \
    (rm -rf packages/Vibe-Workflow && git clone --depth 1 https://github.com/SamurAIGPT/Vibe-Workflow.git packages/Vibe-Workflow)

RUN test -f packages/Open-Poe-AI/packages/agents/package.json || \
    (rm -rf packages/Open-Poe-AI && git clone --depth 1 https://github.com/Anil-matcha/Open-Poe-AI.git packages/Open-Poe-AI)

RUN test -f packages/Open-AI-Design-Agent/package.json || \
    (rm -rf packages/Open-AI-Design-Agent && git clone --depth 1 https://github.com/Anil-matcha/Open-AI-Design-Agent.git packages/Open-AI-Design-Agent)

RUN npm run build:packages
RUN npm run build

FROM base AS runner

ENV NODE_ENV=production

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/next.config.mjs ./next.config.mjs
COPY --from=builder /app/middleware.js ./middleware.js
COPY --from=builder /app/models_dump.json ./models_dump.json

EXPOSE 3000

CMD ["sh", "-c", "npm run start -- -H 0.0.0.0 -p ${PORT:-3000}"]
