# Merkle-based Token Distribution Contracts

A collection of Solidity smart contracts implementing scalable token distribution mechanisms using Merkle proofs. These contracts enable efficient airdrops and vesting schedules for ERC20 tokens.

## Overview

The repository contains four main contracts:

1. **MerkleDropFactory**: Implements airdrops using Merkle proofs
2. **MerkleVesting**: Implements fixed vesting schedules using Merkle proofs
3. **MerkleResistor**: Implements user-configurable vesting schedules with trade-offs
4. **MerkleLib**: Common library for Merkle proof verification

## Core Features

### MerkleDropFactory
- Permissionless token airdrop system
- Multiple independent airdrops in one contract
- Recipients claim tokens by providing Merkle proofs
- Prevents double-claiming through withdrawal tracking
- IPFS hash storage for data redundancy

### MerkleVesting
- Time-locked token distribution with vesting periods
- Fixed vesting schedules defined at creation
- Parameters: recipient, total amount, start time, end time, lock period
- Linear release rate (coins per second)
- Protection against double-withdrawals

### MerkleResistor
- User-configurable vesting schedules
- Trade-off system between vesting duration and token amounts
- Percentage of tokens available upfront
- Min/max vesting time constraints
- Linear vesting with configurable parameters

## Security Features

All contracts implement:
- Re-entrancy protection
- Balance tracking per Merkle tree
- Fee-on-transfer token support
- Malicious token isolation (problems with one tree don't affect others)
- Safe arithmetic operations (Solidity 0.8.12)

## Contract Interactions

### Creating an Airdrop/Vesting Schedule
1. Generate Merkle tree off-chain
2. Deploy using `addMerkleTree`/`addMerkleRoot`
3. Fund with tokens using `depositTokens`

### Claiming Tokens
1. Recipient provides Merkle proof of inclusion
2. Contract verifies proof against stored root
3. If valid, tokens are transferred to recipient
4. Claim is recorded to prevent double-claiming

## Important Notes

- All contracts are permissionless and public-facing
- Trees cannot introspect into Merkle data except during proof verification
- Over-funding trees is possible but funds cannot be recovered
- Token contract malice can only affect its own tree

## Technical Details

### MerkleLib
```solidity
function verifyProof(bytes32 root, bytes32 leaf, bytes32[] proof) public pure returns (bool)
```
- Verifies Merkle proofs using ordered hash pair concatenation
- Used by all main contracts for proof validation

### Common Storage Patterns
All contracts use:
- Sequential tree indexing
- Mapping-based storage for scalability
- Separate balance tracking per tree
- Event emission for important state changes

## License
GPL-3.0-only