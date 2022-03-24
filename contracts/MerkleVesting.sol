// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/IERC20.sol";
import "./MerkleLib.sol";

contract MerkleVesting {
    using MerkleLib for bytes32;

    uint public numTrees = 0;
    
    struct Tranche {
        uint totalCoins;
        uint currentCoins;
        uint startTime;
        uint endTime;
        uint coinsPerSecond;
        uint lastWithdrawalTime;
        uint lockPeriodEndTime;
    }

    struct MerkleTree {
        bytes32 rootHash;
        bytes32 ipfsHash;
        address tokenAddress;
        uint tokenBalance;
    }

    mapping (address => mapping (uint => bool)) public initialized;
    mapping (uint => MerkleTree) public merkleTrees;
    mapping (address => mapping (uint => Tranche)) public tranches;

    event WithdrawalOccurred(address indexed destination, uint numTokens, uint tokensLeft, uint indexed merkleIndex);
    event MerkleRootAdded(uint indexed index, address indexed tokenAddress, bytes32 newRoot);

    /*
        Root hash should be built out of following data:
        - destination
        - totalCoins
        - startTime
        - endTime
        - lockPeriodEndTime
    */
    function addMerkleRoot(bytes32 rootHash, bytes32 ipfsHash, address tokenAddress, uint tokenBalance) {
        merkleTrees[++numRoots] = MerkleTree(rootHash, ipfsHash, tokenAddress, tokenBalance);
        depositTokens(numRoots, tokenBalance);
        emit MerkleRootAdded(numRoots, tokenAddress, newRoot);
    }

    function depositTokens(uint numTree, uint value) public {
        MerkleTree storage merkleTree = merkleTrees[numTree];
        require(IERC20(merkleTree.tokenAddress).transferFrom(msg.sender, address(this), value), "ERC20 transfer failed");
        merkleTree.tokenBalance += value;
    }

    function initialize(uint merkleIndex, address destination, uint totalCoins, uint startTime, uint endTime, uint lockPeriodEndTime, bytes32[] memory proof) external {
        require(!initialized[destination][merkleIndex], "Already initialized");
        bytes32 leaf = keccak256(abi.encodePacked(destination, totalCoins, startTime, endTime, lockPeriodEndTime));

        require(merkleRoots[merkleIndex].verifyProof(leaf, proof), "The proof could not be verified.");
        initialized[destination][merkleIndex] = true;
        uint coinsPerSecond = totalCoins / (endTime - startTime);
        tranches[destination][merkleIndex] = Tranche(
            totalCoins,
            totalCoins,
            startTime,
            endTime,
            coinsPerSecond,
            startTime,
            lockPeriodEndTime
        );
        if (lockPeriodEndTime < block.timestamp) {
            withdraw(merkleIndex, destination);
        }
    }

    function withdraw(uint merkleIndex, address destination) internal {
        require(initialized[destination][merkleIndex], "You must initialize your account first.");
        Tranche storage tranche = tranches[destination][merkleIndex];
        require(block.timestamp > tranche.lockPeriodEndTime, 'Must wait until after lock period');
        require(tranche.currentCoins >  0, 'No coins left to withdraw');
        uint currentWithdrawal = 0;

        // if after vesting period ends, give them the remaining coins
        if (block.timestamp >= tranche.endTime) {
            currentWithdrawal = tranche.currentCoins;
        } else {
            // compute allowed withdrawal
            currentWithdrawal = (block.timestamp - tranche.lastWithdrawalTime) * tranche.coinsPerSecond;
        }

        // update struct
        tranche.currentCoins -= currentWithdrawal;
        tranche.lastWithdrawalTime = block.timestamp;

        MerkleTree storage tree = merkleTrees[merkleIndex];
        tree.tokenBalance -= currentWithdrawal;

        // transfer the tokens, brah
        token.transfer(destination, currentWithdrawal);
        emit WithdrawalOccurred(destination, currentWithdrawal, tranche.currentCoins, merkleIndex);
    }

}