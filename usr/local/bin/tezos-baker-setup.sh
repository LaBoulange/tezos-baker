#!/bin/bash

#############################################################################
# Tezos Baker Setup Wizard
# Interactive setup script for initial Tezos baker configuration
#############################################################################

set -e

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        read -p "$(echo -e ${CYAN}?${NC}) $prompt [${GREEN}$default${NC}]: " input
        eval "$var_name=\"${input:-$default}\""
    else
        read -p "$(echo -e ${CYAN}?${NC}) $prompt: " input
        eval "$var_name=\"$input\""
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local default="$2"
    
    if [ "$default" = "y" ]; then
        read -p "$(echo -e ${CYAN}?${NC}) $prompt [${GREEN}Y${NC}/n]: " answer
        answer=${answer:-y}
    else
        read -p "$(echo -e ${CYAN}?${NC}) $prompt [y/${GREEN}N${NC}]: " answer
        answer=${answer:-n}
    fi
    
    [[ "$answer" =~ ^[Yy]$ ]]
}

validate_tezos_address() {
    local addr="$1"
    local prefix="$2"
    
    if [[ ! "$addr" =~ ^${prefix}[1-9A-HJ-NP-Za-km-z]{33}$ ]]; then
        return 1
    fi
    return 0
}

validate_number() {
    local num="$1"
    local min="$2"
    local max="$3"
    
    if ! [[ "$num" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        return 1
    fi
    
    if [ -n "$min" ] && (( $(echo "$num < $min" | bc -l) )); then
        return 1
    fi
    
    if [ -n "$max" ] && (( $(echo "$num > $max" | bc -l) )); then
        return 1
    fi
    
    return 0
}

#############################################################################
# Main Setup Wizard
#############################################################################

clear
print_header "🥖 Tezos Baker Setup Wizard"

echo -e "${YELLOW}Welcome to the Tezos Baker Setup Wizard!${NC}"
echo ""
echo "This wizard will guide you through the initial configuration of your Tezos baker."
echo "You will be asked a series of questions to configure your environment."
echo ""
print_warning "Make sure you have read the README.md file before proceeding."
echo ""

# Check for existing installation
EXISTING_CONFIG=false
BACKUP_CREATED=false

if [ -f "/usr/local/bin/tezos-env.sh" ]; then
    EXISTING_CONFIG=true
    print_warning "Existing tezos-env.sh configuration detected!"
    echo ""
    echo "The wizard will:"
    echo "  1. Create a backup of your current configuration"
    echo "  2. Load your current values as defaults"
    echo "  3. Allow you to modify any settings"
    echo ""
    
    if ! prompt_yes_no "Do you want to continue?" "y"; then
        print_info "Setup cancelled. Your existing configuration is unchanged."
        exit 0
    fi
    
    # Create backup
    BACKUP_FILE="/usr/local/bin/tezos-env.sh.backup.$(date +%Y%m%d_%H%M%S)"
    cp /usr/local/bin/tezos-env.sh "$BACKUP_FILE"
    BACKUP_CREATED=true
    print_success "Backup created: $BACKUP_FILE"
    echo ""
    
    # Load existing configuration
    . /usr/local/bin/tezos-env.sh 2>/dev/null || true
fi

if ! prompt_yes_no "Are you ready to begin?" "y"; then
    print_info "Setup cancelled. Run this script again when you're ready."
    exit 0
fi

#############################################################################
# Step 1: Architecture and Directories
#############################################################################

print_header "Step 1/8: System Configuration"

print_info "Detecting system architecture..."
DETECTED_ARCH=$(uname -m)
case "$DETECTED_ARCH" in
    x86_64|amd64)
        DEFAULT_ARCH="x86_64"
        ;;
    aarch64|arm64)
        DEFAULT_ARCH="arm64"
        ;;
    *)
        DEFAULT_ARCH="x86_64"
        print_warning "Unknown architecture: $DETECTED_ARCH. Defaulting to x86_64"
        ;;
esac

# Use existing values as defaults if available
BAKER_ARCH=${BAKER_ARCH:-$DEFAULT_ARCH}
BUILD_DIR=${BUILD_DIR:-/tmp/build-tezos-baker}
INSTALL_DIR=${INSTALL_DIR:-/usr/local/bin}
DATA_DIR=${DATA_DIR:-/var/tezos}

