// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./struct.sol";
import "./events.sol";

library FPMMInternal {
    function getPoolBalances(
        mapping(uint256 => FPMMStructs.FPMMMarket) storage markets,
        mapping(uint256 => mapping(uint32 => FPMMStructs.Outcome)) storage outcomes,
        uint256 marketId
    ) internal view returns (uint128[] memory) {
        FPMMStructs.FPMMMarket memory market = markets[marketId];
        uint32 numOutcomes = market.numOutcomes;
        uint128[] memory balances = new uint128[](numOutcomes);

        for (uint32 i = 0; i < numOutcomes; i++) {
            balances[i] = outcomes[marketId][i].numSharesInPool;
        }

        return balances;
    }

    function calcNewPoolBalances(
        mapping(uint256 => FPMMStructs.FPMMMarket) storage markets,
        mapping(uint256 => mapping(uint32 => FPMMStructs.Outcome)) storage outcomes,
        uint256 marketId,
        uint128 amount,
        uint32 outcomeIndex,
        uint128 sharesUpdated,
        bool isBuy
    ) internal {
        FPMMStructs.FPMMMarket memory market = markets[marketId];
        uint32 numOutcomes = market.numOutcomes;

        for (uint32 i = 0; i < numOutcomes; i++) {
            FPMMStructs.Outcome storage outcome = outcomes[marketId][i];
            uint128 sharesInPool = outcome.numSharesInPool;

            if (isBuy) {
                if (i == outcomeIndex) {
                    outcome.numSharesInPool = sharesInPool + amount - sharesUpdated;
                } else {
                    outcome.numSharesInPool = sharesInPool + amount;
                }
            } else {
                if (i == outcomeIndex) {
                    outcome.numSharesInPool = sharesInPool + sharesUpdated - amount;
                } else {
                    outcome.numSharesInPool = sharesInPool - amount;
                }
            }
        }
    }
}