ARG NGINX_IMAGE=nginx:1.28.0-alpine
FROM ${NGINX_IMAGE}

COPY devsecops-demo/container/frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY pmhub-ui/public/ /usr/share/nginx/html/

EXPOSE 80
HEALTHCHECK --interval=5s --timeout=3s --retries=6 CMD wget -q -O - http://127.0.0.1/ >/dev/null || exit 1
