# tezos-baker
Boilerplate code to set up a minimalistic Tezos baker capable of baking, accusing, and paying its delegators.

This code:
- installs octez-node, octez-baker, octez-accuser, Tezpay and its extension payouts-substitutor on a single machine
- provides some basic maintenance tools.

Content of this document:
- [tezos-baker](#tezos-baker)
  * [Disclaimer](#disclaimer)
  * [Release management](#release-management)
  * [Prerequisites](#prerequisites)
  * [Operating instructions](#operating-instructions)
    + [Initial setup](#initial-setup)
    + [Maintenance](#maintenance)
    + [Upgrade from previous versions](#upgrade-from-previous-versions)
      - [Upgrade from tezos-baker v20.1 (see CHANGELOG.md)](#upgrade-from-tezos-baker-v201-see-changelogmd)
  * [Should you wish to support us](#should-you-wish-to-support-us)
  * [Contact](#contact)


## Disclaimer

This repository is not intended to provide perfect code, but code as simple as possible and sufficient to start a baking activity. It can be used as a tutorial.

As a result, it is not state-of-the-art in terms of automation, high availability, or security. We will address these aspects throughout this documentation when relevant. In any case, we decline all responsibility in the event of damages, theft of crypto-assets, operational or security incidents, as detailed further in the LICENSE.txt file.

Additionally, this code doesn't leverage all the options provided by octez, Tezpay and payouts-substitutor. We encourage you to read the documentation for these tools and enhance your setup, transforming this basic configuration into something remarkable.
- octez: https://tezos.gitlab.io/index.html
- Tezpay: https://docs.tez.capital/tezpay/tutorials/ 
- payouts-substitutor: https://github.com/LaBoulange/tezpay-extensions


## Release management

- Versions are numbered in the same way as those of the Tezos Gitlab repository, on which they are based. (See https://gitlab.com/tezos/tezos/-/releases). Before v20.0, they were based on Serokell's 'tezos-packaging' repository (See https://github.com/serokell/tezos-packaging).
- Underlying tags are named according to the same version number, with references to the active and replaced protocol names. Before v18.1-1, only the major version number was used.
- In the case of a change not tied to a new release of octez, a minor version number prefixed by an underscore is appended to both versions and tags.


## Prerequisites

This code is designed to run on a x86_64 or ARM64 Linux platform.

Hardware requirements:
- 2 CPU cores
- Preferably 8GB RAM
- 300GB SSD drive

Before using this code, you should also have:
- a Tezos account set up to become the baker, and funded with a sufficient amount of XTZ.
- a Tezos account set up to handle the payouts.


## Operating instructions

For simplicity, both the initial setup and maintenance processes are designed to be executed by the 'root' user. While this is convenient, it is not best practice from a security standpoint. Ideally, one should minimize operations performed as 'root' and designate one or more users specifically for Tezos-related tasks. Because user management configurations can vary widely, we've opted not to make assumptions about your preferences in this area. This approach allows you to easily modify these scripts and procedures according to your own criteria and preferences.


### Initial setup

- Choose a directory where the executable files for your baker will be installed (typically `/usr/local/bin`). This directory will be referred to as `BAKER_INSTALLATION_DIR` later in this document.
- Ensure this `BAKER_INSTALLATION_DIR` is part of the `PATH` environment variable the user intended to run or service the baker (see [Operating instructions](#operating-instructions) section above).
- Copy the file `usr/local/bin/install-tezos-baker.sh` of this repository to the `BAKER_INSTALLATION_DIR` directory of your machine.
- Copy the file `usr/local/bin/tezos_constants.sh` of this repository to the `BAKER_INSTALLATION_DIR` directory of your machine.
- Make sure all the two files above are executable by the user intended to run them.
- Create a file `BAKER_INSTALLATION_DIR/tezos-env.sh` by copying the file `usr/local/bin/tezos-env.sh.template` of this repository. Some variables need configuration and should persist over upgrades:
    - `BAKER_ARCH`: The hardware architecture you use for baking. Currently, the supported values are `amd64` (x86_64) and `arm64`. Default: `amd64`.
    - `BUILD_DIR`: The working directory where files will be downloaded by the installation scripts of this repository. Default: `/tmp/build-tezos-baker`.
    - `INSTALL_DIR`: The directory `BAKER_INSTALLATION_DIR` where executables files will be stored. Default: `/usr/local/bin`.
    - `DATA_DIR`: The directory where the data needed by octez and Tezpay will be stored (requires large storage space).
    - `KEY_BAKER`: The friendly name you would like to use as an alias for your baker address when managing your baker. This name is not shared publicly; it is only used locally.
    - `BAKER_ACCOUNT_HASH`: The tzXXX address of your baker.
    - `BAKER_LIQUIDITY_BAKING_SWITCH`: The liquidity baking vote (off, on, or pass). See https://tezos.gitlab.io/active/liquidity_baking.html for more details.
    - `BAKER_LIMIT_STAKING_OVER_BAKING`: How many times your stake, ranging from 0 (no staking) to 5 (max allowed by the protocol), you allow others to stake with your baker.
    - `BAKER_EDGE_BAKING_OVER_STAKING`: Proportion from 0 (0%) to 1 (100%) of the reward that your baker receives from the amount staked by stakers.
    - `TEZPAY_ACCOUNT_HASH`: The tzYYY address of your payout account.
    - `TEZPAY_FEES`: The baking fee you wish to charge your delegators, ranging from 0 (0%) to 1 (100%).
- Make `BAKER_INSTALLATION_DIR/tezos-env.sh` executable by the user intended to run it.
- Run `install-tezos-baker.sh`.
- Next, follow the step-by-step instructions in the `initial-setup.sh` file from this repository. Don't execute this file as a script. Instead, copy and run the instructions one at a time, as you'll be prompted to take several actions throughout the process. These actions are described in the comments appearing in this file.


### Maintenance

The `maintenance-cheat-sheet.sh` file includes the following sections:
- **Restart/Reboot**: Instructions for when you need to restart, possibly due to reasons such as Linux distribution maintenance.
- **Upgrade octez**: Steps for updating when a new version of octez is released. This section also covers Tezos protocol upgrades.
- **Upgrade TezPay**: Procedures for when a new version of TezPay or payouts-substitutor is available.
- **Stake management**: Guidelines on setting your baker's deposit limit and replenishing your payout account.
- **Voting process**: Help on how to vote at the various stages of the Tezos amendment and voting process (https://tezos.gitlab.io/active/voting.html).

Don't execute this file as a script. Instead, copy and run the instructions of the section that interests you one at a time, as you'll be prompted to take several actions throughout the process. These actions are described in the comments appearing in this file.


### Upgrade from previous versions

#### Upgrade from tezos-baker v20.1 (see CHANGELOG.md)
This version installs Tezpay Payout Fixer without activating it, as Tezpay is running in continual mode by default (see [Tezpay Payout Fixer documentation](https://github.com/tez-capital/tezpay/tree/0.16.1-beta/extension/official/payout-fixer)).

- Run `install-tezos-baker.sh`.
- Update your Tezpay configuration file by adding the following extension, commented, so that you will just have to uncomment thi block when willing to run the extension (optional)

&nbsp;

    extensions: [
        // ... other extensions ...

        /* UNCOMMENT WHEN RUNNING payout-fixer IN MANUAL MODE
        {
        name: payout-fixer
        command: "${TEZPAY_RUN_DIR}/tezpay-payout-fixer" 
        kind: stdio
        hooks: [
            after_payouts_prepared: rw
        ]
        }
        */   
    ]

- Run the 'Upgrade TezPay' procedure of the [Maintenance](#maintenance) section above.

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
- MailChain: [laboulange@mailchain](https://app.mailchain.com/)
- E-mail: la.boulange.tezos@gmail.com
- DNS: https://dns.xyz/fr/LaBoulange
- Twitter: https://twitter.com/LaBoulangeTezos
- Telegram: https://t.me/laboulangetezos

We are also active in various Telegram and Discord groups related to Tezos.
