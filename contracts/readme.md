#  Bank
- MerkleLib.sol: 17 lines of code, 0 external calls, 0 libraries. Library for extremely efficient merkle proof verification. (AUDITED)
- MerkleDropFactory.sol: 48 lines of code, 2 calls to external ERC20, 1 library. Permissionless scalable airdrops using merkle trees (AUDITED)
- MerkleVesting.sol: 82 lines of code, 2 calls to external ERC20, 1 library. Permissionless scalable linear token vesting using merkle trees (AUDITED)
- MerkleResistor.sol: 107 lines of code, 2 calls to external ERC20, 1 library Permissionless scalable user-chosen token vesting using merkle trees (AUDITED)

MerkleVesting.sol


This smart contract is used for token vesting purposes, with the help of a Merkle tree. The contract allows you to define a vesting schedule for token distribution based on predetermined conditions. The Merkle tree is used to prove the validity of token allocations without revealing the entire dataset. This allows for secure and efficient token vesting, ensuring that the tokens are released to the rightful recipients over time.


Variables

token: The token that will be vested and claimed by users.
merkleRoot: The root of the Merkle tree containing the token distribution data.
claimed: A mapping of users to their claimed token amounts.

Functions

constructor: Initializes the contract with the token address and Merkle tree root.

Token Management Functions

claim: Allows users to claim their vested tokens by providing the index, amount, and Merkle proof.
isClaimed: Returns true if the user has claimed their tokens, false otherwise.
_verifyClaim: Internal function to verify the user's claim against the Merkle tree.
recover: Allows the contract owner to recover any ERC20 tokens accidentally sent to the contract.
tokenRecovered: This is an event emitted when the contract owner recovers any ERC20 tokens accidentally sent to the contract. It includes the token address and the amount recovered.
Events

Claimed: Emitted when a user successfully claims their vested tokens, providing the user's address, index, and amount claimed.
Errors


InvalidMerkleProof: Thrown when the Merkle proof provided in the claim function is invalid.
AlreadyClaimed: Thrown when the user has already claimed their tokens and tries to claim again.
Dependencies


IERC20: The contract imports the IERC20 interface to interact with the token being vested.
MerkleProof: The contract imports the MerkleProof library from OpenZeppelin to work with Merkle tree proofs.


Interactions with other contracts


The MerkleVesting contract interacts with the token contract by transferring tokens to users upon successful claims.
The MerkleVesting contract interacts with any ERC20 tokens accidentally sent to the contract address, allowing the contract owner to recover them.

Miscellaneous


Ownable: The contract inherits from the Ownable contract, allowing it to have an owner with specific privileges, such as recovering accidentally sent tokens.


MerkleResistor.sol


This contract is designed to manage token distribution using a Merkle tree as well. It's focused on "resistance" to token claim, meaning that the more tokens are claimed by users, the fewer tokens become available for future claims. This creates a supply-demand dynamic, where the value of the unclaimed tokens increases as more tokens are claimed. The contract includes functions to claim tokens, update resistance, and calculate the available token amount for a given user.

The MerkleResistor.sol contract is a staking contract that allows users to stake tokens and earn rewards based on a Merkle tree distribution mechanism. The contract employs the concept of Merkle Proofs for claiming rewards, which allows users to provide a proof that they are entitled to a certain reward without revealing the entire distribution list.

Variables

token: IERC20 - The token that will be staked and distributed.
merkleRoot: bytes32 - The Merkle root of the distribution tree.
totalClaimed: uint256 - The total number of tokens claimed.
claimWindows: mapping(uint256 => uint256) - Mapping of claim windows to end timestamps.
userClaimedAmount: mapping(address => uint256) - Mapping of user addresses to claimed token amounts.
Structs

UserInfo: A struct to store information about a user's claims.
amount: uint256 - The amount of tokens the user has claimed.
claimed: bool - Whether the user has claimed their rewards or not.

The UserInfo struct is not directly used as a state variable in the contract. Instead, it is used in the claim function to temporarily store a user's information while processing their claim.

Functions

constructor: Initializes the token and sets the initial Merkle root.
setClaimWindow: Sets a claim window for a specific week with an end timestamp.
setMerkleRoot: Sets the Merkle root for the distribution tree.
claim: Allows users to claim their rewards by providing the proof of their inclusion in the Merkle tree. The function verifies the proof, checks if the user is eligible for the claim, and transfers the rewards to the user.
withdrawToken: Allows the contract owner to withdraw tokens from the contract.
setToken: Allows the contract owner to set a new token for the contract.
Events

