#!/bin/bash

#############################################################################
# Tezos Baker Setup Wizard
# Interactive setup script for initial Tezos baker configuration
# Smart update mode: only modifies what has changed
#############################################################################

set -e

# Parse command line arguments
DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
fi

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

#############################################################################
# Helper functions
#############################################################################

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
    local input
    
    if [ -n "$default" ]; then
        echo -ne "${CYAN}?${NC} $prompt [${GREEN}$default${NC}]: "
        read input
        if [ -z "$input" ]; then
            eval "$var_name=\"$default\""
        else
            eval "$var_name=\"$input\""
        fi
    else
        echo -ne "${CYAN}?${NC} $prompt: "
        read input
        eval "$var_name=\"$input\""
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local default="$2"
    
    if [ "$default" = "y" ]; then
        echo -ne "${CYAN}?${NC} $prompt [${GREEN}Y${NC}/n]: "
        read answer
        answer=${answer:-y}
    else
        echo -ne "${CYAN}?${NC} $prompt [y/${GREEN}N${NC}]: "
        read answer
        answer=${answer:-n}
    fi
    
    [[ "$answer" =~ ^[Yy]$ ]]
}

validate_tezos_address() {
    local addr="$1"
    local prefix="$2"
    
    # Tezos addresses: tz1/tz2/tz3/tz4/tz5 (33 chars after prefix)
    # Total length: 36 characters (tz + 1 digit + 33 base58 chars)
    if [[ ! "$addr" =~ ^${prefix}[1-5][1-9A-HJ-NP-Za-km-z]{33}$ ]]; then
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

check_service_running() {
    local service_name="$1"
    
    case "$service_name" in
        "octez-node")
            pgrep -f "octez-node run" > /dev/null 2>&1
            ;;
        "octez-baker")
            pgrep -f "octez-baker.*run" > /dev/null 2>&1
            ;;
        "octez-accuser")
            pgrep -f "octez-accuser.*run" > /dev/null 2>&1
            ;;
        "octez-dal-node")
            pgrep -f "octez-dal-node run" > /dev/null 2>&1
            ;;
        "tezpay")
            pgrep -f "tezpay continual" > /dev/null 2>&1
            ;;
        "etherlink")
            pgrep -f "octez-smart-rollup-node.*run" > /dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

compare_configs() {
    local old_file="$1"
    local new_file="$2"
    
    # Compare relevant configuration values (ignore comments and whitespace)
    diff -w -B \
        <(grep -v '^#' "$old_file" | grep -v '^$' | sort) \
        <(grep -v '^#' "$new_file" | grep -v '^$' | sort) \
        > /dev/null 2>&1
}

#############################################################################
# Dry-run wrappers
#############################################################################

dry_run_write_file() {
    local file="$1"
    local content="$2"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would write to: $file"
        echo -e "${MAGENTA}Content preview (first 30 lines):${NC}"
        echo "$content" | head -30
        if [ $(echo "$content" | wc -l) -gt 30 ]; then
            echo -e "${MAGENTA}... ($(echo "$content" | wc -l) total lines)${NC}"
        fi
        echo ""
    else
        echo "$content" > "$file"
    fi
}

dry_run_cp() {
    local src="$1"
    local dst="$2"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would copy: $src -> $dst"
    else
        cp "$src" "$dst"
    fi
}

dry_run_chmod() {
    local perms="$1"
    local file="$2"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would chmod $perms: $file"
    else
        chmod "$perms" "$file"
    fi
}

dry_run_mkdir() {
    local dir="$1"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would create directory: $dir"
    else
        mkdir -p "$dir"
    fi
}

dry_run_wget() {
    local url="$1"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would download: $url"
    else
        wget -q "$url"
    fi
}

dry_run_rm() {
    local file="$1"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would remove: $file"
    else
        rm "$file"
    fi
}

dry_run_exec_script() {
    local script="$1"
    shift
    local args="$@"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would execute: $script $args"
    else
        "$script" "$@"
    fi
}

dry_run_stop_services() {
    if [ "$DRY_RUN" = true ]; then
        print_warning "[DRY-RUN] Would stop all services:"
        [ "$TEZPAY_RUNNING" = true ] && echo "  - TezPay"
        [ "$ETHERLINK_RUNNING" = true ] && echo "  - Etherlink"
        [ "$DAL_RUNNING" = true ] && echo "  - DAL node"
        [ "$ACCUSER_RUNNING" = true ] && echo "  - Accuser"
        [ "$BAKER_RUNNING" = true ] && echo "  - Baker"
        [ "$NODE_RUNNING" = true ] && echo "  - Octez node"
    else
        if [ -x "$(which tezos-baker 2>/dev/null)" ]; then
            print_info "Stopping all services with tezos-baker CLI..."
            tezos-baker stop
        else
            print_info "Stopping services manually..."
            if [ -x "$(which stop-tezpay.sh 2>/dev/null)" ]; then
                stop-tezpay.sh 2>/dev/null || true
            fi
            if [ -x "$(which stop-etherlink.sh 2>/dev/null)" ]; then
                stop-etherlink.sh 2>/dev/null || true
            fi
            if [ -x "$(which stop-octez.sh 2>/dev/null)" ]; then
                stop-octez.sh
            fi
        fi
    fi
}

dry_run_start_node() {
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would start Octez node"
        print_info "[DRY-RUN] Would wait for node bootstrap"
    else
        nohup octez-node run --config-file="$NODE_CONFIG_FILE" --rpc-addr "$NODE_RPC_ADDR" --log-output="$NODE_LOG_FILE" &>/dev/null &
        print_info "Waiting for node to bootstrap (this may take several minutes)..."
        mkdir -p "$CLIENT_BASE_DIR"
        octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" bootstrapped
    fi
}

dry_run_octez_cmd() {
    local cmd="$1"
    shift
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would execute: $cmd $@"
    else
        "$cmd" "$@"
    fi
}

dry_run_cd() {
    local dir="$1"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would change directory to: $dir"
    else
        cd "$dir"
    fi
}

