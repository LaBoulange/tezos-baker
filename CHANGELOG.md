All notable changes are documented in this file.

## v23.2 - 2025-09-12

- New version of `octez`: Seoul protocol (Rio still active).
- Switched from protocol-specific to agnostic baker and accuser

## v22.1 - 2025-06-15

- New version of `octez` (bugfixes): Rio protocol.
- Removed Mailchain contact: unused
- Added swap to the minimal harware requirements

## v22.0 - 2025-04-14

- New version of `octez`: Rio protocol (Quebec still active).
- Added a delay between the startup of the Etherlink node and its health check

## v21.4 - 2025-02-28

- New version of `octez` (technical enhancements and fixes): Quebec protocol. 
- Corrected documentation mistakes

## v21.3_2 - 2025-01-27

- Introduced the NODE_NETWORK configuration variable to enable deploying on ghostnet, mainnet, or any other network.
- Integrated the Etherlink Smart Rollup observer node (optional).
- Removal of the deprecated `payouts-substitutor` Tezpay extension.

## v21.3 - 2025-01-25

- New version of `octez` (minor technical enhancements): Quebec protocol. 
- start-octez.sh: Longer pause time after node startup before starting DAL, baker and accuser
- stop-octez.sh: Separate stopping of the DAL node

## v21.1_2 - 2025-01-19

- DAL node integration.

## v21.1 - 2024-12-21

- New version of `octez`: Quebec protocol (ParisC still active).

## v21.0 - 2024-11-15

- New version of `octez`: Quebec protocol (ParisC still active).
- Documentation: delegators payment is made optional

## v20.3 - 2024-10-03

- New version of `octez` (new storage version): ParisC protocol. 
- Made the node history mode configurable
- Changed the default configuration values for staking

## v20.2 - 2024-07-17

- New version of `octez` (minor bug fix): ParisC protocol. 

## v20.1_2 - 2024-06-30

- Corrections and clarifications in the documentation
- Made the maintenance cheat-sheet consistent with the new upgrade process introduced in v20.1
- Payouts account delegation to the baker
- Tezpay Payout Fixer installation without activation (Tezpay is running in continual mode by default)

## v20.1 - 2024-06-19

- Added this changelog.
- Added updater executable `install-tezos-baker.sh`.
- New version of `octez` (critical bug fix): ParisC protocol (ParisB still active). 

## v20.0_2 - 2024-06-17

- Integration of the `payouts-substitutor` Tezpay extension.
- arm64 support (formerly: amd64 only).
- Proper support for any `user:group` configuration in executable permission settings.
- Minor enhancements.

## v20.0 - 2024-05-29

- New version of `octez`: ParisB protocol (Oxford2 still active). 
- Switched from Serokell to Tezos Gitlab packaging.

## v19.2-1 - 2024-04-18

- New version of `octez` (security fix): Oxford2 protocol. Serokell packaging.

## v19.1-1 - 2024-02-08

- New version of `octez` (security fix): Oxford2 protocol. Serokell packaging.

## v19.0-1 - 2024-01-24

- New version of `octez`: Oxford2 protocol (Nairobi still active). Serokell packaging.

## v18.1-1 - 2023-11-21

- New version of `octez`: Nairobi protocol. Serokell packaging.

## v18.0-4 - 2023-11-10

- New version of `octez` (optimization): Nairobi protocol. Serokell packaging.

## v17.3-3 - 2023-11-10

- Initial release, packaged late: Nairobi protocol (Mumbai still active). Serokell packaging.
