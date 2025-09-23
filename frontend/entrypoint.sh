#!/bin/sh
cat <<EOF > /usr/share/nginx/html/env-config.js
window.__ENV__ = {
  PRODUCT_API_BASE_URL: "${PRODUCT_API_BASE_URL}",
  ORDER_API_BASE_URL: "${ORDER_API_BASE_URL}",
  CUSTOMER_API_BASE_URL: "${CUSTOMER_API_BASE_URL}"
};
EOF

exec nginx -g "daemon off;"
