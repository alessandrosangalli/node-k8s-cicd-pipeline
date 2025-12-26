# Stage 1: Build & Install Dependencies
FROM node:22-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Stage 2: Production Run
FROM node:22-alpine

WORKDIR /usr/src/app

# Install dumb-init and upgrade npm to fix vulnerabilities in the base image
RUN apk add --no-cache dumb-init && \
    npm install -g npm@latest

# Create a non-root user
# UID 10001 (non-root)
USER 10001

# Copy only necessary files from the build stage
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/package.json ./package.json

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["dumb-init", "node", "src/server.js"]