prompt_input "Hardware architecture (x86_64 or arm64)" "$BAKER_ARCH" "BAKER_ARCH"
prompt_input "Build directory (temporary files)" "$BUILD_DIR" "BUILD_DIR"
prompt_input "Installation directory (executables)" "$INSTALL_DIR" "INSTALL_DIR"
prompt_input "Data directory (blockchain data, requires large storage)" "$DATA_DIR" "DATA_DIR"

#############################################################################
# Step 2: Network Configuration
#############################################################################

print_header "Step 2/8: Network Configuration"

echo "Available networks:"
echo "  1) mainnet (production network)"
echo "  2) ghostnet (test network)"
echo "  3) custom (specify your own)"
echo ""

while true; do
    read -p "$(echo -e ${CYAN}?${NC}) Select network [${GREEN}1${NC}]: " network_choice
    network_choice=${network_choice:-1}
    
    case "$network_choice" in
        1)
            NODE_NETWORK="mainnet"
            break
            ;;
        2)
            NODE_NETWORK="ghostnet"
            break
            ;;
        3)
            prompt_input "Enter custom network name" "" "NODE_NETWORK"
            break
            ;;
        *)
            print_error "Invalid choice. Please select 1, 2, or 3."
            ;;
    esac
done

print_success "Network: $NODE_NETWORK"

echo ""
echo "Node history mode:"
echo "  1) rolling (recommended, ~120GB)"
echo "  2) full (~500GB)"
echo "  3) rolling with extra cycles (e.g., rolling:10)"
echo ""

while true; do
    read -p "$(echo -e ${CYAN}?${NC}) Select history mode [${GREEN}1${NC}]: " mode_choice
    mode_choice=${mode_choice:-1}
    
    case "$mode_choice" in
        1)
            NODE_MODE="rolling"
            break
            ;;
        2)
            NODE_MODE="full"
            break
            ;;
        3)
            prompt_input "Enter number of extra cycles" "10" "extra_cycles"
            NODE_MODE="rolling:$extra_cycles"
            break
            ;;
        *)
            print_error "Invalid choice. Please select 1, 2, or 3."
            ;;
    esac
done

print_success "History mode: $NODE_MODE"

prompt_input "Snapshot URL (leave empty for default)" "https://snapshots.tzinit.org/${NODE_NETWORK}/${NODE_MODE%%:*}" "NODE_SNAPSHOT_URL"

#############################################################################
# Step 3: Baker Account Configuration
#############################################################################

print_header "Step 3/8: Baker Account Configuration"

# Use existing values as defaults if available
KEY_BAKER=${KEY_BAKER:-}
BAKER_ACCOUNT_HASH=${BAKER_ACCOUNT_HASH:-}

while true; do
    prompt_input "Baker account alias (local name, e.g., 'mybaker')" "$KEY_BAKER" "KEY_BAKER"
    if [ -n "$KEY_BAKER" ]; then
        break
    fi
    print_error "Baker alias cannot be empty."
done

while true; do
    prompt_input "Baker account address (tz1/tz2/tz3/tz4...)" "$BAKER_ACCOUNT_HASH" "BAKER_ACCOUNT_HASH"
    if validate_tezos_address "$BAKER_ACCOUNT_HASH" "tz"; then
        print_success "Valid Tezos address"
        break
    fi
    print_error "Invalid Tezos address. Must start with 'tz' followed by 33 characters."
done

#############################################################################
# Step 4: BLS/tz4 Configuration
#############################################################################

print_header "Step 4/8: BLS/tz4 Consensus Keys (Optional)"

echo "BLS/tz4 keys provide enhanced security for baking operations."
echo "You can configure this now or later using the maintenance CLI."
echo ""

if prompt_yes_no "Do you want to use BLS/tz4 consensus keys?" "n"; then
    USE_BLS_TZ4=true
    prompt_input "Consensus key alias" "consensus-tz4" "KEY_CONSENSUS_TZ4"
    prompt_input "DAL companion key alias" "dal-companion-tz4" "KEY_DAL_COMPANION_TZ4"
    print_info "You will need to import these keys manually after the setup."
else
    USE_BLS_TZ4=false
    KEY_CONSENSUS_TZ4="consensus-tz4"
    KEY_DAL_COMPANION_TZ4="dal-companion-tz4"
