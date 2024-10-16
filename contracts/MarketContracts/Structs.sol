// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

struct Market {
    string name;
    uint256 market_id;
    string description;
    Outcome[2] outcomes;
    uint256 category;
    string image;
    bool is_settled;
    bool is_active;
    uint64 deadline;
    uint256 money_in_pool;
    Outcome winning_outcome;
    uint8 conditions; // 0 -> less than amount, 1 -> greater than amount.
    uint256 price_key;
    uint128 amount;
    uint64 api_event_id;
    bool is_home;
}

struct Outcome {
    string name;
    uint256 bought_shares;
}

struct UserPosition {
    uint256 amount;
    bool has_claimed;
}

struct UserBet {
    Outcome outcome;
    UserPosition position;
}
