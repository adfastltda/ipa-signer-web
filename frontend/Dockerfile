# Stage 1: Build Elm application
FROM node:20-alpine AS builder

# Install Elm
RUN npm install -g elm@latest-0.19.1

WORKDIR /app

# Copy elm project files
COPY elm.json .
COPY src/ ./src/

# Compile Elm to JavaScript
RUN elm make src/Main.elm --optimize --output=elm.js

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Install envsubst for template substitution
RUN apk add --no-cache gettext

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/

# Copy compiled Elm app
COPY --from=builder /app/elm.js /usr/share/nginx/html/

# Copy index.html as template
COPY index.html /usr/share/nginx/html/index.html.template

# Copy and set up entrypoint script
COPY entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
