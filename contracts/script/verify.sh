#!/bin/bash
# Verify ClawMark contracts on Basescan
# Run after deployment

set -e

# Load environment
source ~/.clawdbot/.env

# Contract addresses (update after deployment)
REGISTRY="${CLAWMARK_REGISTRY_CONTRACT:-}"
CREDENTIALS="${CLAWMARK_CREDENTIALS_CONTRACT:-}"
REPUTATION="${CLAWMARK_REPUTATION_CONTRACT:-}"

# Basescan API key
BASESCAN_API_KEY="${BASESCAN_API_KEY:-}"

if [ -z "$BASESCAN_API_KEY" ]; then
  echo "⚠️  BASESCAN_API_KEY not set"
  echo "Get one at: https://basescan.org/myapikey"
  exit 1
fi

if [ -z "$REGISTRY" ]; then
  echo "⚠️  Contract addresses not set"
  echo "Run deployment first, then update ~/.clawdbot/.env"
  exit 1
fi

echo "🦞 Verifying ClawMark contracts on Basescan..."
echo ""

# Add forge to PATH
export PATH="$HOME/.foundry/bin:$PATH"

cd "$(dirname "$0")/.."

# Verify ClawMarkRegistry
echo "1. Verifying ClawMarkRegistry..."
forge verify-contract \
  --chain-id 84532 \
  --compiler-version v0.8.19 \
  --constructor-args $(cast abi-encode "constructor(uint256)" 1000000000000000) \
  "$REGISTRY" \
  src/ClawMarkRegistry.sol:ClawMarkRegistry \
  --etherscan-api-key "$BASESCAN_API_KEY" \
  --watch

echo ""

# Verify ClawMarkCredentials
echo "2. Verifying ClawMarkCredentials..."
forge verify-contract \
  --chain-id 84532 \
  --compiler-version v0.8.19 \
  "$CREDENTIALS" \
  src/ClawMarkCredentials.sol:ClawMarkCredentials \
  --etherscan-api-key "$BASESCAN_API_KEY" \
  --watch

echo ""

# Verify ClawMarkReputation
echo "3. Verifying ClawMarkReputation..."
forge verify-contract \
  --chain-id 84532 \
  --compiler-version v0.8.19 \
  "$REPUTATION" \
  src/ClawMarkReputation.sol:ClawMarkReputation \
  --etherscan-api-key "$BASESCAN_API_KEY" \
  --watch

echo ""
echo "✅ All contracts verified!"
echo ""
echo "View on Basescan:"
echo "  Registry:    https://sepolia.basescan.org/address/$REGISTRY"
echo "  Credentials: https://sepolia.basescan.org/address/$CREDENTIALS"
echo "  Reputation:  https://sepolia.basescan.org/address/$REPUTATION"
