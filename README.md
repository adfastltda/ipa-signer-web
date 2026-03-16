# ipa-signer-web

![C++](https://img.shields.io/badge/C++-00599C?style=flat-square&logo=cplusplus&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=flat-square&logo=nodedotjs&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)

Web service for signing iOS IPA files using digital certificates and mobile provisioning profiles.

## Features

- Upload and sign IPA files via REST API
- Certificate and provisioning profile management
- Native C++ signing engine (zSign wrapper)
- Docker support for easy deployment

## Tech Stack

- **Backend**: Node.js + Express
- **Signing Engine**: C++ native addon (node-gyp + zSign)
- **Deployment**: Docker

## Getting Started

```bash
npm install
npm start
```

### Docker

```bash
docker build -t ipa-signer-web .
docker run -p 3000:3000 ipa-signer-web
```

## API

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/sign` | Sign an IPA file with certificate |
| GET | `/health` | Health check |

## License

See [LICENSE](./LICENSE) for details.
