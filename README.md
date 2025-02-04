# Merkle-Based Token Distribution System

A collection of smart contracts implementing scalable token distribution and vesting mechanisms using Merkle proofs.

## Repository Structure

```
└── ./
    ├── contracts/
    │   ├── MerkleDropFactory.sol
    │   ├── MerkleLib.sol
    │   ├── MerkleResistor.sol
    │   ├── MerkleVesting.sol
    │   └── readme.md
    ├── Bank Report by Consensys Due Dilligence 05_2023.pdf 
    └── LICENSE.md
```

## Core Contracts

1. **MerkleDropFactory.sol** - Implements permissionless token airdrops using Merkle proofs
2. **MerkleVesting.sol** - Provides fixed vesting schedules with linear token release
3. **MerkleResistor.sol** - Enables user-configurable vesting schedules with customizable parameters
4. **MerkleLib.sol** - Common library for Merkle proof verification

## Security Audits

The contracts have undergone multiple security reviews:

1. Bank Report by Consensys Due Dilligence 05_2023.pdf - Available in repo. This report was produced with regards to a package of work carried out by Factory Labs. 
2. [Code4rena Factory DAO Audit](https://code4rena.com/reports/2022-05-factorydao) - Additional review of Bank-related contracts

## Features

- Permissionless token distribution system
- Multiple independent token distributions in single contracts
- Merkle proof-based claim verification
- Flexible vesting schedules
- Protection against double-claiming
- Fee-on-transfer token support
- Isolation between different token distributions
- IPFS data redundancy

## License

GPL-3.0-only
