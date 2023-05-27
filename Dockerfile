# Use the official Node.js 14 image as the base image
FROM node:16

# Set the working directory in the container
WORKDIR /app

# Copy the package.json and package-lock.json files to the container
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the entire project directory to the container
COPY . .

# Build the Nuxt.js application
RUN npm run build

# Expose the application port (change it if necessary)
EXPOSE 3000

# Set the command to run the application
CMD [ "npm", "start" ]