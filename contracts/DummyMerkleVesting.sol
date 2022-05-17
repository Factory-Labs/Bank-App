// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.12;

import "../interfaces/IERC20.sol";
import "./MerkleLib.sol";

contract DummyMerkleVesting {
    using MerkleLib for bytes32;

    mapping (uint => bytes32) public merkleRoots;
    uint public numRoots;
    IERC20 public token;

    uint public initialBalance;

    struct Tranche {
        uint totalCoins;
        uint currentCoins;
        uint startTime;
        uint endTime;
        uint coinsPerSecond;
        uint lastWithdrawalTime;
    }

    mapping (address => bool) public initialized;
    mapping (address => Tranche) public tranches;

    event WithdrawalOccurred(address destination, uint numTokens, uint tokensLeft);
    event MerkleRootAdded(uint indexed index, bytes32 newRoot);

    constructor(IERC20 _token, bytes32 _root) {
        token = _token;
        merkleRoots[1] = _root;
        numRoots = 1;
    }

    function addMerkleRoot(bytes32 newRoot) public {
        merkleRoots[++numRoots] = newRoot;
        emit MerkleRootAdded(numRoots, newRoot);
    }

    function initialize(uint merkleIndex, address destination, uint totalCoins, uint startTime, uint endTime, bytes32[] memory proof) external {
        require(!initialized[destination], "Already initialized");
        bytes32 leaf = keccak256(abi.encodePacked(destination, totalCoins, startTime, endTime));

        require(merkleRoots[merkleIndex].verifyProof(leaf, proof), "The proof could not be verified.");
        initialized[destination] = true;
        uint coinsPerSecond = totalCoins / (endTime - startTime);
        tranches[destination] = Tranche(
            totalCoins,
            totalCoins,
            startTime,
            endTime,
            coinsPerSecond,
            startTime
        );
        withdraw(destination);
    }

    function withdraw(address destination) internal {
        require(initialized[destination], "You must initialize your account first.");
        Tranche storage tranche = tranches[destination];
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

        // transfer the tokens, brah
        token.transfer(destination, currentWithdrawal);
        emit WithdrawalOccurred(destination, currentWithdrawal, tranche.currentCoins);
    }

}