fi

#############################################################################
# Step 5: Staking Parameters
#############################################################################

print_header "Step 5/8: Staking Parameters"

echo "Configure your baker's staking parameters:"
echo ""

while true; do
    prompt_input "Limit of staking over baking (0-5, how many times your stake others can stake)" "5" "BAKER_LIMIT_STAKING_OVER_BAKING"
    if validate_number "$BAKER_LIMIT_STAKING_OVER_BAKING" "0" "5"; then
        break
    fi
    print_error "Must be a number between 0 and 5."
done

while true; do
    prompt_input "Edge of baking over staking (0-1, proportion of rewards from stakers, e.g., 0.1 = 10%)" "0.1" "BAKER_EDGE_BAKING_OVER_STAKING"
    if validate_number "$BAKER_EDGE_BAKING_OVER_STAKING" "0" "1"; then
        break
    fi
    print_error "Must be a number between 0 and 1."
done

echo ""
echo "Liquidity baking vote:"
echo "  1) pass (abstain)"
echo "  2) on (support)"
echo "  3) off (oppose)"
echo ""

while true; do
    read -p "$(echo -e ${CYAN}?${NC}) Select liquidity baking vote [${GREEN}1${NC}]: " lb_choice
    lb_choice=${lb_choice:-1}
    
    case "$lb_choice" in
        1)
            BAKER_LIQUIDITY_BAKING_SWITCH="pass"
            break
            ;;
        2)
            BAKER_LIQUIDITY_BAKING_SWITCH="on"
            break
            ;;
        3)
            BAKER_LIQUIDITY_BAKING_SWITCH="off"
            break
            ;;
        *)
            print_error "Invalid choice. Please select 1, 2, or 3."
            ;;
    esac
done

#############################################################################
# Step 6: TezPay Configuration (Optional)
#############################################################################

print_header "Step 6/8: TezPay Configuration (Optional)"

echo "TezPay allows you to automatically pay your delegators."
echo ""

if prompt_yes_no "Do you want to configure TezPay for delegator payments?" "n"; then
    SETUP_TEZPAY=true
    
    while true; do
        prompt_input "Payout account address (tz1/tz2/tz3...)" "" "TEZPAY_ACCOUNT_HASH"
        if validate_tezos_address "$TEZPAY_ACCOUNT_HASH" "tz"; then
            print_success "Valid Tezos address"
            break
        fi
        print_error "Invalid Tezos address."
    done
    
    while true; do
        prompt_input "Baking fee for delegators (0-1, e.g., 0.1 = 10%)" "0.1" "TEZPAY_FEES"
        if validate_number "$TEZPAY_FEES" "0" "1"; then
            break
        fi
        print_error "Must be a number between 0 and 1."
    done
    
    while true; do
        prompt_input "Payout interval in cycles (e.g., 1 = every cycle)" "1" "TEZPAY_INTERVAL"
        if validate_number "$TEZPAY_INTERVAL" "1" ""; then
            break
        fi
        print_error "Must be a positive integer."
    done
    
    KEY_PAYOUT="${KEY_BAKER}-payouts"
else
    SETUP_TEZPAY=false
    TEZPAY_ACCOUNT_HASH="tzYYYYYYYYYY: YOUR PAYOUTS ADDRESS HASH"
    TEZPAY_FEES=0.1
    TEZPAY_INTERVAL=1
    KEY_PAYOUT="${KEY_BAKER}-payouts"
fi

#############################################################################
# Step 7: Etherlink Smart Rollup Node (Optional)
#############################################################################

print_header "Step 7/8: Etherlink Smart Rollup Node (Optional)"

echo "You can run an Etherlink Smart Rollup observer node alongside your baker."
echo ""

if prompt_yes_no "Do you want to configure an Etherlink Smart Rollup observer node?" "n"; then
    SETUP_ETHERLINK=true
else
    SETUP_ETHERLINK=false
fi

#############################################################################
# Step 8: Review and Confirm
#############################################################################

print_header "Step 8/8: Review Configuration"

