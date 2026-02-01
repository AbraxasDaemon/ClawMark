# ClawMark API

REST API for Agent Verification System.

## Setup

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your settings

# Start development server
npm run dev

# Start production server
npm start
```

## Environment Variables

```bash
PORT=3000
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:3000,https://agentverify.io

# Contract addresses (Base L2)
REGISTRY_CONTRACT=0x...
CREDENTIALS_CONTRACT=0x...
REPUTATION_CONTRACT=0x...

# RPC URLs
BASE_RPC=https://mainnet.base.org
BASE_SEPOLIA_RPC=https://sepolia.base.org

# API Keys (for production)
API_KEY_SECRET=your-secret-key
```

## API Endpoints

### DID Management
- `POST /v1/did/register` - Register new agent DID
- `GET /v1/did/:did` - Resolve DID to document
- `GET /v1/did/:did/status` - Get DID status
- `POST /v1/did/:did/deactivate` - Deactivate DID
- `GET /v1/did` - List all DIDs

### Credentials
- `POST /v1/credentials/anchor` - Anchor credential hash
- `POST /v1/credentials/verify` - Verify credential
- `POST /v1/credentials/revoke` - Revoke credential
- `GET /v1/credentials/agent/:didHash` - List agent credentials

### Reputation
- `GET /v1/reputation/:did` - Get agent reputation
- `POST /v1/reputation/:did` - Update reputation (oracle)
- `GET /v1/reputation/leaderboard` - Top agents
- `GET /v1/reputation/tiers` - Tier definitions

### Health
- `GET /health` - Service health
- `GET /health/ready` - Readiness probe
- `GET /health/live` - Liveness probe

## Testing

```bash
npm test
```

## Deployment

```bash
# Docker
docker build -t agentverify-api .
docker run -p 3000:3000 agentverify-api

# Railway
railway up

# Fly.io
fly deploy
```
