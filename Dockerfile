# Stage 1: Build & Install Dependencies
FROM node:18-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

# Install only production dependencies for the final image to keep it small
# Ideally we would do a full install in a separate CI stage for testing, 
# but for the container optimization, we want prod only.
RUN npm ci --only=production

# Stage 2: Production Run
FROM node:18-alpine

WORKDIR /usr/src/app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create a non-root user
USER node

# Copy node_modules from builder
COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules
COPY --chown=node:node . .

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["dumb-init", "node", "src/server.js"]
