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
    ├── Bank Prelimanary Audit by Consensus Due Dilligence 05_2023.pdf
    └── LICENSE.md
```

## Core Contracts

1. **MerkleDropFactory.sol** - Implements permissionless token airdrops using Merkle proofs
2. **MerkleVesting.sol** - Provides fixed vesting schedules with linear token release
3. **MerkleResistor.sol** - Enables user-configurable vesting schedules with customizable parameters
4. **MerkleLib.sol** - Common library for Merkle proof verification

## Contract Mechanics

### Airdrop (MerkleDropFactory)
- **Purpose**: Enable efficient distribution of tokens to large numbers of recipients
- **Process**:
  1. Deployer creates Merkle tree from `(address, amount)` pairs
  2. Tree root is stored on-chain with total token amount
  3. Recipients claim by providing Merkle proof
  4. Contract verifies proof and transfers tokens
- **Features**:
  - Multiple airdrops can run simultaneously
  - Anyone can pay gas for claims
  - Double-claim prevention
  - Tree data stored on IPFS for redundancy

### Simple Vesting (MerkleVesting)
- **Purpose**: Time-locked token distribution with linear release
- **Parameters**:
  - `startTime`: When vesting begins
  - `endTime`: When tokens are fully vested
  - `lockPeriodEndTime`: When withdrawals can start
  - `totalCoins`: Total tokens to be vested
- **Mechanics**:
  - Linear release rate: `coinsPerSecond = totalCoins / (endTime - startTime)`
  - Withdrawals blocked until `lockPeriodEndTime`
  - Full withdrawal available after `endTime`
  - Partial withdrawals based on elapsed time

### Commitment Vesting (MerkleResistor)
- **Purpose**: Incentivize longer lock-up periods with variable rewards
- **Key Concepts**:
  - Longer vesting = More tokens
  - Trade-off between instant and vested amounts
  - User chooses their own schedule within constraints

#### Parameters
- `minEndTime`: Minimum vesting duration
- `maxEndTime`: Maximum vesting duration
- `pctUpFront`: Percentage available immediately
- `minTotalPayments`: Minimum possible token amount
- `maxTotalPayments`: Maximum possible token amount

#### Schedule Calculation
1. User selects `vestingTime` between `minEndTime` and `maxEndTime`
2. Total tokens calculated linearly:
   ```
   slope = (maxPayments - minPayments) / (maxEndTime - minEndTime)
   totalCoins = slope * (vestingTime - minEndTime) + minPayments
   ```
3. Release rate:
   ```
   coinsPerSecond = (totalCoins * (100 - pctUpFront)) / (vestingTime * 100)
   ```

## Security Features

All contracts implement:
- Re-entrancy protection
- Balance tracking per Merkle tree
- Fee-on-transfer token support
- Malicious token isolation
- Safe arithmetic operations (Solidity 0.8.12)
- Double-claim prevention
- Event emission for all state changes

## Security Audits

The contracts have undergone multiple security reviews:

1. Consensus Due Diligence (May 2023) - Available in repo
2. [Code4rena Factory DAO Audit](https://code4rena.com/reports/2022-05-factorydao) - Additional review of Bank-related contracts

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

## License

GPL-3.0-only
