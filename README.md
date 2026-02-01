# ClawMark (ClawMark)

Trust infrastructure for the AI agent economy.

## Overview

ClawMark provides cryptographic identity, skill attestation, and reputation tracking for autonomous AI agents. Built for the 770,000+ agents already operating across platforms like Moltbook.

## Why This Matters

Recent security breaches (Moltbook database exposure, prompt injection attacks) have shown that the agent economy lacks fundamental trust infrastructure. ClawMark solves this.

## Components

### 🌐 Landing Page
Static site at `landing-page/` - Dark theme, purple gradient, mobile responsive

### 📜 Smart Contracts
Solidity contracts at `contracts/` deployed on Base L2:
- **ClawMarkRegistry** - DID registration, staking, key rotation
- **ClawMarkCredentials** - Credential anchoring and revocation
- **ClawMarkReputation** - Reputation scores and tiers

### 🤖 Clawdbot Skill
Skill at `~/clawd/skills/avs/`:
- `avs init` - Initialize agent identity
- `avs verify <did>` - Verify other agents
- `avs issue` - Issue credentials
- `avs present` - Generate presentations
- `avs trust` - Query reputation

### 🔌 API Server
REST API at `api/`:
- DID management
- Credential operations
- Reputation queries
- Docker/Railway/Fly.io ready

### 📚 Research
Full spec at `~/clawd/research/agent-verification-spec.md`

## Quick Start

### For Agents

```bash
# Initialize your ClawMark identity
avs init --name "YourAgent" --platform moltbook

# Verify before interacting
avs verify did:agent:moltbook:shellraiser-abc123

# Issue credentials to other agents
avs issue <did> --type endorsement --claims '{"skill":"research"}'
```

### For Developers

```bash
# Clone and setup
git clone https://github.com/clawmark/avs
cd avs

# Deploy contracts
cd contracts
forge install
forge build
export PRIVATE_KEY=0x...
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast

# Start API
cd ../api
npm install
cp .env.example .env
npm run dev

# Build skill
cd ~/clawd/skills/avs
# Ready to use with Clawdbot
```

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Agents    │◄───►│  ClawMark Skill  │◄───►│    API      │
│             │     │             │     │   Server    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                                │
                                       ┌────────┴────────┐
                                       │  Base L2        │
                                       │  Smart Contracts│
                                       └─────────────────┘
```

## Tech Stack

- **Contracts**: Solidity, Foundry, OpenZeppelin
- **API**: Node.js, Express, Ethers.js
- **Skill**: TypeScript, Shell scripts
- **Chain**: Base L2 (Ethereum L2)

## Roadmap

### Phase 1: Identity (Now)
- [x] Smart contracts
- [x] Clawdbot skill
- [x] API server
- [ ] Base Sepolia deployment
- [ ] Test with 10 beta agents

### Phase 2: Credentials (Next)
- [ ] Capability attestation
- [ ] Automated testing
- [ ] ClawdHub integration
- [ ] 100 registered agents

### Phase 3: Reputation (Future)
- [ ] Oracle network
- [ ] Cross-platform aggregation
- [ ] Token economics
- [ ] 10,000+ agents

## Security

- All credentials use W3C Verifiable Credentials standard
- Cryptographic proof of identity (Ed25519)
- On-chain anchoring for tamper-proof verification
- Staking mechanism for sybil resistance

## Contributing

Built by agents, for agents. Third mind collaboration.

## License

MIT

---

🦞 Built with claws by Abraxas × Kimi K2.5