echo "Please review your configuration:"
echo ""
echo -e "${CYAN}System:${NC}"
echo "  Architecture: $BAKER_ARCH"
echo "  Build directory: $BUILD_DIR"
echo "  Install directory: $INSTALL_DIR"
echo "  Data directory: $DATA_DIR"
echo ""
echo -e "${CYAN}Network:${NC}"
echo "  Network: $NODE_NETWORK"
echo "  History mode: $NODE_MODE"
echo "  Snapshot URL: $NODE_SNAPSHOT_URL"
echo ""
echo -e "${CYAN}Baker:${NC}"
echo "  Alias: $KEY_BAKER"
echo "  Address: $BAKER_ACCOUNT_HASH"
echo "  BLS/tz4: $([ "$USE_BLS_TZ4" = true ] && echo 'Yes' || echo 'No')"
echo "  Staking limit: $BAKER_LIMIT_STAKING_OVER_BAKING"
echo "  Staking edge: $BAKER_EDGE_BAKING_OVER_STAKING"
echo "  Liquidity baking: $BAKER_LIQUIDITY_BAKING_SWITCH"
echo ""
echo -e "${CYAN}Optional Components:${NC}"
echo "  TezPay: $([ "$SETUP_TEZPAY" = true ] && echo "Yes (fee: $TEZPAY_FEES, interval: $TEZPAY_INTERVAL cycles)" || echo 'No')"
echo "  Etherlink: $([ "$SETUP_ETHERLINK" = true ] && echo 'Yes' || echo 'No')"
echo ""

if ! prompt_yes_no "Is this configuration correct?" "y"; then
    print_error "Setup cancelled. Please run the script again."
    exit 1
fi

#############################################################################
# Generate tezos-env.sh
#############################################################################

print_header "Generating Configuration File"

ENV_FILE="${INSTALL_DIR}/tezos-env.sh"

print_info "Creating $ENV_FILE..."

cat > "$ENV_FILE" << EOF
#!/bin/bash 

##################################
# Architecture
##################################

export BAKER_ARCH='$BAKER_ARCH'

##################################
# Internal - DO NOT EDIT
##################################

