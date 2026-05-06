# Frontend Elm + Docker Setup

Este projeto agora inclui um frontend em Elm com Docker separado para frontend e backend.

## Estrutura

```
ipa-signer-web/
├── backend/          # Node.js + zsign native addon
├── frontend/         # Elm SPA
├── docker-compose.yml
└── .env.example
```

## Quick Start com Docker

```bash
# Copiar variáveis de ambiente
cp .env.example .env

# Subir os serviços
docker-compose up --build

# Acessar
# Frontend: http://localhost:8080
# Backend API: http://localhost:3000
```

## Desenvolvimento

### Backend apenas
```bash
cd backend
npm install
npm run build
npm start
```

### Frontend apenas (com elm-live)
```bash
cd frontend
# Instalar elm
npm install -g elm@latest-0.19.1

# Rodar em modo desenvolvimento
elm-live src/Main.elm --open -- --output=elm.js
```

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `API_URL` | URL do backend | `http://localhost:3000` |

## Funcionalidades do Frontend

- Upload de arquivo IPA
- Upload de certificado (.p12)
- Upload de mobileprovision
- Campo para senha do certificado
- Feedback visual de loading/erro/sucesso

## API Endpoints

### POST /sign

Request body:
```json
{
  "ipaPath": "/path/to/file.ipa",
  "cert": "/path/to/cert.p12",
  "mobileProvision": "/path/to/provision.mobileprovision",
  "password": "cert-password"
}
```

Response:
```json
{
  "success": true,
  "output": "signing result"
}
```
