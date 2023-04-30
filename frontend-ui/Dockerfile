# Use the official Nginx image as the base image
FROM nginx:1.21-alpine

# Remove the default Nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy our custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/

# Copy the frontend UI files to the Nginx container
COPY index.html /usr/share/nginx/html/

# Expose the port the app will run on
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
