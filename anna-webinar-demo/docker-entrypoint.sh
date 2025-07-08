#!/bin/sh

# Replace environment variables in built files
find /usr/share/nginx/html -name "*.js" -exec sed -i "s|REACT_APP_API_URL_PLACEHOLDER|${REACT_APP_API_URL:-http://45.32.212.233:8000}|g" {} \;
find /usr/share/nginx/html -name "*.js" -exec sed -i "s|REACT_APP_WS_URL_PLACEHOLDER|${REACT_APP_WS_URL:-ws://45.32.212.233:8000}|g" {} \;

# Execute the main command
exec "$@"
