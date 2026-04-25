#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${ROOT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ENV_FILE="$ROOT_DIR/.env"
SYSTEM_KEYS_FILE="$ROOT_DIR/weave/system-keys.json"
OUTPUT_FILE="$ROOT_DIR/weave/launch_config.json"

if [ ! -f "$ENV_FILE" ]; then
  echo "missing $ENV_FILE"
  exit 1
fi

if [ ! -f "$SYSTEM_KEYS_FILE" ]; then
  echo "missing $SYSTEM_KEYS_FILE"
  echo "generate it with: npx tsx scripts/generate-system-keys.ts"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

require_env() {
  local key="$1"
  if [ -z "${!key:-}" ]; then
    echo "missing $key in $ENV_FILE"
    exit 1
  fi
}

require_env "MERCHANT_INIT_ADDRESS"
require_env "L1_CHAIN_ID"
require_env "L1_RPC_URL"
require_env "L1_GAS_PRICES"

ROLLUP_CHAIN_ID="${ROLLUP_CHAIN_ID:-utars-chain-1}"
ROLLUP_NATIVE_DENOM="${ROLLUP_NATIVE_DENOM:-utars}"
ROLLUP_MONIKER="${ROLLUP_MONIKER:-utars-chain}"

mkdir -p "$(dirname "$OUTPUT_FILE")"

jq -n \
  --arg l1_chain_id "$L1_CHAIN_ID" \
  --arg l1_rpc_url "$L1_RPC_URL" \
  --arg l1_gas_prices "$L1_GAS_PRICES" \
  --arg l2_chain_id "$ROLLUP_CHAIN_ID" \
  --arg l2_denom "$ROLLUP_NATIVE_DENOM" \
  --arg l2_moniker "$ROLLUP_MONIKER" \
  --arg merchant_init_address "$MERCHANT_INIT_ADDRESS" \
  --slurpfile sys "$SYSTEM_KEYS_FILE" \
  '
  {
    l1_config: {
      chain_id: $l1_chain_id,
      rpc_url: $l1_rpc_url,
      gas_prices: $l1_gas_prices
    },
    l2_config: {
      chain_id: $l2_chain_id,
      denom: $l2_denom,
      moniker: $l2_moniker
    },
    op_bridge: {
      output_submission_interval: "1m",
      output_finalization_period: "5m",
      output_submission_start_height: 1,
      batch_submission_target: "INITIA",
      enable_oracle: false
    },
    system_keys: $sys[0].system_keys,
    genesis_accounts: [
      {
        address: $merchant_init_address,
        coins: ("100000000000000000000" + $l2_denom)
      }
    ]
  }
  ' >"$OUTPUT_FILE"

echo "wrote $OUTPUT_FILE"
