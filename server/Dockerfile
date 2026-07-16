# Dockerfile para el Servidor Central (Cloud Gateway)
FROM node:18-alpine

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias de producción
RUN npm install --only=production

# Copiar código fuente
COPY . .

# Exponer el puerto por defecto (3500)
EXPOSE 3500

# Comando para ejecutar la aplicación
CMD ["node", "index.js"]