generate_tezpay_config() {
    cat << EOF
{
  tezpay_config_version: 0
  disable_analytics: false
  baker: "${BAKER_ACCOUNT_HASH}"
  payouts: {
    wallet_mode: local-private-key
    payout_mode: actual
    fee: 0.10
    baker_pays_transaction_fee: true
    baker_pays_allocation_fee: true
    minimum_payout_amount: 0.00
  }
  delegators: {
    requirements: {
      minimum_balance: 0
    }
    overrides: {
      ${TEZPAY_ACCOUNT_HASH}: {
        fee: 1.0
      }
    }
  }
  network: {
    rpc_pool: [
      http://${NODE_RPC_ADDR}/
      https://eu.rpc.tez.capital/
      https://us.rpc.tez.capital/
    ]
    tzkt_url: https://api.tzkt.io/
    protocol_rewards_url: https://protocol-rewards.tez.capital/
    explorer: https://tzkt.io/
    ignore_kt: false
  }
  overdelegation: {
    protect: true
  }
  extensions: [
  ]
}
EOF
}

#############################################################################
# Main Setup Wizard
#############################################################################

clear
print_header "🥖 Tezos Baker Setup Wizard"

echo -e "${YELLOW}Welcome to the Tezos Baker Setup Wizard!${NC}"
echo ""
echo "This wizard will guide you through the configuration of your Tezos baker."
echo "It uses smart update mode: only what has changed will be modified."
echo ""
print_warning "Make sure you have read the README.md file before proceeding."
echo ""

# Check for existing installation
EXISTING_CONFIG=false
BACKUP_CREATED=false
SERVICES_RUNNING=false
NODE_RUNNING=false
BAKER_RUNNING=false
ACCUSER_RUNNING=false
DAL_RUNNING=false
TEZPAY_RUNNING=false
ETHERLINK_RUNNING=false

# Variables to track what needs to be done
NEED_REINSTALL_OCTEZ=false
NEED_RECONFIG_NODE=false
NEED_REIMPORT_SNAPSHOT=false
NEED_RESTART_SERVICES=false

if [ -f "/usr/local/bin/tezos-env.sh" ]; then
    EXISTING_CONFIG=true
    print_warning "Existing tezos-env.sh configuration detected!"
    echo ""
    
    # Detect running services
    print_info "Detecting running services..."
    
    if check_service_running "octez-node"; then
        NODE_RUNNING=true
        SERVICES_RUNNING=true
        print_success "Octez node is running"
    else
        print_warning "Octez node is not running"
    fi
    
    if check_service_running "octez-baker"; then
        BAKER_RUNNING=true
        SERVICES_RUNNING=true
        print_success "Octez baker is running"
    else
        print_warning "Octez baker is not running"
    fi
    
    if check_service_running "octez-accuser"; then
        ACCUSER_RUNNING=true
        SERVICES_RUNNING=true
        print_success "Octez accuser is running"
    else
        print_warning "Octez accuser is not running"
    fi
    
    if check_service_running "octez-dal-node"; then
        DAL_RUNNING=true
        SERVICES_RUNNING=true
        print_success "Octez DAL node is running"
    else
        print_warning "Octez DAL node is not running"
    fi
    
    if check_service_running "tezpay"; then
        TEZPAY_RUNNING=true
        SERVICES_RUNNING=true
        print_success "TezPay is running"
    else
        print_warning "TezPay is not running"
    fi
    
    if check_service_running "etherlink"; then
        ETHERLINK_RUNNING=true
        SERVICES_RUNNING=true
        print_success "Etherlink is running"
    else
        print_warning "Etherlink is not running"
    fi
    
    if [ "$SERVICES_RUNNING" = false ]; then
        print_info "No services currently running"
    fi
    
    echo ""
    echo "The wizard will:"
    echo "  1. Create a backup of your current configuration"
    echo "  2. Load your current values as defaults"
    echo "  3. Allow you to modify any settings"
    echo "  4. Only update what has changed"
    echo "  5. Manage services intelligently (stop/restart only if needed)"
    echo ""
    
    if ! prompt_yes_no "Do you want to continue?" "y"; then
        print_info "Setup cancelled. Your existing configuration is unchanged."
        exit 0
    fi
    
    # Create backup
    BACKUP_FILE="/usr/local/bin/tezos-env.sh.backup.$(date +%Y%m%d_%H%M%S)"
    dry_run_cp /usr/local/bin/tezos-env.sh "$BACKUP_FILE"
    BACKUP_CREATED=true
    print_success "Backup created: $BACKUP_FILE"
    echo ""
    
    # Load existing configuration
    . /usr/local/bin/tezos-env.sh 2>/dev/null || true
    
    # Store old values for comparison
    OLD_NODE_NETWORK="$NODE_NETWORK"
    OLD_NODE_MODE="$NODE_MODE"
    OLD_BAKER_ARCH="$BAKER_ARCH"
    
    # Store old staking parameters
    OLD_BAKER_LIMIT="$BAKER_LIMIT_STAKING_OVER_BAKING"
    OLD_BAKER_EDGE="$BAKER_EDGE_BAKING_OVER_STAKING"
    
    # Store old liquidity baking vote
    OLD_BAKER_LB_SWITCH="$BAKER_LIQUIDITY_BAKING_SWITCH"
    
    # Store old TezPay parameters
    OLD_TEZPAY_ACCOUNT_HASH="$TEZPAY_ACCOUNT_HASH"
    OLD_TEZPAY_INTERVAL="$TEZPAY_INTERVAL"
    
    # Store old optional component states
    # Note: These will be set after user answers questions
    OLD_USE_BLS_TZ4=""
    OLD_SETUP_TEZPAY=""
    OLD_SETUP_ETHERLINK=""
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
echo "  2) tallinnnet (test network)"
echo "  3) custom (specify your own)"
echo ""

while true; do
    echo -ne "${CYAN}?${NC} Select network [${GREEN}1${NC}]: "
    read network_choice
    network_choice=${network_choice:-1}
    
    case "$network_choice" in
        1)
            NODE_NETWORK="mainnet"
            break
            ;;
        2)
            NODE_NETWORK="tallinnnet"
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
    echo -ne "${CYAN}?${NC} Select history mode [${GREEN}1${NC}]: "
    read mode_choice
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
    prompt_input "Baker account address (tz1/tz2/tz3/tz4)" "$BAKER_ACCOUNT_HASH" "BAKER_ACCOUNT_HASH"
    if validate_tezos_address "$BAKER_ACCOUNT_HASH" "tz"; then
        print_success "Valid Tezos address"
        break
    fi
    print_error "Invalid Tezos address. Must start with 'tz[1-4]' followed by 33 characters."
