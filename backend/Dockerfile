FROM node:20-bookworm

# Instalar dependências de compilação
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libssl-dev \
    zip \
    unzip \
    python3 \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm install

# Copiar código fonte
COPY . .

# Compilar o zsign como binário estático
RUN g++ -O3 -std=c++11 \
    src/zsign.cpp \
    src/common/common.cpp \
    src/common/base64.cpp \
    src/common/json.cpp \
    src/openssl.cpp \
    src/macho.cpp \
    src/bundle.cpp \
    src/archo.cpp \
    src/signing.cpp \
    -I src \
    -I src/common \
    -l crypto \
    -l ssl \
    -o src/zsign \
    -static-libstdc++ \
    -static-libgcc

EXPOSE 3000

CMD ["npm", "start"]
