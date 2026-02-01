# 🎉 New User-Friendly Features

This document describes the new interactive tools that make managing your Tezos baker much easier!

## 🆕 What's New?

We've added two powerful new tools to improve the user experience:

### 1. **Interactive Setup Wizard** (`tezos-baker-setup.sh`)
A guided wizard that walks you through the initial baker setup with:
- ✅ Step-by-step configuration prompts
- ✅ Input validation (Tezos addresses, numbers, etc.)
- ✅ Automatic `tezos-env.sh` generation
- ✅ Optional components (TezPay, Etherlink, BLS/tz4)
- ✅ Colored output for better readability
- ✅ Automated installation of Octez and node setup
- ✅ **Safe for existing installations**: Automatically creates backups and loads current values as defaults

### 2. **Modern CLI Tool** (`tezos-baker`)
A comprehensive command-line interface for all maintenance operations:
- ✅ Simple, intuitive commands
- ✅ Built-in help and documentation
- ✅ Colored output and progress indicators
- ✅ Safe operations with confirmations
- ✅ Replaces manual copy-paste from cheat sheets

---

## ⚡Quick Start

### Initial Setup (New Installations)

Instead of manually editing configuration files and copy-pasting commands, simply run:

```bash
# 1. Install the tezos-baker scripts (as before)
install-tezos-baker.sh

# 2. Run the interactive setup wizard
tezos-baker-setup.sh
```

The wizard will:
1. Ask you questions about your configuration
2. Validate your inputs
3. Generate the `tezos-env.sh` file automatically
4. Install Octez and set up your node
5. Provide clear instructions for manual steps (key imports, etc.)

### Daily Operations (Maintenance)

Use the new `tezos-baker` CLI for all maintenance tasks:

```bash
# View all available commands
tezos-baker help

# Check baker status
tezos-baker status

# View logs
tezos-baker logs baker
tezos-baker logs node 100

# Restart services
tezos-baker restart

# Upgrade Octez
tezos-baker upgrade

# Manage staking
tezos-baker stake increase 1000
tezos-baker stake info

# Participate in governance
tezos-baker vote info
tezos-baker vote ballot PtXXXXXX yay
```

---

## 📚 Complete CLI Reference

### Setup & Configuration

```bash
tezos-baker setup              # Run the interactive setup wizard
tezos-baker --version          # Show version information
```

### Service Management

```bash
tezos-baker start              # Start all baker services
tezos-baker stop               # Stop all baker services
tezos-baker restart            # Restart all baker services
tezos-baker status             # Show current status and running processes
tezos-baker logs <component>   # View logs (node, baker, accuser, dal, tezpay, etherlink)
```

### Upgrades

```bash
tezos-baker upgrade            # Upgrade Octez to latest version
tezos-baker upgrade-tezpay     # Upgrade TezPay to latest version
```

### Staking Operations

```bash
tezos-baker stake increase <amount>    # Stake additional XTZ
tezos-baker stake decrease <amount>    # Unstake XTZ (takes 2 cycles)
tezos-baker stake finalize             # Finalize unstaked balance (after 4 cycles)
tezos-baker stake params               # Update staking parameters
tezos-baker stake info                 # Show current staking information
```

### Governance Voting

```bash
tezos-baker vote info                      # Show current voting period
tezos-baker vote propose <proposal...>     # Submit proposal(s)
tezos-baker vote ballot <proposal> <vote>  # Vote yay/nay/pass
```

### Advanced Operations

```bash
tezos-baker history-mode <mode>    # Switch node history mode (rolling, full, rolling:N)
tezos-baker enable-bls             # Enable BLS/tz4 baking
```

---

## 🔄 Migration Guide

### For Existing Users

If you already have a working baker setup, you can start using the new CLI immediately:

1. **Update your scripts:**
   ```bash
   install-tezos-baker.sh
   ```

2. **Start using the CLI:**
   ```bash
   # Instead of manually running commands from maintenance-cheat-sheet.sh
   tezos-baker upgrade
   
   # Instead of manually managing stake
   tezos-baker stake increase 500
   ```

3. **Your existing `tezos-env.sh` will continue to work** - no need to regenerate it unless you want to.

### Comparison: Old vs New

#### Old Way (Manual)
```bash
# Open maintenance-cheat-sheet.sh
# Copy commands one by one
. `which tezos-env.sh`
stop-tezpay.sh
stop-etherlink.sh
stop-octez.sh
install-octez.sh
# ... many more commands
```

#### New Way (CLI)
```bash
tezos-baker upgrade
```

---

## 🎨 Features Highlights

### Interactive Setup Wizard

**Architecture Detection:**
- Automatically detects your system architecture (x86_64 or ARM64)

**Network Selection:**
- Choose from mainnet, ghostnet, or custom networks
- Select history mode (rolling, full, or rolling with extra cycles)

**Baker Configuration:**
- Validates Tezos addresses in real-time
- Configures staking parameters with range validation
- Optional BLS/tz4 consensus keys setup

**Optional Components:**
- TezPay for delegator payments
- Etherlink Smart Rollup observer node

**Review & Confirm:**
- Shows complete configuration before proceeding
- Allows cancellation at any point

### Modern CLI

**Colored Output:**
- 🔵 Blue headers for sections
- 🟢 Green for success messages
- 🟡 Yellow for warnings
- 🔴 Red for errors
- 🔵 Cyan for information

**Smart Confirmations:**
- Asks for confirmation on destructive operations
- Shows current values before changes

