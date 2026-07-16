# Dockerfile para el Agente On-Premise
FROM node:18-alpine

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias de producción
RUN npm install --only=production

# Copiar código fuente
COPY . .

# El agente NO expone ningún puerto. Solo realiza conexiones salientes (outbound) hacia el servidor central.
# Por lo tanto, omitimos la instrucción EXPOSE intencionalmente para la auditoría de seguridad perimetral.

# Comando para ejecutar la aplicación
CMD ["node", "index.js"]
