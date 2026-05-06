# frontend
cd frontend && docker build -t ghcr.io/adfastltda/ipa-signer-web:frontend . && docker push ghcr.io/adfastltda/ipa-signer-web:frontend 
curl http://69.62.89.61:3000/api/deploy/19e885b6417a246c04d75ff4aed8453289c30c648079a2f4

# backend
cd ../backend && docker build -t ghcr.io/adfastltda/ipa-signer-web:backend . && docker push ghcr.io/adfastltda/ipa-signer-web:backend 
curl http://69.62.89.61:3000/api/deploy/30d78a21406f09a03cdc25c7687ebba76094a289b116c712