FROM node:18-alpine as build

WORKDIR /app

# Build arguments for Vite environment variables
ARG VITE_API_URL
ARG VITE_APP_NAME
ARG VITE_ENVIRONMENT

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Set environment variables for build
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_APP_NAME=$VITE_APP_NAME
ENV VITE_ENVIRONMENT=$VITE_ENVIRONMENT

# Build the app (limit Node heap for low-RAM servers)
ENV NODE_OPTIONS=--max-old-space-size=512
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built files
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
