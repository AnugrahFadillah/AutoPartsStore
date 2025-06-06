# Menggunakan Node.js versi 20 dengan base image yang ringan (alpine)
FROM node:20-alpine

# Set working directory di dalam Docker container
WORKDIR /app

# Salin file package.json dan package-lock.json (jika ada)
COPY package*.json ./

# Install dependencies
RUN npm install

# Salin seluruh kode ke dalam container
COPY . .

# Cloud Run menggunakan port 8080 secara default, jadi harus expose port 8080
EXPOSE 5000

# Set environment variable PORT ke 8080
ENV PORT 5000

# Jalankan aplikasi
CMD ["node", "index.js"]
