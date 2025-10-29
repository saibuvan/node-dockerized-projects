# Use official Node.js image
FROM node:18

# Set working directory
WORKDIR /usr/src/app

# Copy dependency files first
COPY package*.json ./

# Install production dependencies
RUN npm install --staging

# Copy the rest of the app
COPY . .

# Expose the app port
EXPOSE 3000

# Start app without PM2
CMD ["node", "app.js"]