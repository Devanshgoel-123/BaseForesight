// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

library FPMMStructs {
    struct Outcome {
        string name;
        uint128 numSharesInPool;
        bool winner;
    }

    struct FPMMMarket {
        uint32 numOutcomes;
        uint128 deadline;
        bool isActive;
        bool isSettled;
    }
}