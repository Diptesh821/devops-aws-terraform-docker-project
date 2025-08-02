FROM nginx:alpine
COPY . /usr/share/nginx/html
# Copy the Nginx configuration template to the correct directory
# This will become /etc/nginx/conf.d/default.conf after the entrypoint script runs
COPY nginx.conf /etc/nginx/conf.d/default.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# The entrypoint script will generate the final config and start Nginx
CMD ["/entrypoint.sh"]
