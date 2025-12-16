# Use Node.js LTS as base image
FROM node:20-alpine AS base

# Install OpenSSL and required libraries for Prisma
RUN apk add --no-cache openssl libc6-compat python3 make g++

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci

# Generate Prisma Client
RUN npx prisma generate

# Build the application
FROM base AS builder
WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/node_modules/.prisma ./node_modules/.prisma

# Copy source code and config files
COPY . .

# Build TypeScript
ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN npm run build

# Production image
FROM base AS runner
WORKDIR /app

# Install OpenSSL for Prisma in production image
RUN apk add --no-cache openssl libc6-compat

ENV NODE_ENV=production

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs && \
  adduser --system --uid 1001 nodejs

# Copy necessary files from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma

# Create uploads directory for file storage
RUN mkdir -p /app/uploads && \
  chown -R nodejs:nodejs /app

USER nodejs

# Create uploads directory (as nodejs user) to ensure it exists
RUN mkdir -p /app/uploads

# Expose port
EXPOSE 4000

# Volume for persistent file storage (optional, can be mounted at runtime)
VOLUME ["/app/uploads"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/healthz', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"



# Copy startup script
COPY scripts/start.sh ./start.sh
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# Start the application
CMD ["./start.sh", "npm", "start"]