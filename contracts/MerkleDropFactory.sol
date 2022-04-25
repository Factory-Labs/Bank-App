// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/IERC20.sol";
import "./MerkleLib.sol";

// This contract is for anyone to create a merkledrop, that is, an airdrop using merkleproofs to compute eligibility
contract MerkleDropFactory {
    using MerkleLib for bytes32;

    // the number of airdrops in this contract
    uint public numTrees = 0;

    // this represents a single airdrop
    struct MerkleTree {
        bytes32 merkleRoot;  // merkleroot of tree whose leaves are (address,uint) pairs representing amount owed to user
        bytes32 ipfsHash; // ipfs hash of entire dataset, as backup in case our servers turn off...
        address tokenAddress; // address of token that is being airdropped
        uint tokenBalance; // amount of tokens allocated for this tree
        uint spentTokens; // amount of tokens dispensed from this tree
    }

    // withdrawn[recipient][treeIndex] = hasUserWithdrawnAirdrop
    mapping (address => mapping (uint => bool)) public withdrawn;

    // array-like map for all ze merkle trees (airdrops)
    mapping (uint => MerkleTree) public merkleTrees;

    // every time there's a withdraw
    event Withdraw(uint indexed merkleIndex, address indexed recipient, uint value);
    // every time a tree is added
    event MerkleTreeAdded(uint indexed index, address indexed tokenAddress, bytes32 newRoot, bytes32 ipfsHash);

    // anyone can add a new airdrop
    function addMerkleTree(bytes32 newRoot, bytes32 ipfsHash, address depositToken, uint tokenBalance) public {
        // prefix operator ++ increments then evaluates
        merkleTrees[++numTrees] = MerkleTree(
            newRoot,
            ipfsHash,
            depositToken,
            0,  // ain't no tokens in here yet
            0   // ain't nobody claimed no tokens yet either
        );
        // you don't get to add a tree without funding it
        depositTokens(numTrees, tokenBalance);
        emit MerkleTreeAdded(numTrees, depositToken, newRoot, ipfsHash);
    }

    // anyone can fund any tree
    function depositTokens(uint treeIndex, uint value) public {
        // storage since we are editing
        MerkleTree storage merkleTree = merkleTrees[treeIndex];

        // bookkeeping to make sure trees don't share tokens
        merkleTree.tokenBalance += value;

        // transfer tokens, if this is a malicious token, then this whole tree is malicious
        // but it does not effect the other trees
        require(IERC20(merkleTree.tokenAddress).transferFrom(msg.sender, address(this), value), "ERC20 transfer failed");
    }

    // anyone can withdraw anyone else's tokens, altho they always go to the right destination
    // msg.sender is not used in this function
    function withdraw(uint merkleIndex, address walletAddress, uint value, bytes32[] memory proof) public {
        // no withdrawing from uninitialized merkle trees
        require(merkleIndex <= numTrees, "Provided merkle index doesn't exist");
        // no withdrawing same airdrop twice
        require(!withdrawn[walletAddress][merkleIndex], "You have already withdrawn your entitled token.");
        // compute merkle leaf, this is first element of proof
        bytes32 leaf = keccak256(abi.encode(walletAddress, value));
        // storage because we edit
        MerkleTree storage tree = merkleTrees[merkleIndex];
        // this calls to MerkleLib, will return false if recursive hashes do not end in merkle root
        require(tree.merkleRoot.verifyProof(leaf, proof), "The proof could not be verified.");
        // close re-entrance gate, prevent double claims
        withdrawn[walletAddress][merkleIndex] = true;
        // update struct
        tree.tokenBalance -= value;
        tree.spentTokens += value;
        // transfer the tokens
        // NOTE: if the token contract is malicious this call could re-enter this function
        // which will fail because withdrawn will be set to true
        require(IERC20(tree.tokenAddress).transfer(walletAddress, value), "ERC20 transfer failed");
        emit Withdraw(merkleIndex, walletAddress, value);
    }

}