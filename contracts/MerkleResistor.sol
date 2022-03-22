// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/IERC20.sol";
import "./MerkleLib.sol";

contract MerkleResistor {
    using MerkleLib for bytes32;

    uint public numTrees = 0;

    struct Tranche {
        uint totalCoins;
        uint currentCoins;
        uint startTime;
        uint endTime;
        uint coinsPerSecond;
        uint lastWithdrawalTime;
    }

    struct MerkleTree {
        bytes32 merkleRoot;
        bytes32 ipfsHash;
        uint minEndTime; // offsets
        uint maxEndTime; // offsets
        uint pctUpFront;
        address tokenAddress;
        uint tokenBalance;
    }

    mapping (address => mapping (uint => bool)) public initialized;
    mapping (uint => MerkleTree) public merkleTrees;
    mapping (address => mapping (uint => Tranche)) public tranches;

    uint constant public PRECISION = 1000000;
    uint constant public ERROR_TOLERANCE = 1;

    event WithdrawalOccurred(address indexed destination, uint numTokens, uint tokensLeft, uint indexed merkleIndex);
    event MerkleTreeAdded(uint indexed index, address indexed tokenAddress, bytes32 newRoot, bytes32 ipfsHash);

    function addMerkleTree(bytes32 newRoot, bytes32 ipfsHash, uint minEndTime, uint maxEndTime, uint pctUpFront, address depositToken, uint tokenBalance) public {
        require(pctUpFront < 100, 'pctUpFront >= 100');
        require(minEndTime < maxEndTime, 'minEndTime must be less than maxEndTime');
        merkleTrees[++numTrees] = MerkleTree(
            newRoot,
            ipfsHash,
            minEndTime,
            maxEndTime,
            pctUpFront,
            depositToken,
            0
        );
        depositTokens(numTrees, tokenBalance);
        emit MerkleTreeAdded(numTrees, depositToken, newRoot, ipfsHash);
    }

    function depositTokens(uint numTree, uint value) public {
        MerkleTree storage merkleTree = merkleTrees[numTree];
        require(IERC20(merkleTree.tokenAddress).transferFrom(msg.sender, address(this), value), "ERC20 transfer failed");
        merkleTree.tokenBalance += value;
    }

    function initialize(uint merkleIndex, address destination, uint vestingTime, uint minTotalPayments, uint maxTotalPayments, bytes32[] memory proof) external {
        require(msg.sender == destination, 'Can only initialize your own tranche');
        require(!initialized[destination][merkleIndex], "Already initialized");
        bytes32 leaf = keccak256(abi.encode(destination, minTotalPayments, maxTotalPayments));
        MerkleTree memory tree = merkleTrees[merkleIndex];
        require(tree.merkleRoot.verifyProof(leaf, proof), "The proof could not be verified.");
        initialized[destination][merkleIndex] = true;

        (bool valid, uint totalCoins, uint coinsPerSecond, uint startTime) = verifyVestingSchedule(merkleIndex, vestingTime, minTotalPayments, maxTotalPayments);
        require(valid, 'Invalid vesting schedule');

        tranches[destination][merkleIndex] = Tranche(
            totalCoins,
            totalCoins,
            startTime,
            block.timestamp + vestingTime,
            coinsPerSecond,
            startTime
        );
        withdraw(merkleIndex, destination);
    }

    function withdraw(uint merkleIndex, address destination) public {
        require(initialized[destination][merkleIndex], "You must initialize your account first.");
        Tranche storage tranche = tranches[destination][merkleIndex];
        MerkleTree memory tree = merkleTrees[merkleIndex];
        require(tranche.currentCoins >  0, 'No coins left to withdraw');
        uint currentWithdrawal = 0;

        // if after vesting period ends, give them the remaining coins
        if (block.timestamp >= tranche.endTime) {
            currentWithdrawal = tranche.currentCoins;
        } else {
            // compute allowed withdrawal
            currentWithdrawal = (block.timestamp - tranche.lastWithdrawalTime) * tranche.coinsPerSecond;
        }
        require(tree.tokenBalance >= currentWithdrawal, "Token balance of the tree too low");

        // update struct
        tranche.currentCoins -= currentWithdrawal;
        tranche.lastWithdrawalTime = block.timestamp;

        // transfer the tokens, brah
        IERC20(tree.tokenAddress).transfer(destination, currentWithdrawal);
        tree.tokenBalance -= currentWithdrawal;
        emit WithdrawalOccurred(destination, currentWithdrawal, tranche.currentCoins, merkleIndex);
    }

    function verifyVestingSchedule(uint merkleIndex, uint vestingTime, uint minTotalPayments, uint maxTotalPayments) public view returns (bool, uint, uint, uint) {
        if (merkleIndex > numTrees) {
            return (false, 0, 0, 0);
        }

        MerkleTree memory tree = merkleTrees[merkleIndex];

        if (vestingTime > tree.maxEndTime || vestingTime < tree.minEndTime) {
            return (false, 0, 0, 0);
        }

        uint totalCoins;
        if (vestingTime == tree.maxEndTime) {
            totalCoins = maxTotalPayments;
        } else {
            uint paymentSlope = (maxTotalPayments - minTotalPayments) * PRECISION / (tree.maxEndTime - tree.minEndTime);
            totalCoins = (paymentSlope * (vestingTime - tree.minEndTime) / PRECISION) + minTotalPayments;
        }

        uint coinsPerSecond = (totalCoins * (uint(100) - tree.pctUpFront)) / (vestingTime * 100);
        uint startTime = block.timestamp + vestingTime - (totalCoins / coinsPerSecond);

        return (true, totalCoins, coinsPerSecond, startTime);
    }

}
