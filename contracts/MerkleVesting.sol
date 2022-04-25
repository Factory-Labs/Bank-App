// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/IERC20.sol";
import "./MerkleLib.sol";

// This contract is for anyone to create a vesting schedule (time release) for their tokens, using merkle trees to scale
contract MerkleVesting {
    using MerkleLib for bytes32;

    // the number of vesting schedules in this contract
    uint public numTrees = 0;
    
    // this represents a single vesting schedule for a specific address
    struct Tranche {
        uint totalCoins;  // total number of coins released to an address after vesting is completed
        uint currentCoins; // how many coins are left unclaimed by this address, vested or unvested
        uint startTime; // when the vesting schedule is set to start, possibly in the past
        uint endTime;  // when the vesting schedule will have released all coins
        uint coinsPerSecond; // an intermediate value cached to reduce gas costs, how many coins released every second
        uint lastWithdrawalTime; // the last time a withdrawal occurred, used to compute unvested coins
        uint lockPeriodEndTime; // the first time at which coins may be withdrawn
    }

    // this represents a set of vesting schedules all in the same token
    struct MerkleTree {
        bytes32 rootHash;  // merkleroot of tree whose leaves are (address,uint,uint,uint,uint) representing vesting schedules
        bytes32 ipfsHash; // ipfs hash of entire dataset, used to reconstruct merkle proofs if our servers go down
        address tokenAddress; // token that the vesting schedules will be denominated in
        uint tokenBalance; // current amount of tokens deposited to this tree, used to make sure trees don't share tokens
    }

    // initialized[recipient][treeIndex] = wasItInitialized?
    mapping (address => mapping (uint => bool)) public initialized;

    // array-like sequential map for all the vesting schedules
    mapping (uint => MerkleTree) public merkleTrees;

    // tranches[recipient][treeIndex] = initializedVestingSchedule
    mapping (address => mapping (uint => Tranche)) public tranches;

    // every time there's a withdrawal
    event WithdrawalOccurred(address indexed destination, uint numTokens, uint tokensLeft, uint indexed merkleIndex);

    // every time a tree is added
    event MerkleRootAdded(uint indexed index, address indexed tokenAddress, bytes32 newRoot);

    /*
        Anyone can add a vesting schedule
        Root hash should be built out of following data:
        - destination
        - totalCoins
        - startTime
        - endTime
        - lockPeriodEndTime
    */
    function addMerkleRoot(bytes32 rootHash, bytes32 ipfsHash, address tokenAddress, uint tokenBalance) public {
        merkleTrees[++numTrees] = MerkleTree(rootHash, ipfsHash, tokenAddress, 0);
        depositTokens(numTrees, tokenBalance);
        emit MerkleRootAdded(numTrees, tokenAddress, rootHash);
    }

    // used to top-up trees if they are not sufficiently funded
    // NOTE: if the tree is over-funded, there is no way to get the tokens out, this is intentional
    function depositTokens(uint numTree, uint value) public {
        // storage since we are editing
        MerkleTree storage merkleTree = merkleTrees[numTree];

        // bookkeeping to make sure trees don't share tokens
        merkleTree.tokenBalance += value;

        // transfer tokens, if this is a malicious token, then this whole tree is malicious
        // but it does not effect the other trees
        require(IERC20(merkleTree.tokenAddress).transferFrom(msg.sender, address(this), value), "ERC20 transfer failed");
    }

    // called once by anyone to initialize a specific recipients vesting schedule
    function initialize(uint merkleIndex, address destination, uint totalCoins, uint startTime, uint endTime, uint lockPeriodEndTime, bytes32[] memory proof) external {
        // must not initialize multiple times
        require(!initialized[destination][merkleIndex], "Already initialized");
        // leaf hash is digest of vesting schedule parameters and destination
        // NOTE: use abi.encode, not abi.encodePacked to avoid possible (but unlikely) collision
        bytes32 leaf = keccak256(abi.encode(destination, totalCoins, startTime, endTime, lockPeriodEndTime));
        // memory because we read only
        MerkleTree memory tree = merkleTrees[merkleIndex];
        // call to MerkleLib to check if the submitted data is correct
        require(tree.rootHash.verifyProof(leaf, proof), "The proof could not be verified.");
        // set initialized, preventing double initialization
        initialized[destination][merkleIndex] = true;
        // precompute how many coins are released per second
        uint coinsPerSecond = totalCoins / (endTime - startTime);
        // create the tranche struct and assign it
        tranches[destination][merkleIndex] = Tranche(
            totalCoins,  // total coins to be released
            totalCoins,  // currentCoins starts as totalCoins
            startTime,
            endTime,
            coinsPerSecond,
            startTime,
            lockPeriodEndTime
        );
        // if we've passed the lock time go ahead and perform a withdrawal now
        if (lockPeriodEndTime < block.timestamp) {
            withdraw(merkleIndex, destination);
        }
    }

    // anybody can trigger the withdrawal of anyone else's tokens
    function withdraw(uint merkleIndex, address destination) public {
        // cannot withdraw from an uninitialized vesting schedule
        require(initialized[destination][merkleIndex], "You must initialize your account first.");
        // storage because we will modify it
        Tranche storage tranche = tranches[destination][merkleIndex];
        // no withdrawals before lock time ends
        require(block.timestamp > tranche.lockPeriodEndTime, 'Must wait until after lock period');
        // revert if there's nothing left
        require(tranche.currentCoins >  0, 'No coins left to withdraw');

        // declaration for branched assignment
        uint currentWithdrawal = 0;

        // if after vesting period ends, give them the remaining coins
        if (block.timestamp >= tranche.endTime) {
            currentWithdrawal = tranche.currentCoins;
        } else {
            // compute allowed withdrawal
            currentWithdrawal = (block.timestamp - tranche.lastWithdrawalTime) * tranche.coinsPerSecond;
        }

        // decrease allocation of coins
        tranche.currentCoins -= currentWithdrawal;
        // this makes sure coins don't get double withdrawn
        tranche.lastWithdrawalTime = block.timestamp;

        // update the tree balance so trees can't take each other's tokens
        MerkleTree storage tree = merkleTrees[merkleIndex];
        tree.tokenBalance -= currentWithdrawal;

        // Transfer the tokens, if the token contract is malicious, this will make the whole tree malicious
        // but this does not allow re-entrance due to struct updates and it does not effect other trees.
        // It is also generally consistent with the ethereum security model:
        // other contracts do what they want, it's our job to protect our contract
        IERC20(tree.tokenAddress).transfer(destination, currentWithdrawal);
        emit WithdrawalOccurred(destination, currentWithdrawal, tranche.currentCoins, merkleIndex);
    }

}