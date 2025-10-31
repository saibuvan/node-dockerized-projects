# Use official Node.js image
FROM node:18

# Set working directory
WORKDIR /usr/src/app

# Copy dependency files first
COPY package*.json ./

# Install production dependencies
RUN npm install --production

# Copy the rest of the app
COPY . .

# Define build-time argument for app port (default: 3000)
ARG APP_PORT=3002

# Make port available as environment variable
ENV PORT=${APP_PORT}

# Expose the app port dynamically
EXPOSE ${PORT}

# Start the Node.js app
CMD ["sh", "-c", "node app.js"]