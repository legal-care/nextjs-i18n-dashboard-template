# Step 1: Build the application using Node.js 20
FROM node:20 AS builder

# Set working directory inside the container
WORKDIR /app

# Copy package.json and lock files to install dependencies
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application code
COPY . .

# Build the Next.js application
RUN npm run build

# Step 2: Use a lightweight production image to run the application
FROM node:20-slim

# Set working directory inside the container
WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose the port that the application will run on
EXPOSE 3000

# Run the application
CMD ["npm", "start"]

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (res) => { if (res.statusCode !== 200) { process.exit(1) } })"