done

#############################################################################
# Step 4: BLS/tz4 Configuration
#############################################################################

print_header "Step 4/8: BLS/tz4 Consensus Keys (Optional)"

echo "BLS/tz4 keys provide enhanced security for baking operations."
echo "You can configure this now or later using the maintenance CLI."
echo ""

# Initialize KEY_CONSENSUS_TZ4 and KEY_DAL_COMPANION_TZ4 with values from config if they exist
KEY_CONSENSUS_TZ4=${KEY_CONSENSUS_TZ4:-consensus-tz4}
KEY_DAL_COMPANION_TZ4=${KEY_DAL_COMPANION_TZ4:-dal-companion-tz4}

# Store old BLS/tz4 state if existing config
if [ "$EXISTING_CONFIG" = true ]; then
    # Try to detect if BLS/tz4 was used before by checking if consensus key exists
    if octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" list known addresses 2>/dev/null | grep -q "^${KEY_CONSENSUS_TZ4}:"; then
        OLD_USE_BLS_TZ4=true
        # Display the existing consensus key address
        CONSENSUS_ADDR=$(octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" show address "$KEY_CONSENSUS_TZ4" 2>/dev/null | grep '^Hash' | awk '{print $2}')
        if [ -n "$CONSENSUS_ADDR" ]; then
            print_info "Existing consensus key '$KEY_CONSENSUS_TZ4': $CONSENSUS_ADDR"
        fi
        
        # Also display DAL companion key if it exists
        if octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" list known addresses 2>/dev/null | grep -q "^${KEY_DAL_COMPANION_TZ4}:"; then
            DAL_ADDR=$(octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" show address "$KEY_DAL_COMPANION_TZ4" 2>/dev/null | grep '^Hash' | awk '{print $2}')
            if [ -n "$DAL_ADDR" ]; then
                print_info "Existing DAL companion key '$KEY_DAL_COMPANION_TZ4': $DAL_ADDR"
            fi
        fi
    else
        OLD_USE_BLS_TZ4=false
    fi
fi

if prompt_yes_no "Do you want to use BLS/tz4 consensus keys?" "y"; then
    USE_BLS_TZ4=true
    prompt_input "Consensus key alias" "$KEY_CONSENSUS_TZ4" "KEY_CONSENSUS_TZ4"
    prompt_input "DAL companion key alias" "$KEY_DAL_COMPANION_TZ4" "KEY_DAL_COMPANION_TZ4"
    print_info "If not already done, you will need to import these keys manually after the setup."
else
    USE_BLS_TZ4=false
fi

# Detect BLS/tz4 configuration change
if [ "$EXISTING_CONFIG" = true ] && [ "$OLD_USE_BLS_TZ4" != "$USE_BLS_TZ4" ]; then
    NEED_RESTART_SERVICES=true
    if [ "$USE_BLS_TZ4" = true ]; then
        print_warning "BLS/tz4 enabled - baker restart will be required after key import"
    else
        print_warning "BLS/tz4 disabled - baker restart will be required"
    fi
fi


#############################################################################
# Step 5: Staking Parameters
#############################################################################

print_header "Step 5/8: Staking Parameters"

echo "Configure your baker's staking parameters:"
echo ""

while true; do
    prompt_input "Limit of staking over baking (0-9, how many times your stake others can stake)" "$BAKER_LIMIT_STAKING_OVER_BAKING" "BAKER_LIMIT_STAKING_OVER_BAKING"
    if validate_number "$BAKER_LIMIT_STAKING_OVER_BAKING" "0" "9"; then
        break
    fi
    print_error "Must be a number between 0 and 9."
done

while true; do
    prompt_input "Edge of baking over staking (0-1, proportion of rewards from stakers, e.g., 0.1 = 10%)" "$BAKER_EDGE_BAKING_OVER_STAKING" "BAKER_EDGE_BAKING_OVER_STAKING"
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
    echo -ne "${CYAN}?${NC} Select liquidity baking vote [${GREEN}1${NC}]: "
    read lb_choice
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

# Detect liquidity baking vote change
if [ "$EXISTING_CONFIG" = true ] && [ -n "$OLD_BAKER_LB_SWITCH" ]; then
    if [ "$OLD_BAKER_LB_SWITCH" != "$BAKER_LIQUIDITY_BAKING_SWITCH" ]; then
        NEED_RESTART_SERVICES=true
        print_warning "Liquidity baking vote changed - baker restart will be required"
    fi
fi


#############################################################################
# Step 6: TezPay Configuration (Optional)
#############################################################################

print_header "Step 6/8: TezPay Configuration (Optional)"

echo "TezPay allows you to automatically pay your delegators."
echo ""

RESTART_TEZPAY=false
if prompt_yes_no "Do you want to use TezPay for delegator payments?" "y"; then
    SETUP_TEZPAY=true
    
    # Use existing values as defaults if available
    TEZPAY_ACCOUNT_HASH=${TEZPAY_ACCOUNT_HASH:-}
    TEZPAY_INTERVAL=${TEZPAY_INTERVAL:-1}
    
    while true; do
        prompt_input "Payout account address (tz1/tz2/tz3/tz4...)" "$TEZPAY_ACCOUNT_HASH" "TEZPAY_ACCOUNT_HASH"
        if validate_tezos_address "$TEZPAY_ACCOUNT_HASH" "tz"; then
            print_success "Valid Tezos address"
            break
        fi
        print_error "Invalid Tezos address."
    done
    
    while true; do
        prompt_input "Payout interval in cycles (e.g., 1 = every cycle)" "$TEZPAY_INTERVAL" "TEZPAY_INTERVAL"
        if validate_number "$TEZPAY_INTERVAL" "1" ""; then
            break
        fi
        print_error "Must be a positive integer."
    done
    
    KEY_PAYOUT="${KEY_BAKER}-payouts"
    
    # Detect TezPay parameter changes
    if [ "$EXISTING_CONFIG" = true ] && [ -n "$OLD_TEZPAY_INTERVAL" ]; then
        if [ "$OLD_TEZPAY_INTERVAL" != "$TEZPAY_INTERVAL" ]; then
            print_warning "TezPay parameters changed - restart will be required"
            RESTART_TEZPAY=true
        fi
    fi
else
    SETUP_TEZPAY=false
    TEZPAY_ACCOUNT_HASH="tzYYYYYYYYYY: YOUR PAYOUTS ADDRESS HASH"
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
echo "  TezPay: $([ "$SETUP_TEZPAY" = true ] && echo "Yes (interval: $TEZPAY_INTERVAL cycles)" || echo 'No')"
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

ENV_CONTENT=$(cat << 'EOF'
#!/bin/bash 

##################################
# Architecture
##################################

export BAKER_ARCH='BAKER_ARCH_PLACEHOLDER'

##################################
# Internal - DO NOT EDIT
##################################

. `which tezos-constants.sh`

##################################
# Environment variables for octez
##################################

export ZCASH_DIR="${HOME}/.zcash-params"
export BUILD_DIR='BUILD_DIR_PLACEHOLDER'
export INSTALL_DIR="INSTALL_DIR_PLACEHOLDER"
export DATA_DIR="DATA_DIR_PLACEHOLDER"

export NODE_ETC_DIR="/usr/local/etc/octez-node"
export NODE_RUN_DIR="${DATA_DIR}/octez-node"
export NODE_LOG_FILE="/var/log/octez-node.log"
export NODE_CONFIG_FILE="${NODE_ETC_DIR}/config.json"
export NODE_RPC_ADDR="127.0.0.1:8732"
export NODE_NETWORK="NODE_NETWORK_PLACEHOLDER"
export NODE_MODE="NODE_MODE_PLACEHOLDER"
export NODE_SNAPSHOT_URL="NODE_SNAPSHOT_URL_PLACEHOLDER"

export KEY_BAKER="KEY_BAKER_PLACEHOLDER"
export KEY_CONSENSUS_TZ4="KEY_CONSENSUS_TZ4_PLACEHOLDER"
export KEY_DAL_COMPANION_TZ4="KEY_DAL_COMPANION_TZ4_PLACEHOLDER"
export KEY_PAYOUT="KEY_PAYOUT_PLACEHOLDER"

export CLIENT_BASE_DIR="${DATA_DIR}/octez-client"
export CLIENT_LOG_FILE="/var/log/octez-client.log"

export BAKER_ACCOUNT_HASH="BAKER_ACCOUNT_HASH_PLACEHOLDER"
export BAKER_LOG_FILE="/var/log/octez-baker.log"
export BAKER_LIQUIDITY_BAKING_SWITCH="BAKER_LIQUIDITY_BAKING_SWITCH_PLACEHOLDER"
export BAKER_LIMIT_STAKING_OVER_BAKING=BAKER_LIMIT_STAKING_OVER_BAKING_PLACEHOLDER
export BAKER_EDGE_BAKING_OVER_STAKING=BAKER_EDGE_BAKING_OVER_STAKING_PLACEHOLDER

export ACCUSER_LOG_FILE="/var/log/octez-accuser.log"

export DAL_RUN_DIR="${DATA_DIR}/octez-dal-node"
export DAL_LOG_FILE="/var/log/octez-dal-node.log"
export DAL_ENDPOINT_ADDR="127.0.0.1:10732"

############################################################################################################
# Environment variables for TezPay (should you wish to pay your delegators, these can be ignored otherwise)
############################################################################################################

export TEZPAY_RUN_DIR="${DATA_DIR}/tezpay"
export TEZPAY_INSTALL_SCRIPT="/tmp/install.sh"
export TEZPAY_ACCOUNT_HASH="TEZPAY_ACCOUNT_HASH_PLACEHOLDER"
export TEZPAY_INTERVAL=TEZPAY_INTERVAL_PLACEHOLDER
export TEZPAY_LOG_FILE="/var/log/tezpay.log"

######################################################################################################################
# Etherlink Smart Rollup node (should you wish to run an Etherlink Smart Rollup node, these can be ignored otherwise)
######################################################################################################################

export ETHERLINK_ROLLUP_ADDR=$(eval echo '$ETHERLINK_ROLLUP_ADDR_'`echo $NODE_NETWORK | tr '[:lower:]' '[:upper:]'`)
export ETHERLINK_RUN_DIR="${DATA_DIR}/octez-smart-rollup-node"
export ETHERLINK_IMAGES_ENDPOINT="https://snapshots.eu.tzinit.org/etherlink-${NODE_NETWORK}"
export ETHERLINK_PREIMAGES="${ETHERLINK_IMAGES_ENDPOINT}/wasm_2_0_0"
export ETHERLINK_SNAPSHOT="${ETHERLINK_IMAGES_ENDPOINT}/eth-${NODE_NETWORK}.full"
export ETHERLINK_RPC_ENDPOINT="https://rpc.tzkt.io/${NODE_NETWORK}"
export ETHERLINK_RPC_ADDR="127.0.0.1:8932"
export ETHERLINK_NODE_LOG_FILE="/var/log/octez-smart-rollup-node.log"
EOF
)

# Replace placeholders with actual values
ENV_CONTENT="${ENV_CONTENT//BAKER_ARCH_PLACEHOLDER/$BAKER_ARCH}"
ENV_CONTENT="${ENV_CONTENT//BUILD_DIR_PLACEHOLDER/$BUILD_DIR}"
ENV_CONTENT="${ENV_CONTENT//INSTALL_DIR_PLACEHOLDER/$INSTALL_DIR}"
ENV_CONTENT="${ENV_CONTENT//DATA_DIR_PLACEHOLDER/$DATA_DIR}"
ENV_CONTENT="${ENV_CONTENT//NODE_NETWORK_PLACEHOLDER/$NODE_NETWORK}"
ENV_CONTENT="${ENV_CONTENT//NODE_MODE_PLACEHOLDER/$NODE_MODE}"
ENV_CONTENT="${ENV_CONTENT//NODE_SNAPSHOT_URL_PLACEHOLDER/$NODE_SNAPSHOT_URL}"
ENV_CONTENT="${ENV_CONTENT//KEY_BAKER_PLACEHOLDER/$KEY_BAKER}"
ENV_CONTENT="${ENV_CONTENT//KEY_CONSENSUS_TZ4_PLACEHOLDER/$KEY_CONSENSUS_TZ4}"
ENV_CONTENT="${ENV_CONTENT//KEY_DAL_COMPANION_TZ4_PLACEHOLDER/$KEY_DAL_COMPANION_TZ4}"
ENV_CONTENT="${ENV_CONTENT//KEY_PAYOUT_PLACEHOLDER/$KEY_PAYOUT}"
ENV_CONTENT="${ENV_CONTENT//BAKER_ACCOUNT_HASH_PLACEHOLDER/$BAKER_ACCOUNT_HASH}"
ENV_CONTENT="${ENV_CONTENT//BAKER_LIQUIDITY_BAKING_SWITCH_PLACEHOLDER/$BAKER_LIQUIDITY_BAKING_SWITCH}"
ENV_CONTENT="${ENV_CONTENT//BAKER_LIMIT_STAKING_OVER_BAKING_PLACEHOLDER/$BAKER_LIMIT_STAKING_OVER_BAKING}"
ENV_CONTENT="${ENV_CONTENT//BAKER_EDGE_BAKING_OVER_STAKING_PLACEHOLDER/$BAKER_EDGE_BAKING_OVER_STAKING}"
ENV_CONTENT="${ENV_CONTENT//TEZPAY_ACCOUNT_HASH_PLACEHOLDER/$TEZPAY_ACCOUNT_HASH}"
ENV_CONTENT="${ENV_CONTENT//TEZPAY_INTERVAL_PLACEHOLDER/$TEZPAY_INTERVAL}"

dry_run_write_file "$ENV_FILE" "$ENV_CONTENT"
dry_run_chmod +x "$ENV_FILE"

print_success "Configuration file created: $ENV_FILE"

#############################################################################
# Execute Installation Steps (Smart Update Mode)
#############################################################################

print_header "Smart Installation"

# Source the environment
. "$ENV_FILE"

# Detect what needs to be done
if [ "$EXISTING_CONFIG" = true ]; then
    print_info "Analyzing configuration changes..."
    
    # Check for critical changes
    if [ "$OLD_NODE_NETWORK" != "$NODE_NETWORK" ] || [ "$OLD_NODE_MODE" != "$NODE_MODE" ]; then
        NEED_REIMPORT_SNAPSHOT=true
        NEED_RESTART_SERVICES=true
        print_warning "Network or history mode changed - snapshot reimport required"
    fi
    
    if [ "$OLD_BAKER_ARCH" != "$BAKER_ARCH" ]; then
        NEED_REINSTALL_OCTEZ=true
        NEED_RESTART_SERVICES=true
        print_warning "Architecture changed - Octez reinstall required"
    fi
    
    # Check if node directory exists
    if [ ! -d "$NODE_RUN_DIR" ] || [ ! -f "$NODE_RUN_DIR/identity.json" ]; then
        NEED_REIMPORT_SNAPSHOT=true
        print_info "Node not initialized - full setup required"
    fi
fi

# Stop services if necessary
if [ "$NEED_RESTART_SERVICES" = true ] && [ "$SERVICES_RUNNING" = true ]; then
    print_warning "Configuration changes require stopping all services"
    dry_run_stop_services
    
    if [ "$DRY_RUN" = false ]; then
        print_success "All services stopped"
        
        # Update service status
        SERVICES_RUNNING=false
        NODE_RUNNING=false
        BAKER_RUNNING=false
        ACCUSER_RUNNING=false
        DAL_RUNNING=false
        TEZPAY_RUNNING=false
        ETHERLINK_RUNNING=false
    fi
fi

# Step 1: Setup ZCASH parameters (only if not all present)
ZCASH_COMPLETE=true
for paramFile in 'sprout-groth16.params' 'sapling-output.params' 'sapling-spend.params'
do
    if [ ! -f "$ZCASH_DIR/$paramFile" ]; then
        ZCASH_COMPLETE=false
        break
    fi
done

if [ "$ZCASH_COMPLETE" = false ]; then
    print_info "Setting up ZCASH parameters..."
    dry_run_mkdir "$ZCASH_DIR"
    dry_run_cd "$ZCASH_DIR"
    
    for paramFile in 'sprout-groth16.params' 'sapling-output.params' 'sapling-spend.params'
    do
        if [ ! -f "$paramFile" ]; then
            print_info "Downloading $paramFile..."
            dry_run_wget "${ZCASH_DOWNLOAD_URL}/${paramFile}"
            dry_run_chmod u+rw "$paramFile"
        else
            print_success "$paramFile already exists"
        fi
    done
else
    print_success "ZCASH parameters already configured, skipping"
fi

# Step 2: Install Octez only if necessary
if [ "$NEED_REINSTALL_OCTEZ" = true ] || [ ! -x "$(which octez-node 2>/dev/null)" ]; then
    print_info "Installing Octez..."
    if [ -x "${INSTALL_DIR}/install-octez.sh" ]; then
        dry_run_exec_script "${INSTALL_DIR}/install-octez.sh"
    else
        print_error "install-octez.sh not found. Please ensure install-tezos-baker.sh was run first."
        exit 1
    fi
else
    print_success "Octez already installed, skipping"
fi

# Step 3: Setup node only if necessary
if [ "$NEED_REIMPORT_SNAPSHOT" = true ]; then
    print_info "Setting up RPC node..."
    
    # Wipe existing node data if it exists (required when changing network or history mode)
    if [ -d "$NODE_RUN_DIR" ]; then
        print_warning "Wiping existing node data directory: $NODE_RUN_DIR"
        if [ "$DRY_RUN" = true ]; then
            print_info "[DRY-RUN] Would remove directory: $NODE_RUN_DIR"
        else
            rm -rf "$NODE_RUN_DIR"
        fi
    fi
    
    dry_run_mkdir "$DATA_DIR"
    dry_run_mkdir "$NODE_RUN_DIR"
    dry_run_mkdir "$NODE_ETC_DIR"
    
    print_info "Initializing node configuration..."
    dry_run_octez_cmd octez-node config init --config-file="$NODE_CONFIG_FILE" --data-dir="$NODE_RUN_DIR" --network="$NODE_NETWORK" --history-mode="$NODE_MODE"
    dry_run_octez_cmd octez-node config update --config-file="$NODE_CONFIG_FILE" --data-dir="$NODE_RUN_DIR"
    
    print_info "Downloading snapshot..."
    dry_run_cd /tmp
    SNAPSHOT=$(basename "$NODE_SNAPSHOT_URL")
    dry_run_wget "$NODE_SNAPSHOT_URL"
    dry_run_octez_cmd octez-node snapshot info "$SNAPSHOT"
    
    print_info "Importing snapshot (this will take several minutes, please wait)..."
    dry_run_octez_cmd octez-node snapshot import "$SNAPSHOT" --no-check --config-file="$NODE_CONFIG_FILE" --data-dir="$NODE_RUN_DIR"
    dry_run_rm "$SNAPSHOT"
    
    print_success "Snapshot imported successfully!"
    
    dry_run_chmod o-rwx "$NODE_RUN_DIR/identity.json"
else
    print_success "Node already configured, skipping snapshot import"
fi

# Step 4: Start node only if not already running
if ! check_service_running "octez-node"; then
    dry_run_start_node
    print_success "Node bootstrapped successfully!"
else
    print_success "Node already running"
fi

#############################################################################
# Detect existing configuration state
#############################################################################

print_header "Analyzing Existing Configuration"

# Check if baker key is already imported
BAKER_KEY_EXISTS=false
if octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" list known addresses 2>/dev/null | grep -q "^${KEY_BAKER}:"; then
    BAKER_KEY_EXISTS=true
    print_success "Baker key '$KEY_BAKER' already imported"
fi

# Check if BLS/tz4 keys are already imported
CONSENSUS_KEY_EXISTS=false
DAL_KEY_EXISTS=false
if [ "$USE_BLS_TZ4" = true ]; then
    if octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" list known addresses 2>/dev/null | grep -q "^${KEY_CONSENSUS_TZ4}:"; then
        CONSENSUS_KEY_EXISTS=true
        print_success "Consensus key '$KEY_CONSENSUS_TZ4' already imported"
    fi
    if octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" list known addresses 2>/dev/null | grep -q "^${KEY_DAL_COMPANION_TZ4}:"; then
        DAL_KEY_EXISTS=true
        print_success "DAL companion key '$KEY_DAL_COMPANION_TZ4' already imported"
    fi
fi

# Check if payout key is already added
PAYOUT_KEY_EXISTS=false
if [ "$SETUP_TEZPAY" = true ]; then
    if octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" list known addresses 2>/dev/null | grep -q "^${KEY_PAYOUT}:"; then
        PAYOUT_KEY_EXISTS=true
        print_success "Payout key '$KEY_PAYOUT' already added"
    fi
fi

# Check if baker is already registered
BAKER_REGISTERED=false
BAKER_HASH=$(octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" show address "$KEY_BAKER" 2>/dev/null | grep '^Hash' | awk '{print $2}')
if [ -n "$BAKER_HASH" ]; then
    if octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" rpc get "/chains/main/blocks/head/context/delegates/${BAKER_HASH}" 2>/dev/null | grep -q "deactivated"; then
        BAKER_REGISTERED=true
        print_success "Baker already registered as delegate"
    fi
fi

# Check if BLS/tz4 is already configured
BLS_CONFIGURED=false
if [ "$USE_BLS_TZ4" = true ] && [ -n "$BAKER_HASH" ]; then
    CONSENSUS_KEY_HASH=$(octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" rpc get "/chains/main/blocks/head/context/delegates/${BAKER_HASH}/consensus_key" 2>/dev/null | grep -o 'tz4[1-9A-HJ-NP-Za-km-z]\{33\}')
    if [ -n "$CONSENSUS_KEY_HASH" ]; then
        BLS_CONFIGURED=true
        print_success "BLS/tz4 consensus key already configured"
    fi
fi

# Check if DAL node is already configured
DAL_CONFIGURED=false
if [ -f "$DAL_RUN_DIR/config.json" ]; then
    DAL_CONFIGURED=true
    print_success "DAL node already configured"
fi

# Check if TezPay is already configured
TEZPAY_CONFIGURED=false
if [ "$SETUP_TEZPAY" = true ]; then
    if [ -f "$TEZPAY_RUN_DIR/config.hjson" ] && ([ -f "$TEZPAY_RUN_DIR/payout_wallet_private.key" ] || [ -f "$TEZPAY_RUN_DIR/remote_signer.hjson" ]); then
        TEZPAY_CONFIGURED=true
        print_success "TezPay already configured"
    fi
fi

# Check if Etherlink is already configured
ETHERLINK_CONFIGURED=false
if [ "$SETUP_ETHERLINK" = true ]; then
    if [ -f "$ETHERLINK_RUN_DIR/config.json" ]; then
        ETHERLINK_CONFIGURED=true
        print_success "Etherlink already configured"
    fi
fi

#############################################################################
# Manual Steps Required
#############################################################################

print_header "Configuration Steps"

echo -e "${YELLOW}Please complete the following configuration steps:${NC}"
echo ""

# Step counter
STEP=1

# Import baker key if needed
if [ "$BAKER_KEY_EXISTS" = false ]; then
    echo -e "${CYAN}${STEP}. Import your baking key${NC}"
    echo "   This depends on your key storage method (Ledger, remote signer, or local)."
    echo "   Please refer to https://docs.tezos.com/tutorials/join-dal-baker/prepare-account"
    echo "   and https://docs.tezos.com/tutorials/bake-with-ledger/install-app for more details."
    echo ""
    echo "   Example for local key (not recommended for production):"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} import secret key $KEY_BAKER <your_key>"
    echo ""
    STEP=$((STEP + 1))
fi

# Import BLS/tz4 keys if needed
if [ "$USE_BLS_TZ4" = true ]; then
    if [ "$CONSENSUS_KEY_EXISTS" = false ] || [ "$DAL_KEY_EXISTS" = false ]; then
        echo -e "${CYAN}${STEP}. Import your BLS/tz4 consensus and DAL companion keys${NC}"
        if [ "$CONSENSUS_KEY_EXISTS" = false ]; then
            echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} import secret key $KEY_CONSENSUS_TZ4 <your_consensus_key>"
        fi
        if [ "$DAL_KEY_EXISTS" = false ]; then
            echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} import secret key $KEY_DAL_COMPANION_TZ4 <your_dal_key>"
        fi
        echo ""
        STEP=$((STEP + 1))
    fi
fi

# Add payout key if needed
if [ "$SETUP_TEZPAY" = true ] && [ "$PAYOUT_KEY_EXISTS" = false ]; then
    echo -e "${CYAN}${STEP}. Add your payout account public key${NC}"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} add address $KEY_PAYOUT $TEZPAY_ACCOUNT_HASH"
    echo ""
    STEP=$((STEP + 1))
