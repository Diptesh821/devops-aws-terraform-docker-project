#!/bin/sh
set -e
# Replace the placeholder in the template and create the final config file
# inside the /etc/nginx/conf.d/ directory.
sed "s|__BACKEND_URL__|${BACKEND_URL}|g" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
# Start Nginx in the foreground
nginx -g "daemon off;"