Claimed: Emitted when a user claims their rewards.
MerkleRootUpdated: Emitted when the Merkle root is updated.
ClaimWindowSet: Emitted when a claim window is set.
Errors

InvalidProof: Thrown when the provided Merkle proof is invalid.
AlreadyClaimed: Thrown when the user has already claimed their rewards.
WindowNotSet: Thrown when the claim window is not set.
WindowExpired: Thrown when the claim window has expired.
InsufficientBalance: Thrown when the contract does not have enough balance to distribute rewards.
Dependencies

OpenZeppelin Contracts: A library of secure and community-reviewed smart contracts.
MerkleProof.sol: A contract for verifying Merkle proofs.
Interactions with other contracts

IERC20: Interacts with the IERC20 token contract to handle staking, distribution, and withdrawal of tokens.



MerkleDropFactory.sol


This smart contract acts as a factory to create instances of MerkleDrops, which are essentially token airdrops managed through Merkle trees. The factory allows for easy creation of multiple MerkleDrop contracts, each with its own token distribution conditions. The factory can manage the deployment of multiple MerkleDrop instances, making it easier to track and manage token distributions for various campaigns.

This contract is an implementation of a Merkle Drop Factory that allows the deployment of multiple Merkle Drop contracts, where each contract is created with a specific token and merkle root. The main purpose of this contract is to distribute tokens to users in a permissionless and efficient way, utilizing a Merkle tree data structure.


:
Variables

merkleDistributorImplementation (address): address of the MerkleDistributor implementation contract
merkleDistributorCounter (uint256): counter to keep track of the number of MerkleDistributor instances created
distributors (mapping): a mapping of uint256 (index) to MerkleDistributor instances


Roles


DEFAULT_ADMIN_ROLE: a role that allows updating the MerkleDistributor implementation


Events


MerkleDistributorCreated: an event emitted when a new MerkleDistributor is created, containing creator's address, distributor's address, distributor ID, token address, and merkleRoot


Functions


constructor: initializes the contract, setting the deployer as the admin and initializing the MerkleDistributor implementation
updateMerkleDistributorImplementation: a function to update the MerkleDistributor implementation address (requires DEFAULT_ADMIN_ROLE)
createMerkleDistributor: a function to create a new MerkleDistributor instance and emit the MerkleDistributorCreated event
getMerkleDistributor: a function that returns the address of a specific MerkleDistributor instance using its ID


Dependencies


AccessControl: an OpenZeppelin contract for managing access control and roles
IMerkleDistributorFactory: an interface that the MerkleDropFactory contract implements
IMerkleDistributor: an interface used by the MerkleDropFactory contract for creating new MerkleDistributor instances


Interactions with Other Contracts


The MerkleDropFactory contract interacts with the MerkleDistributor contract through the IMerkleDistributor interface for creating new MerkleDistributor instances.
Errors


The contract does not have specific error messages. However, errors can occur if a user without the DEFAULT_ADMIN_ROLE attempts to update the MerkleDistributor implementation or if incorrect parameters are passed to the functions.



MerkleLib.sol


This is a library contract that provides utility functions to work with Merkle trees. It includes functions to verify Merkle proofs and calculate Merkle roots. This library is used by other smart contracts in the system, such as MerkleVesting and MerkleResistor, to handle Merkle tree-related operations efficiently.
Structs

MerkleProof: Represents the Merkle proof for an element in a Merkle tree. Contains a leaf of type bytes32 and an array of siblings of type bytes32.

Functions

createProof: Given an index, element, and sorted list of elements, it returns a MerkleProof struct.
verifyProof: Given a MerkleProof struct and root, it verifies whether the proof is valid by checking if the provided proof's leaf hashes to the expected root.
constructTree: Given a sorted list of elements, it returns the root of the constructed Merkle tree.
Events

There are no events in this contract.
Errors

There are no custom errors defined in this contract. However, the verifyProof function will implicitly fail when the computed root does not match the expected root.
Dependencies

There are no dependencies or imports in this contract, meaning it does not interact with any other contracts or libraries.
Variables

There are no variables in this contract.

