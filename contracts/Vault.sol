// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "./Token.sol";
import "./SafeMathLib.sol";

contract Vault {
    using SafeMathLib for uint;

    Token public token;
    uint public numTranches = 0;


    struct Tranche {
        uint id;
        address destination;
        uint totalCoins;
        uint currentCoins;
        uint lockPeriodEndBlock;
        uint vestingPeriodEndBlock;
        uint lastWithdrawalBlock;
        uint startBlock;
    }

    mapping (uint => Tranche) public tranches;

    event WithdrawalOccurred(uint trancheId, uint numTokens, uint tokensLeft);
    event TrancheAdded(uint id, address destination, uint totalCoins, uint lockPeriodBlocks, uint vestingPeriodEndBlocks, uint startBlock);

    constructor(address tokenAddr, address[] memory destinations, uint[] memory tokenAllocations, uint[] memory lockPeriods, uint[] memory vestingPeriodEnds, uint[] memory startBlocks) {
        token = Token(tokenAddr);

        for (uint i = 0; i < destinations.length; i++)  {
            uint trancheId = i + 1;
            tranches[trancheId] = Tranche(
                trancheId,
                destinations[i],
                tokenAllocations[i],
                tokenAllocations[i],
                lockPeriods[i],
                vestingPeriodEnds[i],
                startBlocks[i],
                startBlocks[i]
            );
            emit TrancheAdded(trancheId, destinations[i], tokenAllocations[i], lockPeriods[i], vestingPeriodEnds[i], startBlocks[i]);
        }
        numTranches = destinations.length;
    }

    function withdraw(uint trancheId) public {
        Tranche storage tranche = tranches[trancheId];
        require(block.number > tranche.lockPeriodEndBlock, 'Must wait until after lock period');
        require(tranche.currentCoins >  0, 'No coins left to withdraw');
        uint currentWithdrawal = 0;

        // if after vesting period ends, give them the remaining coins
        if (block.number >= tranche.vestingPeriodEndBlock) {
            currentWithdrawal = tranche.currentCoins;
        } else {
            // compute allowed withdrawal
            uint coinsPerBlock = tranche.totalCoins / (tranche.vestingPeriodEndBlock.minus(tranche.startBlock));
            currentWithdrawal = (block.number.minus(tranche.lastWithdrawalBlock)).times(coinsPerBlock);
        }

        // check that we have enough tokens
        // adding this so we don't have to know in advance how many LP tokens we will get
        uint tokenBalance = token.balanceOf(address(this));
        if (currentWithdrawal > tokenBalance) {
            currentWithdrawal = tokenBalance;
        }

        // update struct
        tranche.currentCoins = tranche.currentCoins.minus(currentWithdrawal);
        tranche.lastWithdrawalBlock = block.number;

        // transfer the tokens, brah
        token.transfer(tranche.destination, currentWithdrawal);
        emit WithdrawalOccurred(trancheId, currentWithdrawal, tranche.currentCoins);
    }

    function changeDestination(uint trancheId, address newDestination) public {
        Tranche storage tranche = tranches[trancheId];
        require(tranche.destination == msg.sender, 'Can only change destination if you are the destination');
        tranche.destination = newDestination;
    }
}
