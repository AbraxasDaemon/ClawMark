# AgentVerify Smart Contracts

Agent Verification System (AVS) smart contracts for Base L2.

## Contracts

### AVSRegistry.sol
Core DID registry for agent identity management.
- Register agent DIDs with optional staking
- Key rotation
- Activation/deactivation
- Stake management
- Slashing/revocation (admin)

### AVSCredentials.sol
On-chain credential anchoring (hashes only).
- Anchor credential hashes
- Verify credentials
- Revoke credentials
- Trusted issuer management

### AVSReputation.sol
Reputation score anchoring.
- Oracle-updatable scores
- Tier management (bronze/silver/gold/platinum)
- Historical score tracking
- Metrics storage

## Setup

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Build
forge build

# Test
forge test
```

## Deploy

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export ETHERSCAN_API_KEY=your_etherscan_key

# Deploy to Base Sepolia
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify

# Deploy to Base Mainnet
forge script script/Deploy.s.sol --rpc-url base --broadcast --verify
```

## Contract Addresses

### Base Sepolia (Testnet)
| Contract | Address |
|----------|---------|
| AVSRegistry | TBD |
| AVSCredentials | TBD |
| AVSReputation | TBD |

### Base (Mainnet)
| Contract | Address |
|----------|---------|
| AVSRegistry | TBD |
| AVSCredentials | TBD |
| AVSReputation | TBD |

## License

MIT
