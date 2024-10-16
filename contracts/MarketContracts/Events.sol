// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Structs.sol";
contract Events {
    // Emitted when a new market is created
    event MarketCreated(
        Market market
        );

    // Emitted when shares are bought for a specific outcome in a market
   event ShareBought(
    address user, 
    Market market, 
    Outcome outcome, 
    uint256 amount
    );

    // Emitted when a market is settled
    event MarketSettled(
        Market market
    );

    // Emitted when a market is toggled between active and inactive
    event MarketToggled(
        Market market
    );

    // Emitted when winnings are claimed by a user
    event WinningsClaimed(
        address indexed user,
        Market market,
       Outcome outcome,
        uint256 amount
    );
}
