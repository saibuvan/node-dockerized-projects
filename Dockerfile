# Use official Node.js image (Debian-based)
FROM node:18

# Set working directory
WORKDIR /usr/src/app

# Copy dependency files first
COPY package*.json ./

# Install production dependencies
RUN npm install --only=production

# Copy the rest of the app
COPY . .

# ---------------------------
# Fix DNS / network issues
# ---------------------------
# Force use of Google DNS during build (helps in WSL / Jenkins)
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf

# ---------------------------
# Install SSH and Nginx
# ---------------------------
RUN apt-get update || (sleep 5 && apt-get update) && \
    apt-get install -y --no-install-recommends openssh-server nginx && \
    mkdir -p /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    # Enable root login for SSH
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # Configure Nginx reverse proxy to Node.js app
    rm -rf /etc/nginx/sites-enabled/default && \
    echo 'server { listen 80; location / { proxy_pass http://localhost:3000; } }' > /etc/nginx/sites-available/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default && \
    # Cleanup
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Expose ports
# ---------------------------
# 22  -> SSH
# 80  -> HTTP (via Nginx reverse proxy)
# 3000 -> Node.js app
EXPOSE 22 80 3000

# ---------------------------
# Start SSH, Nginx, and Node app
# ---------------------------
# Use bash -c so we can run multiple processes in one CMD
CMD bash -c "service ssh start && service nginx start && node app.js"