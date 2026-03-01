# Manual Operations Reference

This document is the complete reference for users who prefer to configure and operate their baker manually, without using the interactive wizard or the `tezos-baker` CLI.

> **Note:** The interactive wizard (`tezos-baker-setup.sh`) and the `tezos-baker` CLI are the recommended approach for most users. See [CLI-REFERENCE.md](CLI-REFERENCE.md) for details.

---

## Manual Setup (Initial Configuration)

### Initial steps

- Choose a directory where the executable files for your baker will be installed (typically `/usr/local/bin`). This directory will be referred to as `BAKER_INSTALLATION_DIR` later in this document.
- Ensure this `BAKER_INSTALLATION_DIR` is part of the `PATH` environment variable of the user intended to run or service the baker.
- Copy the file `usr/local/bin/install-tezos-baker.sh` of this repository to the `BAKER_INSTALLATION_DIR` directory of your machine.
- Copy the file `usr/local/bin/tezos-constants.sh` of this repository to the `BAKER_INSTALLATION_DIR` directory of your machine.
- Make sure all the two files above are executable by the user intended to run them.

### Configuration File (`tezos-env.sh`)

Create a file `BAKER_INSTALLATION_DIR/tezos-env.sh` by copying the file `usr/local/bin/tezos-env.sh.template` of this repository. Some variables need configuration and should persist over upgrades while the others may optionally be adjusted.

#### Required variables

- `DATA_DIR`: The directory where the data needed by octez and TezPay will be stored (requires large storage space).
- `KEY_BAKER`: The friendly name you would like to use as an alias for your baker address when managing your baker. This name is not shared publicly; it is only used locally.
- `BAKER_ACCOUNT_HASH`: The tzXXX address of your baker.

#### Optional variables

- `BAKER_ARCH`: The hardware architecture you use for baking. Currently, the supported values are `x86_64` (similar to `amd64` - deprecated) and `arm64`. Default: `x86_64`.
- `BUILD_DIR`: The working directory where files will be downloaded by the installation scripts of this repository. Default: `/tmp/build-tezos-baker`.
- `INSTALL_DIR`: The directory `BAKER_INSTALLATION_DIR` where executables files will be stored. Default: `/usr/local/bin`.
- `NODE_NETWORK`: The Tezos network that your bakery belongs to: `mainnet`, `tallinnnet`, or any other network. Default: `mainnet`.
- `NODE_MODE`: The history mode of your node (`full`, `rolling`, or `rolling:<number_of_extra_cycles>`). See https://tezos.gitlab.io/user/history_modes.html for more details. Default: `rolling`.
- `NODE_SNAPSHOT_URL`: The URL of the Tezos data snapshot to download to initialize your node. Default: Lambs on Acid's URL corresponding to your `NODE_NETWORK` and `NODE_MODE` (See https://lambsonacid.nl/).
- `BAKER_LIQUIDITY_BAKING_SWITCH`: The liquidity baking vote (`off`, `on`, or `pass`). See https://tezos.gitlab.io/active/liquidity_baking.html for more details. Default: `pass`.
- `BAKER_LIMIT_STAKING_OVER_BAKING`: How many times your stake, ranging from 0 (no staking) to 9 (max allowed by the protocol), you allow others to stake with your baker. Default: 9.
- `BAKER_EDGE_BAKING_OVER_STAKING`: Proportion from 0 (0%) to 1 (100%) of the reward that your baker receives from the amount staked by stakers. Default: 0.1 (10%).

#### TezPay variables (optional — only if you wish to pay your delegators)

- `TEZPAY_ACCOUNT_HASH`: The tzYYY address of your payout account.
- `TEZPAY_FEES`: The baking fee you wish to charge your delegators, ranging from 0 (0%) to 1 (100%). Default: 0.1 (10%).
- `TEZPAY_INTERVAL`: Aggregates and distributes payouts every N cycles. Default: 1 (every cycle).

### Installation Steps

1. Make `BAKER_INSTALLATION_DIR/tezos-env.sh` executable by the user intended to run it.
2. Run `install-tezos-baker.sh`.
3. Follow the step-by-step instructions in the `initial-setup.sh` file from this repository. **Do not execute this file as a script!** Instead, copy and run the instructions one at a time, as you'll be prompted to take several actions throughout the process. These actions are described in the comments appearing in this file.

---

## Manual Maintenance

The `manual-ops-cheat-sheet.sh` file contains ready-to-use commands for all maintenance operations. **Do not execute this file as a script!** Instead, copy and run the instructions of the section that interests you one at a time, as you'll be prompted to take several actions throughout the process.

### Sections available in `manual-ops-cheat-sheet.sh`

#### Restart/Reboot
Instructions for when you need to restart your baker, possibly due to reasons such as Linux distribution maintenance.

#### Upgrade Octez
Steps for updating when a new version of octez is released. This section also covers Tezos protocol upgrades.

#### Upgrade TezPay
Should you wish to pay your delegators: procedures for when a new version of TezPay is available.

#### Stake and payouts management
Guidelines on setting your baker's stake parameters and optionally replenishing your payout account.

#### Voting process
Help on how to vote at the various stages of the Tezos amendment and voting process (https://tezos.gitlab.io/active/voting.html).

#### Switch history mode from full to rolling
Help on how to optimize performances and disk space by switching the node history mode from `full` to `rolling`.

#### Enable BLS/tz4 baking
Guidelines on setting up your baker's tz4 consensus and DAL companion keys.

---

## 📞 Support

For questions or issues:
- Email: la.boulange.tezos@gmail.com
- Twitter: https://x.com/LaBoulangeTezos
- Telegram: https://t.me/laboulangetezos
