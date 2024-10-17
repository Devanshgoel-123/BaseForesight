// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library FPMMEvents {
    event FPMMMarketInit(
        uint256 indexed marketId,
        string[] outcomes,
        uint128 deadline
    );

    event FPMMFundingAdded(
        address indexed funder,
        uint256 amountsAdded
    );

    event FPMMFundingRemoved(
        address indexed funder,
        uint256 collateralRemovedFromFeePool,
        uint256 amountsRemoved
    );

    event FPMMBuy(
        address indexed buyer,
        uint128 investmentAmount,
        uint32 outcomeIndex,
        uint256 outcomeTokensBought
    );

    event FPMMSell(
        address indexed seller,
        uint128 returnAmount,
        uint32 outcomeIndex,
        uint256 outcomeTokensSold
    );

    event Upgraded(
        address indexed newImplementation
    );
}