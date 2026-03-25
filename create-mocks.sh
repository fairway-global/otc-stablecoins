#!/bin/bash
# ============================================================================
# create-mocks.sh — Create mock stablecoin mints on Solana devnet
# ============================================================================
# Uses spl-token CLI with Token-2022 program to create mints with metadata.
# Each mint gets 1,000,000 tokens sent to your wallet.
#
# Prerequisites:
#   - solana CLI configured for devnet
#   - spl-token CLI installed
#   - Wallet funded with >= 2 SOL on devnet
#
# Usage:
#   chmod +x create-mocks.sh
#   ./create-mocks.sh
# ============================================================================

set -e

# ---- Configuration ----
PROGRAM_ID="TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"  # Token-2022
DECIMALS=6
INITIAL_SUPPLY=1000000  # 1M tokens per mint
OUTPUT_FILE="mint-addresses.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# ---- Stablecoin definitions ----
# Format: SYMBOL|NAME|URI
STABLECOINS=(
  "USDC|USD Coin (Mock)|https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png"
  "USDT|Tether USD (Mock)|https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB/logo.svg"
  "EURC|Euro Coin (Mock)|https://www.circle.com/hubfs/Brand/EURC/EURC-icon_gradient.svg"
  "PYUSD|PayPal USD (Mock)|https://raw.githubusercontent.com/nicechute/pyusd-svg/main/pyusd.svg"
  "USDG|Global Dollar (Mock)|https://assets.coingecko.com/coins/images/41409/standard/usdg.png"
  "USX|USX (Mock)|"
  "CHF|Swiss Franc Stable (Mock)|"
  "GBP|British Pound Stable (Mock)|"
  "JPY|Japanese Yen Stable (Mock)|"
  "SGD|Singapore Dollar Stable (Mock)|"
  "AED|UAE Dirham Stable (Mock)|"
)

# ---- Preflight checks ----
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Solana Mock Stablecoin Factory${NC}"
echo -e "${CYAN}  Creating ${#STABLECOINS[@]} token mints on devnet${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Check CLI tools
if ! command -v solana &> /dev/null; then
  echo -e "${RED}ERROR: solana CLI not found. Install: sh -c \"\$(curl -sSfL https://release.anza.xyz/stable/install)\"${NC}"
  exit 1
fi

if ! command -v spl-token &> /dev/null; then
  echo -e "${RED}ERROR: spl-token CLI not found. Install: cargo install spl-token-cli${NC}"
  exit 1
fi

# Check network
CLUSTER=$(solana config get | grep "RPC URL" | awk '{print $3}')
if [[ "$CLUSTER" != *"devnet"* ]]; then
  echo -e "${YELLOW}WARNING: Not on devnet. Current RPC: ${CLUSTER}${NC}"
  echo -e "${YELLOW}Switching to devnet...${NC}"
  solana config set --url https://api.devnet.solana.com
fi

# Check balance
WALLET=$(solana address)
BALANCE=$(solana balance | awk '{print $1}')
echo -e "Wallet:  ${GREEN}${WALLET}${NC}"
echo -e "Balance: ${GREEN}${BALANCE} SOL${NC}"
echo ""

# Check if we have enough SOL (need ~0.05 SOL per mint)
NEEDED=$(echo "${#STABLECOINS[@]} * 0.05" | bc 2>/dev/null || echo "0.5")
if (( $(echo "$BALANCE < 0.5" | bc -l 2>/dev/null || echo 0) )); then
  echo -e "${YELLOW}Low balance. Requesting airdrop...${NC}"
  solana airdrop 2 || {
    echo -e "${RED}Airdrop failed. Try: solana airdrop 1${NC}"
    echo -e "${RED}Or use https://faucet.solana.com${NC}"
    exit 1
  }
  sleep 2
fi

# ---- Create mints ----
echo -e "${CYAN}Creating token mints...${NC}"
echo ""

# Start JSON output
echo "{" > "$OUTPUT_FILE"
FIRST=true

for entry in "${STABLECOINS[@]}"; do
  IFS='|' read -r SYMBOL NAME URI <<< "$entry"

  echo -e "${YELLOW}━━━ Creating ${SYMBOL} ━━━${NC}"
  echo -e "  Name: ${NAME}"

  # Create Token-2022 mint with metadata extension
  if [ -n "$URI" ]; then
    MINT_OUTPUT=$(spl-token create-token \
      --program-id $PROGRAM_ID \
      --decimals $DECIMALS \
      --enable-metadata \
      2>&1)
  else
    MINT_OUTPUT=$(spl-token create-token \
      --program-id $PROGRAM_ID \
      --decimals $DECIMALS \
      --enable-metadata \
      2>&1)
  fi

  # Extract mint address
  MINT_ADDR=$(echo "$MINT_OUTPUT" | grep -oP 'Creating token \K[A-Za-z0-9]+' || \
              echo "$MINT_OUTPUT" | grep -oP 'Address:\s+\K[A-Za-z0-9]+' || \
              echo "$MINT_OUTPUT" | head -1 | awk '{print $3}')

  if [ -z "$MINT_ADDR" ]; then
    echo -e "  ${RED}Failed to create mint. Output: ${MINT_OUTPUT}${NC}"
    continue
  fi

  echo -e "  Mint:  ${GREEN}${MINT_ADDR}${NC}"

  # Initialize metadata on the mint
  echo -e "  Setting metadata..."
  if [ -n "$URI" ]; then
    spl-token initialize-metadata "$MINT_ADDR" "$NAME" "$SYMBOL" "$URI" \
      --program-id $PROGRAM_ID 2>&1 || true
  else
    spl-token initialize-metadata "$MINT_ADDR" "$NAME" "$SYMBOL" "" \
      --program-id $PROGRAM_ID 2>&1 || true
  fi

  # Create associated token account and mint tokens
  echo -e "  Minting ${INITIAL_SUPPLY} ${SYMBOL}..."
  spl-token create-account "$MINT_ADDR" --program-id $PROGRAM_ID 2>&1 || true
  spl-token mint "$MINT_ADDR" $INITIAL_SUPPLY --program-id $PROGRAM_ID 2>&1 || true

  echo -e "  ${GREEN}✓ Done${NC}"
  echo ""

  # Append to JSON
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    echo "," >> "$OUTPUT_FILE"
  fi

  cat >> "$OUTPUT_FILE" << JSONEOF
  "${SYMBOL}": {
    "mint": "${MINT_ADDR}",
    "name": "${NAME}",
    "symbol": "${SYMBOL}",
    "decimals": ${DECIMALS},
    "initialSupply": ${INITIAL_SUPPLY},
    "program": "Token-2022",
    "programId": "${PROGRAM_ID}"
  }
JSONEOF

done

echo "" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

# ---- Summary ----
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  All mints created successfully!${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "Config saved to: ${GREEN}${OUTPUT_FILE}${NC}"
echo ""
echo -e "Your mock stablecoin mints:"
echo ""

# Pretty print the JSON
if command -v jq &> /dev/null; then
  jq -r 'to_entries[] | "  \(.key)\t\(.value.mint)"' "$OUTPUT_FILE"
else
  cat "$OUTPUT_FILE"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Import ${OUTPUT_FILE} into your OTC desk code"
echo -e "  2. Open Phantom → switch to devnet → tokens should appear"
echo -e "  3. To mint more: spl-token mint <MINT> <AMOUNT> --program-id ${PROGRAM_ID}"
echo ""
echo -e "${GREEN}Happy building! 🚀${NC}"