**Context-Aware:**
- Detects which optional components are installed
- Only manages services that are configured

**Built-in Help:**
- Every command has detailed help
- Examples provided for common operations

---

## 📝 Examples

### Example 1: Fresh Installation

```bash
# Run the wizard
$ tezos-baker-setup.sh

🥖 Tezos Baker Setup Wizard
═══════════════════════════════════════════════════════════════

Welcome to the Tezos Baker Setup Wizard!

This wizard will guide you through the initial configuration...

? Are you ready to begin? [Y/n]: y

Step 1/8: System Configuration
═══════════════════════════════════════════════════════════════

ℹ Detecting system architecture...
? Hardware architecture (x86_64 or arm64) [x86_64]: 
? Build directory (temporary files) [/tmp/build-tezos-baker]: 
? Installation directory (executables) [/usr/local/bin]: 
? Data directory (blockchain data, requires large storage) [/var/tezos]: 

Step 2/8: Network Configuration
═══════════════════════════════════════════════════════════════

Available networks:
  1) mainnet (production network)
  2) ghostnet (test network)
  3) custom (specify your own)

? Select network [1]: 1
✓ Network: mainnet

# ... continues through all steps ...
```

### Example 2: Upgrading Octez

```bash
$ tezos-baker upgrade

Upgrading Octez
═══════════════════════════════════════════════════════════════

⚠ This will stop all services and upgrade Octez to the latest version.
? Do you want to continue? [Y/n]: y

ℹ Updating tezos-baker scripts...
ℹ Stopping TezPay...
ℹ Stopping Octez services...
ℹ Installing Octez...
ℹ Checking if storage upgrade is needed...
⚠ Storage upgrade running in background. Check /var/log/octez-node.log for progress.
ℹ Starting Octez services...
ℹ Starting TezPay...
✓ Upgrade completed successfully!
ℹ Check for any backup directories in your home directory that may need cleanup.
```

### Example 3: Managing Stake

```bash
$ tezos-baker stake info

Staking Information
═══════════════════════════════════════════════════════════════

{
  "full_balance": "12500000000",
  "frozen_deposits": "6000000000",
  "staking_balance": "15000000000",
  ...
}

$ tezos-baker stake increase 1000

Increasing Stake
═══════════════════════════════════════════════════════════════

ℹ Staking 1000 XTZ for mybaker...
Node is bootstrapped.
Estimated gas: 1000 units
...
✓ Stake increased by 1000 XTZ
```

### Example 4: Viewing Logs

```bash
$ tezos-baker logs baker 20

Baker Logs (last 20 lines)
═══════════════════════════════════════════════════════════════

Jan 24 12:00:01 baker: Injected block BLxxxxxx
Jan 24 12:00:15 baker: Injected endorsement for level 5000000
Jan 24 12:00:30 baker: Waiting for next baking slot
...
```

---

## 🛠️ Technical Details

### File Locations

- **Setup Wizard:** `/usr/local/bin/tezos-baker-setup.sh`
- **CLI Tool:** `/usr/local/bin/tezos-baker`
- **Generated Config:** `/usr/local/bin/tezos-env.sh`

### Compatibility

- ✅ Fully compatible with existing installations
- ✅ Works alongside existing scripts (start-octez.sh, stop-octez.sh, etc.)
- ✅ Uses the same configuration file (`tezos-env.sh`)
- ✅ No breaking changes to existing workflows

### Requirements

- Bash 4.0+
- Standard Unix utilities (grep, awk, sed, wget, etc.)
- bc (for numeric validation)

---

## 🤝 Backward Compatibility

**The old workflow still works!** You can continue to:
- Manually edit `tezos-env.sh`
- Use `initial-setup.sh` as a reference
- Use `maintenance-cheat-sheet.sh` for copy-paste commands
- Run individual scripts (start-octez.sh, stop-octez.sh, etc.)

The new tools are **additions**, not replacements. Use whichever approach you prefer!

---

## 💡 Tips & Best Practices

1. **Use the wizard for initial setup** - It's faster and less error-prone than manual configuration

2. **Use the CLI for daily operations** - Commands are easier to remember than script locations

3. **Check status regularly:**
   ```bash
   tezos-baker status
   ```

4. **Monitor logs during upgrades:**
   ```bash
   tezos-baker upgrade
   # In another terminal:
   tezos-baker logs node
   ```

5. **Use tab completion** - The CLI command names are designed to be intuitive

---

## 🐛 Troubleshooting

### "tezos-env.sh not found"

Make sure you've run the setup wizard or have a valid `tezos-env.sh` in your `INSTALL_DIR`.

### "Command not found: tezos-baker"

Ensure `/usr/local/bin` is in your PATH and the script is executable:
```bash
chmod +x /usr/local/bin/tezos-baker
export PATH="/usr/local/bin:$PATH"
```

### "Permission denied"

Most commands need to be run as root or with appropriate permissions:
```bash
sudo tezos-baker upgrade
```

---

## 📞 Support

For questions or issues:
- Email: la.boulange.tezos@gmail.com
- Twitter: https://x.com/LaBoulangeTezos
- Telegram: https://t.me/laboulangetezos

---

## 🎯 Future Enhancements

Potential future improvements:
- [ ] Auto-completion for bash/zsh
- [ ] Configuration file editor (interactive tezos-env.sh updates)
- [ ] Health checks and diagnostics
- [ ] Automated backup/restore
- [ ] Web dashboard (optional)

---

**Happy Baking! 🥖**
