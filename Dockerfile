# Create from base node image (18 is LTS)
FROM node:18

# Working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json into /app
COPY package*.json ./

# Install all dependencies declared in package.json
RUN npm install

# Copy the rest of your application code into the container
COPY . .

# Expose port 8080 (used in app.js)
EXPOSE 8088

# 7. Command to run the start script
CMD ["npm", "start"]
