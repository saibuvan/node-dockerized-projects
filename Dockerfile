# Use official Node.js image
FROM node:18

# Set working directory
WORKDIR /usr/src/app

# Copy dependency files first
COPY package*.json ./

# Install production dependencies
RUN npm install --only=production

# Copy the rest of the app
COPY . .

# Install SSH server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    # Allow root login via SSH
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # Clean up
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose ports
EXPOSE 22 80 3000

# Create a simple HTTP redirect from port 80 → 3000 (optional)
RUN apt-get update && apt-get install -y nginx && \
    rm /etc/nginx/sites-enabled/default && \
    echo 'server { listen 80; location / { proxy_pass http://localhost:3000; } }' > /etc/nginx/sites-available/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Start both SSH, Nginx, and Node.js together
CMD service ssh start && service nginx start && node app.js