. \`which tezos-constants.sh\`

##################################
# Environment variables for octez
##################################

export ZCASH_DIR="\${HOME}/.zcash-params"
export BUILD_DIR='$BUILD_DIR'
export INSTALL_DIR="$INSTALL_DIR"
export DATA_DIR="$DATA_DIR"

export NODE_ETC_DIR="/usr/local/etc/octez-node"
export NODE_RUN_DIR="\${DATA_DIR}/octez-node"
export NODE_LOG_FILE="/var/log/octez-node.log"
export NODE_CONFIG_FILE="\${NODE_ETC_DIR}/config.json"
export NODE_RPC_ADDR="127.0.0.1:8732"
export NODE_NETWORK="$NODE_NETWORK"
export NODE_MODE="$NODE_MODE"
export NODE_SNAPSHOT_URL="$NODE_SNAPSHOT_URL"

export KEY_BAKER="$KEY_BAKER"
export KEY_CONSENSUS_TZ4="$KEY_CONSENSUS_TZ4"
export KEY_DAL_COMPANION_TZ4="$KEY_DAL_COMPANION_TZ4"
export KEY_PAYOUT="$KEY_PAYOUT"

export CLIENT_BASE_DIR="\${DATA_DIR}/octez-client"
export CLIENT_LOG_FILE="/var/log/octez-client.log"

export BAKER_ACCOUNT_HASH="$BAKER_ACCOUNT_HASH"
export BAKER_LOG_FILE="/var/log/octez-baker.log"
export BAKER_LIQUIDITY_BAKING_SWITCH="$BAKER_LIQUIDITY_BAKING_SWITCH"
export BAKER_LIMIT_STAKING_OVER_BAKING=$BAKER_LIMIT_STAKING_OVER_BAKING
export BAKER_EDGE_BAKING_OVER_STAKING=$BAKER_EDGE_BAKING_OVER_STAKING

export ACCUSER_LOG_FILE="/var/log/octez-accuser.log"

export DAL_RUN_DIR="\${DATA_DIR}/octez-dal-node"
export DAL_LOG_FILE="/var/log/octez-dal-node.log"
export DAL_ENDPOINT_ADDR="127.0.0.1:10732"

############################################################################################################
# Environment variables for TezPay (should you wish to pay your delegators, these can be ignored otherwise)
############################################################################################################

export TEZPAY_RUN_DIR="\${DATA_DIR}/tezpay"
export TEZPAY_INSTALL_SCRIPT="/tmp/install.sh"
export TEZPAY_ACCOUNT_HASH="$TEZPAY_ACCOUNT_HASH"
export TEZPAY_FEES=$TEZPAY_FEES
export TEZPAY_INTERVAL=$TEZPAY_INTERVAL
export TEZPAY_LOG_FILE="/var/log/tezpay.log"

######################################################################################################################
# Etherlink Smart Rollup node (should you wish to run an Etherlink Smart Rollup node, these can be ignored otherwise)
######################################################################################################################

export ETHERLINK_ROLLUP_ADDR=\$(eval echo '\$ETHERLINK_ROLLUP_ADDR_'\`echo \$NODE_NETWORK | tr '[:lower:]' '[:upper:]'\`)
export ETHERLINK_RUN_DIR="\${DATA_DIR}/octez-smart-rollup-node"
export ETHERLINK_IMAGES_ENDPOINT="https://snapshots.eu.tzinit.org/etherlink-\${NODE_NETWORK}"
export ETHERLINK_PREIMAGES="\${ETHERLINK_IMAGES_ENDPOINT}/wasm_2_0_0"
export ETHERLINK_SNAPSHOT="\${ETHERLINK_IMAGES_ENDPOINT}/eth-\${NODE_NETWORK}.full"
export ETHERLINK_RPC_ENDPOINT="https://rpc.tzkt.io/\${NODE_NETWORK}"
export ETHERLINK_RPC_ADDR="127.0.0.1:8932"
export ETHERLINK_NODE_LOG_FILE="/var/log/octez-smart-rollup-node.log"
EOF

chmod +x "$ENV_FILE"

print_success "Configuration file created: $ENV_FILE"

#############################################################################
# Execute Installation Steps
#############################################################################

print_header "Starting Installation"

# Source the environment
. "$ENV_FILE"

# Step 1: Setup ZCASH parameters
print_info "Setting up ZCASH parameters..."
mkdir -p "$ZCASH_DIR"
cd "$ZCASH_DIR"

for paramFile in 'sprout-groth16.params' 'sapling-output.params' 'sapling-spend.params'
do
    if [ ! -f "$paramFile" ]; then
        print_info "Downloading $paramFile..."
        wget -q "${ZCASH_DOWNLOAD_URL}/${paramFile}"
        chmod u+rw "$paramFile"
    else
        print_success "$paramFile already exists"
    fi
done

# Step 2: Install octez
print_info "Installing Octez..."
if [ -x "${INSTALL_DIR}/install-octez.sh" ]; then
    "${INSTALL_DIR}/install-octez.sh"
else
    print_error "install-octez.sh not found. Please ensure install-tezos-baker.sh was run first."
    exit 1
fi

# Step 3: Setup the RPC node
print_info "Setting up RPC node..."
mkdir -p "$DATA_DIR"
mkdir -p "$NODE_RUN_DIR"
mkdir -p "$NODE_ETC_DIR"

print_info "Initializing node configuration..."
octez-node config init --config-file="$NODE_CONFIG_FILE" --data-dir="$NODE_RUN_DIR" --network="$NODE_NETWORK" --history-mode="$NODE_MODE"
octez-node config update --config-file="$NODE_CONFIG_FILE" --data-dir="$NODE_RUN_DIR"

print_info "Downloading and importing snapshot (this may take a while)..."
cd /tmp
SNAPSHOT=$(basename "$NODE_SNAPSHOT_URL")
wget -q --show-progress "$NODE_SNAPSHOT_URL"
octez-node snapshot info "$SNAPSHOT"

print_warning "Importing snapshot in background. Check $NODE_LOG_FILE for progress."
nohup octez-node snapshot import "$SNAPSHOT" --no-check --config-file="$NODE_CONFIG_FILE" --data-dir="$NODE_RUN_DIR" &>"$NODE_LOG_FILE" &
rm "$SNAPSHOT"

print_info "Starting node..."
nohup octez-node run --config-file="$NODE_CONFIG_FILE" --rpc-addr "$NODE_RPC_ADDR" --log-output="$NODE_LOG_FILE" &>/dev/null &

chmod o-rwx "$NODE_RUN_DIR/identity.json"

# Step 4: Wait for node to bootstrap
print_info "Waiting for node to bootstrap (this may take several minutes)..."
mkdir -p "$CLIENT_BASE_DIR"
octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" bootstrapped

print_success "Node bootstrapped successfully!"

#############################################################################
# Manual Steps Required
#############################################################################

print_header "Manual Steps Required"

echo -e "${YELLOW}The automated setup is complete, but you need to perform the following manual steps:${NC}"
echo ""
echo -e "${CYAN}1. Import your baking key${NC}"
echo "   This depends on your key storage method (Ledger, remote signer, or local)."
echo "   Example for local key:"
echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} import secret key $KEY_BAKER <your_key>"
echo ""

if [ "$USE_BLS_TZ4" = true ]; then
    echo -e "${CYAN}2. Import your BLS/tz4 consensus and DAL companion keys${NC}"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} import secret key $KEY_CONSENSUS_TZ4 <your_consensus_key>"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} import secret key $KEY_DAL_COMPANION_TZ4 <your_dal_key>"
    echo "   See: https://docs.tezos.com/tutorials/join-dal-baker/prepare-account"
    echo ""
fi

if [ "$SETUP_TEZPAY" = true ]; then
    echo -e "${CYAN}3. Add your payout account public key${NC}"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} add address $KEY_PAYOUT $TEZPAY_ACCOUNT_HASH"
    echo ""
fi

echo -e "${CYAN}4. Register as delegate${NC}"
echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} register key $KEY_BAKER as delegate"
echo ""

if [ "$USE_BLS_TZ4" = true ]; then
    echo -e "${CYAN}5. Set consensus and companion keys${NC}"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} set consensus key for $KEY_BAKER to $KEY_CONSENSUS_TZ4"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} set companion key for $KEY_BAKER to $KEY_DAL_COMPANION_TZ4"
    echo ""
fi

echo -e "${CYAN}6. Initialize your stake${NC}"
echo "   Replace NNN with the amount of XTZ to stake (minimum 6000 for baking rights):"
echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} stake NNN for $KEY_BAKER"
echo ""

echo -e "${CYAN}7. Set delegate parameters${NC}"
echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} set delegate parameters for $KEY_BAKER --limit-of-staking-over-baking $BAKER_LIMIT_STAKING_OVER_BAKING --edge-of-baking-over-staking $BAKER_EDGE_BAKING_OVER_STAKING"
echo ""

echo -e "${CYAN}8. Start DAL node${NC}"
echo "   mkdir -p $DAL_RUN_DIR"
echo "   octez-dal-node config init --endpoint http://${NODE_RPC_ADDR} --attester-profiles=\"$BAKER_ACCOUNT_HASH\" --data-dir $DAL_RUN_DIR"
echo "   nohup octez-dal-node run &>$DAL_LOG_FILE &"
echo ""

echo -e "${CYAN}9. Start baker and accuser${NC}"
if [ "$USE_BLS_TZ4" = true ]; then
    echo "   nohup octez-baker --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_CONSENSUS_TZ4 $KEY_DAL_COMPANION_TZ4 $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH --dal-node http://${DAL_ENDPOINT_ADDR} &>$BAKER_LOG_FILE &"
else
    echo "   nohup octez-baker --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH --dal-node http://${DAL_ENDPOINT_ADDR} &>$BAKER_LOG_FILE &"
fi
echo "   nohup octez-accuser --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE &"
echo ""

if [ "$SETUP_ETHERLINK" = true ]; then
    echo -e "${CYAN}10. Setup Etherlink Smart Rollup node (optional)${NC}"
    echo "   See the Etherlink section in initial-setup.sh for detailed instructions."
    echo ""
fi

if [ "$SETUP_TEZPAY" = true ]; then
    echo -e "${CYAN}11. Setup TezPay (optional, only after you have endorsing rights)${NC}"
    echo "   See the TezPay section in initial-setup.sh for detailed instructions."
    echo ""
fi

print_header "Setup Complete!"

echo -e "${GREEN}The initial setup wizard has completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Complete the manual steps listed above"
echo "  2. Monitor your baker's logs: tail -f $BAKER_LOG_FILE"
echo "  3. Use 'tezos-baker' CLI for maintenance tasks"
echo ""
print_success "Happy baking! 🥖"