fi

# Register as delegate if needed
if [ "$BAKER_REGISTERED" = false ]; then
    echo -e "${CYAN}${STEP}. Register as delegate${NC}"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} register key $KEY_BAKER as delegate"
    echo ""
    echo "   After registration, verify on tzkt.io/${BAKER_ACCOUNT_HASH} under 'Delegations'"
    echo ""
    STEP=$((STEP + 1))
fi

# Enable BLS/tz4 if needed
if [ "$USE_BLS_TZ4" = true ] && [ "$BLS_CONFIGURED" = false ]; then
    echo -e "${CYAN}${STEP}. Enable BLS/tz4 baking${NC}"
    echo "   Use the CLI to set consensus and companion keys:"
    echo "   ${GREEN}tezos-baker enable-bls${NC}"
    echo ""
    echo "   This will:"
    echo "   - Set consensus key for $KEY_BAKER to $KEY_CONSENSUS_TZ4"
    echo "   - Set companion key for $KEY_BAKER to $KEY_DAL_COMPANION_TZ4"
    echo "   - Verify the registration"
    echo ""
    STEP=$((STEP + 1))
fi

# Initialize stake (only if current stake is below 6000 XTZ)
CURRENT_STAKE=0
if [ -n "$BAKER_HASH" ]; then
    # Try to get current staked balance
    STAKE_OUTPUT=$(octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" get staked balance for "$BAKER_ACCOUNT_HASH" 2>/dev/null | grep "ꜩ" || echo "0 ꜩ")
    CURRENT_STAKE=$(echo "$STAKE_OUTPUT" | grep -o '[0-9.]*' | head -1)
    
    # Default to 0 if empty
    CURRENT_STAKE=${CURRENT_STAKE:-0}
fi

# Only show stake initialization step if stake is below 6000 XTZ
if (( $(echo "$CURRENT_STAKE < 6000" | bc -l) )); then
    echo -e "${CYAN}${STEP}. Ensure your stake is sufficient${NC}"
    echo "   Current own stake: ${CURRENT_STAKE} ꜩ"
    echo "   Check your current external stake on tzkt.io/${BAKER_ACCOUNT_HASH}"
    echo ""
    echo "   If you need to add more stake using the CLI:"
    echo "   ${GREEN}tezos-baker stake increase <amount>${NC}"
    echo ""
    echo "   Example: tezos-baker stake increase 6000"
    echo "   (The minimum is 6000 XTZ for baking rights, including external staking)"
    echo ""
    STEP=$((STEP + 1))
else
    print_success "Own stake is already sufficient: ${CURRENT_STAKE} ꜩ"
fi

# Configure DAL if needed
if [ "$DAL_CONFIGURED" = false ]; then
    echo -e "${CYAN}${STEP}. Configure DAL node${NC}"
    echo "   mkdir -p $DAL_RUN_DIR"
    echo "   octez-dal-node config init --endpoint http://${NODE_RPC_ADDR} --attester-profiles=\"$BAKER_ACCOUNT_HASH\" --data-dir $DAL_RUN_DIR"
    echo ""
    STEP=$((STEP + 1))
fi

# Configure Etherlink if needed
if [ "$SETUP_ETHERLINK" = true ] && [ "$ETHERLINK_CONFIGURED" = false ]; then
    echo -e "${CYAN}${STEP}. Configure Etherlink Smart Rollup observer node${NC}"
    echo "   mkdir -p \"$ETHERLINK_RUN_DIR\""
    echo "   octez-smart-rollup-node init observer config for $ETHERLINK_ROLLUP_ADDR with operators --data-dir $ETHERLINK_RUN_DIR --pre-images-endpoint $ETHERLINK_PREIMAGES"
    echo ""
    echo "   SNAPSHOT=\`echo $ETHERLINK_SNAPSHOT | cut -d \"/\" -f 5\`"
    echo "   cd /tmp"
    echo "   wget $ETHERLINK_SNAPSHOT"
    echo "   octez-smart-rollup-node --endpoint $ETHERLINK_RPC_ENDPOINT snapshot import \$SNAPSHOT --data-dir $ETHERLINK_RUN_DIR"
    echo "   rm \$SNAPSHOT"
    echo ""
    STEP=$((STEP + 1))
fi

# Configure TezPay if needed or regenerate if parameters changed
if [ "$SETUP_TEZPAY" = true ] && [ "$TEZPAY_CONFIGURED" = false ]; then
    echo -e "${CYAN}${STEP}. Configure TezPay for delegator payments${NC}"
    echo -e "${YELLOW}   ATTENTION: Only do this after your baker has attestation rights for the current cycle${NC}"
    echo "   (Check on tzkt.io)"
    echo ""
    echo "   mkdir -p $TEZPAY_RUN_DIR"
    echo "   cd $TEZPAY_RUN_DIR"
    echo ""
    echo "   # Install TezPay (if not already installed)"
    echo "   install-tezpay.sh"
    echo ""
    
    echo "   # Create TezPay configuration file (example below)"
    echo "   cat<<EOF>config.hjson"
    generate_tezpay_config
    echo "EOF"
    echo ""
    echo "   # Create payout key file (replace placeholder with your actual private key)"
    echo "   ${YELLOW}# SECURITY WARNING: Store only enough XTZ for payouts in this account${NC}"
    echo "   ${YELLOW}# Consider using Ledger or remote signer for production${NC}"
    echo "   ${YELLOW}# See: https://docs.tez.capital/tezpay/tutorials/how-to-setup/${NC}"
    echo ""
    echo "   cat<<EOF>payout_wallet_private.key"
    echo "edskYYYYYYYYYY: YOUR PAYOUTS ACCOUNT PRIVATE KEY"
    echo "EOF"
    echo ""
    echo "   chmod go-rwx payout_wallet_private.key"
    echo ""
    echo "   # Delegate payout account to your baker"
    echo "   octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} set delegate for $TEZPAY_ACCOUNT_HASH to $BAKER_ACCOUNT_HASH"
    echo ""
    STEP=$((STEP + 1))
elif [ "$SETUP_TEZPAY" = true ]; then
    print_warning "TezPay already configured. Manual modifications will not be overwritten."
fi

# Warn about configuration changes that require manual action
if [ "$EXISTING_CONFIG" = true ]; then
    # Warn about disabled components
    if [ "$ETHERLINK_RUNNING" = true ] && [ "$SETUP_ETHERLINK" = false ]; then
        echo ""
        print_warning "Etherlink was running but is now disabled in configuration"
        echo "   You should stop it manually:"
        echo "   ${GREEN}stop-etherlink.sh${NC}"
        echo ""
    fi
    
    if [ "$TEZPAY_RUNNING" = true ] && [ "$SETUP_TEZPAY" = false ]; then
        echo ""
        print_warning "TezPay was running but is now disabled in configuration"
        echo "   You should stop it manually:"
        echo "   ${GREEN}stop-tezpay.sh${NC}"
        echo ""
    fi
    
    # Handle staking parameter changes (automatic update)
    if [ -n "$OLD_BAKER_LIMIT" ] && [ -n "$OLD_BAKER_EDGE" ]; then
        if [ "$OLD_BAKER_LIMIT" != "$BAKER_LIMIT_STAKING_OVER_BAKING" ] || [ "$OLD_BAKER_EDGE" != "$BAKER_EDGE_BAKING_OVER_STAKING" ]; then
            echo ""
            print_warning "Staking parameters have changed"
            echo "   Old values: limit=$OLD_BAKER_LIMIT, edge=$OLD_BAKER_EDGE"
            echo "   New values: limit=$BAKER_LIMIT_STAKING_OVER_BAKING, edge=$BAKER_EDGE_BAKING_OVER_STAKING"
            echo ""
            print_info "Updating on-chain parameters..."
            
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY-RUN] Would execute: octez-client set delegate parameters for $KEY_BAKER --limit-of-staking-over-baking $BAKER_LIMIT_STAKING_OVER_BAKING --edge-of-baking-over-staking $BAKER_EDGE_BAKING_OVER_STAKING"
            else
                octez-client --base-dir "$CLIENT_BASE_DIR" --endpoint "http://${NODE_RPC_ADDR}" \
                    set delegate parameters for "$KEY_BAKER" \
                    --limit-of-staking-over-baking "$BAKER_LIMIT_STAKING_OVER_BAKING" \
                    --edge-of-baking-over-staking "$BAKER_EDGE_BAKING_OVER_STAKING"
                print_success "Staking parameters updated on-chain"
            fi
            echo ""
        fi
    fi
    
    # Warn about TezPay address change (manual action required)
    if [ "$SETUP_TEZPAY" = true ] && [ -n "$OLD_TEZPAY_ACCOUNT_HASH" ] && [ "$OLD_TEZPAY_ACCOUNT_HASH" != "tzYYYYYYYYYY: YOUR PAYOUTS ADDRESS HASH" ]; then
        if [ "$OLD_TEZPAY_ACCOUNT_HASH" != "$TEZPAY_ACCOUNT_HASH" ]; then
            echo ""
            print_warning "TezPay payout address has changed"
            echo "   Old address: $OLD_TEZPAY_ACCOUNT_HASH"
            echo "   New address: $TEZPAY_ACCOUNT_HASH"
            echo ""
            echo "   You need to manually update TezPay configuration:"
            echo "   1. Stop TezPay: ${GREEN}stop-tezpay.sh${NC}"
            echo "   2. Edit ${TEZPAY_RUN_DIR}/config.hjson (update overrides section with new address)"
            echo "   3. Update payout_wallet_private.key with new private key"
            echo "   4. Update payout key in octez-client:"
            echo "      ${GREEN}octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} forget address $KEY_PAYOUT${NC}"
            echo "      ${GREEN}octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} add address $KEY_PAYOUT $TEZPAY_ACCOUNT_HASH${NC}"
            echo "   5. Restart TezPay: ${GREEN}start-tezpay.sh${NC}"
            echo ""
        fi
    fi
    
    # Handle TezPay interval change
    if [ "$RESTART_TEZPAY" = true ]; then
        # Stop TezPay if running and not already stopped by general restart
        if [ "$TEZPAY_RUNNING" = true ] && [ "$NEED_RESTART_SERVICES" = false ]; then
            print_info "Restarting TezPay to update interval configuration..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY-RUN] Would restart TezPay"
            else
                if [ -x "$(which stop-tezpay.sh 2>/dev/null)" ]; then
                    stop-tezpay.sh 2>/dev/null || true
                    start-tezpay.sh 2>/dev/null || true
                    print_success "TezPay restarted"
                fi
            fi
        fi
    fi
fi

# Start all services (only if not already running)
if [ "$SERVICES_RUNNING" = false ]; then
    echo -e "${CYAN}${STEP}. Start all services${NC}"
    echo "   Once all configuration steps above are complete, start all services:"
    echo "   ${GREEN}tezos-baker start${NC}"
    echo ""
    echo "   This will start (in order):"
    echo "   - Octez node (if not running)"
    echo "   - DAL node"
    echo "   - Baker and Accuser"
    if [ "$SETUP_ETHERLINK" = true ]; then
        echo "   - Etherlink Smart Rollup node"
    fi
    if [ "$SETUP_TEZPAY" = true ]; then
        echo "   - TezPay (continual mode)"
    fi
    echo ""
    STEP=$((STEP + 1))
else
    print_success "Services are already running. No need to start them again."
    echo ""
    echo "   If you made configuration changes that require a restart, use:"
    echo -e "   ${GREEN}tezos-baker restart${NC}"
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
