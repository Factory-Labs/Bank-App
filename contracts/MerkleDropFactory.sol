// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/IERC20.sol";
import "./MerkleLib.sol";

contract MerkleDropFactory {
    using MerkleLib for bytes32;

    uint public numTrees = 0;

    struct MerkleTree {
        bytes32 merkleRoot;
        bytes32 ipfsHash;
        address tokenAddress;
        uint tokenBalance;
        uint spentTokens;
    }

    mapping (address => mapping (uint => bool)) public withdrawn;
    mapping (uint => MerkleTree) public merkleTrees;

    event Withdraw(uint indexed merkleIndex, address indexed recipient, uint value);
    event MerkleTreeAdded(uint indexed index, address indexed tokenAddress, bytes32 newRoot, bytes32 ipfsHash);

    function addMerkleTree(bytes32 newRoot, bytes32 ipfsHash, address depositToken, uint tokenBalance) public {
        merkleTrees[++numTrees] = MerkleTree(
            newRoot,
            ipfsHash,
            depositToken,
            0,
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

    function withdraw(uint merkleIndex, address walletAddress, uint value, bytes32[] memory proof) public {
        require(merkleIndex <= numTrees, "Provided merkle index doesn't exist");
        require(!withdrawn[walletAddress][merkleIndex], "You have already withdrawn your entitled token.");
        bytes32 leaf = keccak256(abi.encode(walletAddress, value));
        MerkleTree storage tree = merkleTrees[merkleIndex];
        require(tree.tokenBalance >= value, "Token balance of the tree too low");
        require(tree.merkleRoot.verifyProof(leaf, proof), "The proof could not be verified.");
        withdrawn[walletAddress][merkleIndex] = true;
        require(IERC20(tree.tokenAddress).transfer(walletAddress, value), "ERC20 transfer failed");
        tree.tokenBalance -= value;
        tree.spentTokens += value;
        emit Withdraw(merkleIndex, walletAddress, value);
    }

}