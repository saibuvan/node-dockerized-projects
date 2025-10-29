# ----------------------------------------------------------
# Base image
# ----------------------------------------------------------
FROM node:18

# Set working directory
WORKDIR /usr/src/app

# ----------------------------------------------------------
# Copy package files and install dependencies
# ----------------------------------------------------------
COPY package*.json ./
RUN npm install --only=production

# ----------------------------------------------------------
# Copy application source
# ----------------------------------------------------------
COPY . .

# ----------------------------------------------------------
# Install OpenSSH Server and Nginx (for port 22 & 80)
# ----------------------------------------------------------
RUN apt-get -o Acquire::ForceIPv4=true -o Acquire::http::No-Cache=True -o Acquire::Retries=3 update || (sleep 5 && apt-get update) && \
    apt-get install -y --no-install-recommends openssh-server nginx && \
    mkdir -p /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    rm -rf /etc/nginx/sites-enabled/default && \
    echo 'server { \
        listen 80; \
        location / { proxy_pass http://localhost:3000; } \
    }' > /etc/nginx/sites-available/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------
# Expose ports
# ----------------------------------------------------------
EXPOSE 3000 80 22

# ----------------------------------------------------------
# Start both Node app + SSH + Nginx
# ----------------------------------------------------------
CMD service ssh start && service nginx start && node app.js