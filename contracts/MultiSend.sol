// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract MultiSender {
    constructor() {}

    // withdrawals enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    function multisend(address payable[] memory addresses, uint256 amount) payable public {
        uint256 total = msg.value;

        for (uint i=0; i < addresses.length; i++) {
            // the total should be greater than the sum of the amounts
            require(total >= amount, "The value is not sufficient");
            total -= amount;

            // send the specified amount to the recipient
            addresses[i].transfer(amount);
        }
    }
}