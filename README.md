# tezos-baker
Boilerplate code to set up a minimalistic Tezos baker capable of baking, accusing, and paying its delegators.

This code:
- installs octez-node, octez-baker, octez-accuser, and Tezpay on a single machine
- provides some basic maintenance tools.


## Disclaimer

This repository is not intended to provide perfect code, but code as simple as possible and sufficient to start a baking activity. It can be used as a tutorial.

As a result, it is not state-of-the-art in terms of automation, high availability, or security. We will address these aspects throughout this documentation when relevant. In any case, we decline all responsibility in the event of damages, theft of crypto-assets, operational or security incidents, as detailed further in the LICENSE.txt file.

Additionally, this code doesn't leverage all the options provided by octez and Tezpay. We encourage you to read the documentation for these tools and enhance your setup, transforming this basic configuration into something remarkable.
- octez: https://tezos.gitlab.io/index.html
- Tezpay: https://docs.tez.capital/tezpay/tutorials/ 


## Release management

- Versions are numbered in the same way as those of the Tezos Gitlab repository, on which they are based. (See https://gitlab.com/tezos/tezos/-/releases). Before v20.0, they were based on Serokell's 'tezos-packaging' repository (See https://github.com/serokell/tezos-packaging).
- Underlying tags are named according to the same version number, with references to the active and replaced protocol names. Before v18.1-1, only the major version number was used.


## Prerequisites

This code is designed to run on a x86_64 Linux platform.

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

- Ensure `/usr/local/bin` is part of the `PATH` environment variable on your machine.
- Copy the files located in the `usr/local/bin` directory of this repository to the `/usr/local/bin` directory on your machine.
- Make sure all the `install-*.sh`, `start-*.sh`, `stop-*.sh`, and `tezos-*.sh` files located there are executable by the users intended to run them (see [Operating instructions](#operating-instructions) above).
- Create a file `/usr/local/bin/tezos-env.sh` by copying `/usr/local/bin/tezos-env.sh.template`. Some variables need configuration and should persist over upgrades:
    - `BAKER_ARCH`: The hardware architecture you use for baking. Currently, the supported values are 'amd64' and 'arm64'.
    - `DATA_DIR`: The directory where the data needed by octez and Tezpay will be stored (requires large storage space).
    - `KEY_BAKER`: This should be the friendly name you would like to use as an alias for your baker address when managing your baker. This name is not shared publicly; it is used only locally.
    - `BAKER_ACCOUNT_HASH`: The tzXXX address of your baker.
    - `BAKER_LIQUIDITY_BAKING_SWITCH`: The liquidity baking vote (off, on, or pass). See https://tezos.gitlab.io/active/liquidity_baking.html for more details.
    - `BAKER_LIMIT_STAKING_OVER_BAKING`: How many times your stake, ranging from 0 (no staking) to 5 (max allowed by the protocol), you allow others to stake with your baker.
    - `BAKER_EDGE_BAKING_OVER_STAKING`: Proportion from 0 (0%) to 1 (100%) of the reward that your baker receives from the amount staked by stakers.
    - `TEZPAY_ACCOUNT_HASH`: The tzYYY address of your payout account.
    - `TEZPAY_FEES`: The baking fee you wish to charge your delegators, ranging from 0 (0%) to 1 (100%).
- Make `/usr/local/bin/tezos-env.sh` executable by the users intended to run it (see [Operating instructions](#operating-instructions) above).
- Next, follow the step-by-step instructions in the `initial-setup.sh` file from this repository. Don't execute this file as a script. Instead, copy and run the instructions one at a time, as you'll be prompted to take several actions throughout the process. These actions are described in the comments appearing in this file.


### Maintenance

The `maintenance-cheat-sheet.sh` file includes the following sections:
- **Restart/Reboot**: Instructions for when you need to restart, possibly due to reasons such as Linux distribution maintenance.
- **Upgrade octez**: Steps for updating when a new version of octez is released. This section also covers Tezos protocol upgrades.
- **Upgrade TezPay**: Procedures for when a new version of TezPay is available.
- **Stake management**: Guidelines on setting your baker's deposit limit and replenishing your payout account.
- **Voting process**: Help on how to vote at the various stages of the Tezos amendment and voting process (https://tezos.gitlab.io/active/voting.html).

Don't execute this file as a script. Instead, copy and run the instructions of the section that interests you one at a time, as you'll be prompted to take several actions throughout the process. These actions are described in the comments appearing in this file.


### Upgrade from previous version
A new variable, `BAKER_ARCH`, has been introduced in `usr/local/bin/tezos-env.sh` to specify the hardware architecture used for baking. This ensures that the corresponding octez and Tezpay executables are downloaded and installed. Please refer to the [Initial setup](#initial-setup) section above for more details.

Another significant change is the use of the Tezpay extension [payouts-substitutor](https://github.com/LaBoulange/tezpay-extensions), which redirects the payout of rewards due to 'oven' type contracts to the owners of these contracts. Indeed, the operation of these contracts deprives them of rewards when balance movements are applied to them because their balance update mechanism involves a temporary passage through a zero balance (more details [here on the Tezos Agora](https://forum.tezosagora.org/t/tez-capital-resolving-kt-delegator-payment-issues-in-paris/6256?u=boulange)), which, since the Paris protocol, results in the cancellation of the reward for the concerned cycle.

These two changes involve the last two steps of the list below:

- Copy the files located in the `usr/local/bin` directory of this repository to the `/usr/local/bin` directory on your machine.
- Make sure all the `install-*.sh`, `start-*.sh`and `stop-*.sh` files located there are executable by the users intended to run them.
- Add the following line to `/usr/local/bin/tezos-env.sh` just before the ``. `which tezos-constants.sh` `` statement (if in doubt, please refer to `usr/local/bin/tezos-env.sh.template` for guidance):
    - `export BAKER_ARCH='amd64'` or `export BAKER_ARCH='arm64'` depending on the architecture you are using for baking.
- Update your Tezpay `config.hjson` file to enable `payouts-substitutor` extension by including the following configuration block. Additional configuration options are available in the [payouts-substitutor's documentation](https://github.com/LaBoulange/tezpay-extensions). For practical implementation, please refer to the `initial-setup.sh` file in this repository:

  extensions: [
      {
          name: payouts-substitutor
          command: /usr/local/bin/payouts-substitutor
          args: [
          ]
          kind: stdio
          configuration: {
              RPC_NODE: 127.0.0.1:8732
          }
          hooks: [
              {
                  id: after_candidates_generated
                  mode: rw
              }
          ]
      }
  ] 

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
