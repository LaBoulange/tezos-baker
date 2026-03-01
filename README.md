# tezos-baker
Tools and scripts to set up and operate a Tezos baker capable of baking, accusing, participating in the DAL, and optionally paying its delegators and running an Etherlink Smart Rollup observer node.

This repository provides:
- an interactive setup wizard (`tezos-baker-setup.sh`) for guided initial configuration,
- a CLI tool (`tezos-baker`) for day-to-day operations,
- for advanced users, installation scripts for the octez suite and optionally TezPay.

Content of this document:
- [tezos-baker](#tezos-baker)
  * [Disclaimer](#disclaimer)
  * [Prerequisites](#prerequisites)
  * [Operating instructions](#operating-instructions)
    + [Initial setup](#initial-setup)
    + [Upgrade from the previous versions](#upgrade-from-the-previous-versions)
    + [Maintenance](#maintenance)
  * [Testing unreleased code](#testing-unreleased-code)
  * [Release management](#release-management)
  * [Should you wish to support us](#should-you-wish-to-support-us)
  * [Contact](#contact)


## Disclaimer

This repository is not intended to provide perfect code, but code as simple as possible and sufficient to start a baking activity. It can be used as a tutorial.

As a result, it is not state-of-the-art in terms of automation, high availability, or security. We will address these aspects throughout this documentation when relevant. In any case, we decline all responsibility in the event of damages, theft of crypto-assets, operational or security incidents, as detailed further in the [LICENSE.txt](LICENSE.txt) file.

Additionally, this code doesn't leverage all the options provided by octez and TezPay. We encourage you to read the documentation for these tools and enhance your setup, transforming this basic configuration into something remarkable.
- octez: https://tezos.gitlab.io/index.html
- TezPay: https://docs.tez.capital/tezpay/tutorials/ 


## Prerequisites

This code is designed to run on a x86_64 or ARM64 Linux platform.

Hardware requirements:
- 4 CPU cores
- 16GB to 20GB RAM depending on your stake (see DAL hardware requirements, https://forum.tezosagora.org/t/hardware-and-bandwidth-requirements-for-the-tezos-dal/6230), swap included.
- 120GB to 500GB SSD drive depending on the chosen node history mode ("rolling" or "full", see https://tezos.gitlab.io/user/history_modes.html)

Before using this code, you should also have:
- a Tezos account set up to become the baker, and funded with a sufficient amount of XTZ (6000 is required to have baking rights without relying on externally staked and delegated).
- if you wish to pay your delegators, a Tezos account set up to handle the payouts.


## Operating instructions

For simplicity, both the initial setup and maintenance processes are designed to be executed by the 'root' user. While this is convenient, it is not best practice from a security standpoint. Ideally, one should minimize operations performed as 'root' and designate one or more users specifically for Tezos-related tasks. 

Because user management configurations can vary widely, we've opted not to make assumptions about your preferences in this area. This approach allows you to easily modify these scripts and procedures according to your own criteria and preferences.


### Initial setup

The easiest way to set up your baker is using the interactive wizard:

```bash
# 1. Install the tezos-baker scripts
install-tezos-baker.sh

# 2. Run the interactive setup wizard
tezos-baker-setup.sh
```

The wizard will guide you through all configuration steps, validate your inputs, and automatically generate the `tezos-env.sh` file. See [CLI-REFERENCE.md](CLI-REFERENCE.md) for the complete CLI reference.

**Alternative: Manual Setup**

For advanced users who prefer manual configuration: copy `tezos-env.sh.template` to `tezos-env.sh`, fill in the required variables (baker address, data directory, network, etc.), run `install-tezos-baker.sh`, then follow `initial-setup.sh` step by step. See [MANUAL-OPS-REFERENCE.md](MANUAL-OPS-REFERENCE.md) for the full variable reference and detailed instructions.


### Upgrade from the previous versions

#### From tezos-baker v24.0, v24.1 or v24.2

Simply run:
```bash
tezos-baker upgrade
```

**Alternative: Manual upgrade**

Follow the "Upgrade octez" procedure from the [manual-ops-cheat-sheet](manual-ops-cheat-sheet.sh#L16) (see [MANUAL-OPS-REFERENCE.md](MANUAL-OPS-REFERENCE.md)  for further details).


### Maintenance

The easiest way to perform maintenance operations is using the `tezos-baker` CLI:

```bash
# Common operations:
tezos-baker start               # Start all services
tezos-baker stop                # Stop all services (useful before reboot)
tezos-baker restart             # Restart all services
tezos-baker upgrade             # Upgrade Octez
tezos-baker upgrade-tezpay      # Upgrade TezPay
tezos-baker stake increase 1000 # Stake 1000 XTZ
tezos-baker vote info           # Show voting period
tezos-baker logs baker          # View baker logs
tezos-baker status              # Check status

# For complete command reference:
tezos-baker help
```

See [CLI-REFERENCE.md](CLI-REFERENCE.md) for detailed documentation and examples.

**Alternative: Manual Maintenance**

For manual operations, `manual-ops-cheat-sheet.sh` covers: restart/reboot, Octez upgrade, TezPay upgrade, stake management, governance voting, history mode switch, and BLS/tz4 setup. Run commands one at a time — do not execute the file as a script. See [MANUAL-OPS-REFERENCE.md](MANUAL-OPS-REFERENCE.md) for details.


## Testing unreleased code

If you need to test code from a specific branch before creating an official release, you can use the `--branch` parameter:

```bash
# Install from a specific branch for testing
install-tezos-baker.sh --branch my-test-branch

# Install from master branch
install-tezos-baker.sh --branch master

# Normal installation (latest release)
install-tezos-baker.sh
```

This is particularly useful for testing changes on your baker without publishing a GitHub release.


## Release management

- Versions are numbered in the same way as those of the Tezos Gitlab repository, on which they are based. (See https://gitlab.com/tezos/tezos/-/releases). Before v20.0, they were based on Serokell's 'tezos-packaging' repository (See https://github.com/serokell/tezos-packaging).
- Underlying tags are named according to the same version number, with references to the active and replaced protocol names. Before v18.1-1, only the major version number was used.
- In the case of a change not tied to a new release of octez, a minor version number prefixed by an underscore is appended to both versions and tags.


## Should you wish to support us

You can send a donation:
- to our baker's address: [tz1aJHKKUWrwfsuoftdmwNBbBctjSWchMWZY](https://tzkt.io/tz1aJHKKUWrwfsuoftdmwNBbBctjSWchMWZY/schedule)
- or to its Tezos domain name: [laboulange.tez](https://tzkt.io/laboulange.tez/schedule)

Or just click here: 

[![Button Support]][Link Support] 

This is not mandatory, but it is greatly appreciated!

[Button Support]: https://img.shields.io/badge/Support_La_Boulange!_(5_XTZ)-007bff?style=for-the-badge
[Link Support]: https://tezos-share.stroep.nl/?id=tfLn0 'Support La Boulange (5 XTZ)'


## Contact

Feel free to contact us with any questions or suggestions. We can be reached through the following channels:
- E-mail: la.boulange.tezos@gmail.com
- TwitterX: https://x.com/LaBoulangeTezos
- Telegram: https://t.me/laboulangetezos

We are also active in various Telegram and Discord groups related to Tezos.
