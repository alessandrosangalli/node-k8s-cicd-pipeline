# Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

# Install ALL dependencies (needed for build)
RUN apk add --no-cache python3 make g++
RUN npm ci

COPY . .

# Build the NestJS application
RUN npm run build

# Remove development dependencies
RUN npm prune --production

# Stage 2: Production Run
FROM node:22-alpine

WORKDIR /usr/src/app

# Install dumb-init
RUN apk add --no-cache dumb-init

# Create a non-root user (UID 10001) if not exists, though alpine usually has none or root.
# We'll rely on the user ID directly.
USER 10001

COPY --from=builder --chown=10001:10001 /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=10001:10001 /usr/src/app/dist ./dist
COPY --from=builder --chown=10001:10001 /usr/src/app/package.json ./package.json

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["dumb-init", "node", "dist/main.js"]
