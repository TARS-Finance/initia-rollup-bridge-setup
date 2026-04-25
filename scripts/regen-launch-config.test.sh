#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/weave"

cat >"$TMP_DIR/.env" <<'EOF'
MERCHANT_INIT_ADDRESS=init1merchantdemoaddress0000000000000000000000
L1_CHAIN_ID=initiation-2
L1_RPC_URL=https://rpc.testnet.initia.xyz:443
L1_GAS_PRICES=0.015uinit
ROLLUP_CHAIN_ID=utars-chain-1
ROLLUP_NATIVE_DENOM=utars
EOF

cat >"$TMP_DIR/weave/system-keys.json" <<'EOF'
{
  "system_keys": {
    "validator": {
      "l1_address": "init1validator",
      "l2_address": "init1validator",
      "mnemonic": "validator mnemonic"
    },
    "bridge_executor": {
      "l1_address": "init1bridge",
      "l2_address": "init1bridge",
      "mnemonic": "bridge mnemonic"
    },
    "output_submitter": {
      "l1_address": "init1output",
      "l2_address": "init1output",
      "mnemonic": "output mnemonic"
    },
    "batch_submitter": {
      "da_address": "init1batch",
      "mnemonic": "batch mnemonic"
    },
    "challenger": {
      "l1_address": "init1challenger",
      "l2_address": "init1challenger",
      "mnemonic": "challenger mnemonic"
    }
  }
}
EOF

(
  cd "$TMP_DIR"
  ROOT_DIR="$TMP_DIR" bash "$ROOT/scripts/regen-launch-config.sh"
)

CONFIG="$TMP_DIR/weave/launch_config.json"
[ -f "$CONFIG" ]

jq -e '.l1_config.chain_id == "initiation-2"' "$CONFIG" >/dev/null
jq -e '.l2_config.chain_id == "utars-chain-1"' "$CONFIG" >/dev/null
jq -e '.l2_config.denom == "utars"' "$CONFIG" >/dev/null
jq -e '.genesis_accounts[0].address == "init1merchantdemoaddress0000000000000000000000"' "$CONFIG" >/dev/null
jq -e '.system_keys.validator.mnemonic == "validator mnemonic"' "$CONFIG" >/dev/null
jq -e '.system_keys.batch_submitter.da_address == "init1batch"' "$CONFIG" >/dev/null

echo "regen-launch-config test passed"
