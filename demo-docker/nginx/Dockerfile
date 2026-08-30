FROM nginx:alpine

# Copiar configuración personalizada de Nginx
COPY default.conf /etc/nginx/conf.d/default.conf

# Los archivos del frontend se copian desde el contexto del build
# definido en docker-compose.local.yml usando el directorio demo-frontend/
COPY html/ /usr/share/nginx/html/
