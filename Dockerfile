# Stage 1: Build & Install Dependencies
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Stage 2: Production Run
FROM node:20-alpine

WORKDIR /usr/src/app

# Install dumb-init and upgrade npm to fix vulnerabilities in the base image
RUN apk add --no-cache dumb-init && \
    npm install -g npm@latest

# Create a non-root user
USER node


# Copy only necessary files
COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules
COPY --chown=node:node src ./src

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["dumb-init", "node", "src/server.js"]

