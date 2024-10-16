// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./struct.sol";
import "./events.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FPMMInternal.sol";


contract FPMMMarket {
     using FPMMInternal for *;
     IERC20 public collateralToken;
    uint256 public numMarkets;
    uint32 public fee;
    uint128 public liquidityPool;
    uint256 public feesAccrued;
    address public owner;
    address public treasuryWallet;
    uint32 public treasuryFee;
    mapping(uint256 => FPMMStructs.FPMMMarket) public markets;
    mapping(address => uint256) public liquidityBalance; // this is the liquidity added in pool by each account
    mapping(uint256 => mapping(address => mapping(uint32 => uint256))) public balances;
    mapping(uint256 => mapping(uint32 => FPMMStructs.Outcome)) public outcomes;

    constructor(  // check this for the collateral token how to assign it 
        IERC20 _collateralToken,
        uint32 _fee,
        address _owner
    ) {
        collateralToken = _collateralToken;
        fee = _fee;
        owner = _owner;
    }

    function getCollateralToken() public view returns (address) {
        return address(collateralToken);
    }

    function getFee() public view returns (uint32) {
        return fee;
    }

    function setFee(uint32 _fee) public {
        require(msg.sender == owner, "Only owner can set fee");
        fee = _fee;
    }

    function currentLiquidity() public view returns (uint128) {
        return liquidityPool;
    }

    function getNumMarkets() public view returns (uint256) {
        return numMarkets;
    }
    function feesWithdrawableBy(address account) public view returns (uint256) {
        uint256 amount = (feesAccrued * liquidityBalance[account]) / uint256(liquidityPool);
        return amount + liquidityBalance[account];
    }

    function disableMarket(uint256 marketId) public {
        require(msg.sender == owner, "Only owner can disable market");
        FPMMStructs.FPMMMarket storage market = markets[marketId];
        require(market.isActive, "Market is already disabled");
        market.isActive = false;
    }  

    function setWinner(uint256 marketId, uint32 outcomeIndex) public {
    require(msg.sender == owner, "Only owner can set winner");
    FPMMStructs.FPMMMarket storage market = markets[marketId];
    require(market.isActive, "Market is not active");
    require(!market.isSettled, "Market is already settled");
    for (uint32 i = 0; i < market.numOutcomes; i++) {
        FPMMStructs.Outcome storage outcome = outcomes[marketId][i];
        if (i == outcomeIndex) {
            outcome.winner = true;
        }
    }
    market.isActive = false;
    market.isSettled = true;
   }

   function addFunding(uint128 addedFunds) public {
    require(addedFunds > 0, "Added funds must be positive");
    require(
        collateralToken.transferFrom(msg.sender, address(this), addedFunds),
        "Transfer failed"
    );
    
    liquidityBalance[msg.sender] += addedFunds;
    liquidityPool += addedFunds;
    
    emit FPMMEvents.FPMMFundingAdded(msg.sender, addedFunds);
}

function removeFunding(uint128 fundsToRemove) public {
    require(fundsToRemove > 0, "Funds must be positive");
    require(fundsToRemove <= liquidityPool, "Cannot remove more than pool");
    require(liquidityBalance[msg.sender] >= fundsToRemove, "Insufficient funds");
    
    uint256 amount = (feesAccrued * fundsToRemove) / liquidityPool;
    uint256 withdrawableAmount = feesWithdrawableBy(msg.sender);
    require(withdrawableAmount > 0, "Require non-zero balances");
    
    require(
        collateralToken.transfer(msg.sender, withdrawableAmount),
        "Transfer failed"
    );
    
    feesAccrued -= amount;
    liquidityBalance[msg.sender] -= fundsToRemove;
    liquidityPool -= fundsToRemove;
    
    emit FPMMEvents.FPMMFundingRemoved(msg.sender, fundsToRemove, amount);
}

    function calcBuyAmount(uint256 marketId, uint128 investmentAmount, uint32 outcomeIndex) public view returns (uint128) {
    require(investmentAmount > 0, "Investment must be positive");
    require(marketId <= numMarkets, "Invalid market ID");
    FPMMStructs.FPMMMarket storage market = markets[marketId];
    require(outcomeIndex < market.numOutcomes, "Invalid outcome index");
    require(market.isActive, "Market is not active");
    require(!market.isSettled, "Market is already settled");

    uint128[] memory poolBalances = FPMMInternal.getPoolBalances(markets,outcomes,marketId);
    uint128 investmentAmountMinusFees = investmentAmount - 
        (investmentAmount * fee / 100) - 
        (investmentAmount * treasuryFee / 100);

    uint128 newOutcomeBalance = poolBalances[outcomeIndex];
    for (uint32 i = 0; i < poolBalances.length; i++) {
        if (i != outcomeIndex) {
            newOutcomeBalance = newOutcomeBalance * poolBalances[i] / 
                (poolBalances[i] + investmentAmountMinusFees);
        }
    }

    require(newOutcomeBalance > 0, "Must have non-zero balances");
    uint128 minOutcomeTokensToBuy = poolBalances[outcomeIndex] + 
        investmentAmountMinusFees - 
        newOutcomeBalance;

    return minOutcomeTokensToBuy;
    }

    function calcSellAmount(uint256 marketId, uint128 returnAmount, uint32 outcomeIndex) public view returns (uint128) {
    require(returnAmount > 0, "Must be positive");
    require(marketId <= numMarkets, "Invalid market ID");
    FPMMStructs.FPMMMarket storage market = markets[marketId];
    require(outcomeIndex < market.numOutcomes, "Invalid outcome index");
    require(market.isActive, "Market is not active");
    require(!market.isSettled, "Market is already settled");

    uint128[] memory poolBalances = FPMMInternal.getPoolBalances(markets,outcomes,marketId);
    uint128 returnAmountMinusFees = returnAmount - (returnAmount * fee / 100);

    uint128 newOutcomeBalance = poolBalances[outcomeIndex];
    for (uint32 i = 0; i < poolBalances.length; i++) {
        if (i != outcomeIndex) {
            newOutcomeBalance = newOutcomeBalance * poolBalances[i] / 
                (poolBalances[i] - returnAmountMinusFees);
        }
    }

    require(newOutcomeBalance > 0, "Must have non-zero balances");
    return returnAmountMinusFees + newOutcomeBalance - poolBalances[outcomeIndex];
    }

    function buy(
    uint256 marketId,
    uint128 investmentAmount,
    uint32 outcomeIndex,
    uint128 minOutcomeTokensToBuy
) public {
    uint128 outcomeTokensToBuy = calcBuyAmount(marketId, investmentAmount, outcomeIndex);
    require(outcomeTokensToBuy >= minOutcomeTokensToBuy, "Receiving less than expected");

    require(
        collateralToken.transferFrom(msg.sender, address(this), investmentAmount),
        "Transfer failed"
    );

    feesAccrued += (investmentAmount * fee) / 100;

    require(
        collateralToken.transfer(treasuryWallet, (investmentAmount * treasuryFee) / 100),
        "Treasury transfer failed"
    );

    uint128 investmentAmountMinusFees = investmentAmount - 
        (investmentAmount * fee / 100) - 
        (investmentAmount * treasuryFee / 100);

    FPMMInternal.calcNewPoolBalances(
        markets,
        outcomes,
        marketId,
        investmentAmountMinusFees,
        outcomeIndex,
        outcomeTokensToBuy,
        true
    );

    balances[marketId][msg.sender][outcomeIndex] += outcomeTokensToBuy;

    emit FPMMEvents.FPMMBuy(
        msg.sender,
        investmentAmount,
        outcomeIndex,
        outcomeTokensToBuy
    );
 } 
 function sell(
    uint256 marketId,
    uint128 returnAmount,
    uint32 outcomeIndex,
    uint128 maxOutcomeTokensToSell
) public {
    uint128 outcomeTokensToSell = calcSellAmount(marketId, returnAmount, outcomeIndex);
    require(outcomeTokensToSell <= maxOutcomeTokensToSell, "Selling more than expected");
    require(
        outcomeTokensToSell <= balances[marketId][msg.sender][outcomeIndex],
        "Insufficient balance"
    );

    balances[marketId][msg.sender][outcomeIndex] -= outcomeTokensToSell;

    feesAccrued += (returnAmount * fee) / 100;

    uint128 returnAmountMinusFees = returnAmount - (returnAmount * fee / 100);

    FPMMInternal.calcNewPoolBalances(
        markets,
        outcomes,
        marketId,
        returnAmountMinusFees,
        outcomeIndex,
        outcomeTokensToSell,
        false
    );

    require(
        collateralToken.transfer(msg.sender, returnAmount),
        "Transfer failed"
    );

    emit FPMMEvents.FPMMSell(
        msg.sender,
        returnAmount,
        outcomeIndex,
        outcomeTokensToSell
    );
}
function getUserBalance(address user) public view returns (uint256) {
    return liquidityBalance[user];
}

function getUserMarketShare(address user, uint256 marketId, uint32 outcomeIndex) public view returns (uint256) {
    return balances[marketId][user][outcomeIndex];
}

function initMarket(string[] memory outcomeNames, uint128 deadline) public {
    require(outcomeNames.length > 0, "Outcomes array cannot be empty");
    require(outcomeNames.length <= 256, "Too many outcomes");
    require(deadline > block.timestamp, "Deadline must be in the future");
    
    uint256 currentFunding = liquidityPool;
    require(currentFunding > 0, "No liquidity in the pool");
    
    uint256 marketId = numMarkets + 1;
    numMarkets = marketId;
    
    uint32 numOutcomes = uint32(outcomeNames.length);
    FPMMStructs.FPMMMarket memory market = FPMMStructs.FPMMMarket({
        numOutcomes: numOutcomes,
        deadline: deadline,
        isActive: true,
        isSettled: false
    });
    markets[marketId] = market;
    
    uint128 outcomeTokens = uint128(currentFunding / 10 / numOutcomes);
    
    for (uint32 i = 0; i < numOutcomes; i++) {
        outcomes[marketId][i] = FPMMStructs.Outcome({
            name: outcomeNames[i],
            numSharesInPool: outcomeTokens,
            winner: false
        });
    }
    
    emit FPMMEvents.FPMMMarketInit(marketId, outcomeNames, deadline);
}

function setMarketWinner(uint256 marketId, uint32 outcomeIndex) public {
    require(msg.sender == owner, "Only owner can set winner");
    FPMMStructs.FPMMMarket storage market = markets[marketId];
    require(!market.isSettled, "Market is already settled");
    
    for (uint32 i = 0; i < market.numOutcomes; i++) {
        if (i == outcomeIndex) {
            outcomes[marketId][i].winner = true;
        }
    }
    
    market.isActive = false;
    market.isSettled = true;
}

function claimWinnings(uint256 marketId, uint32 outcomeIndex) public {
    FPMMStructs.FPMMMarket storage market = markets[marketId];
    require(market.isSettled, "Market is not settled");
    
    FPMMStructs.Outcome storage outcome = outcomes[marketId][outcomeIndex];
    require(outcome.winner, "Outcome is not a winner");
    
    uint256 userBalance = balances[marketId][msg.sender][outcomeIndex];
    require(userBalance > 0, "No balance to claim");
    
    uint256 winnings = userBalance * (100 - fee) / 100;
    balances[marketId][msg.sender][outcomeIndex] = 0;
    
    require(
        collateralToken.transfer(msg.sender, userBalance - winnings),
        "Transfer failed"
    );
    require(
        collateralToken.transfer(msg.sender, winnings),
        "Transfer failed"
    );
}

function getMarket(uint256 marketId) public view returns (FPMMStructs.FPMMMarket memory) {
    return markets[marketId];
}

function getOutcome(uint256 marketId, uint32 outcomeIndex) public view returns (FPMMStructs.Outcome memory) {
    return outcomes[marketId][outcomeIndex];
}

function getTreasury() public view returns (address) {
    require(msg.sender == owner, "Only owner can see treasurer");
    return treasuryWallet;
}
function setTreasury(address treasurer) public {
    require(msg.sender == owner, "Only owner can set treasurer");
    treasuryWallet = treasurer;
}

function setTreasurerFee(uint32 _fee) public {
    require(msg.sender == owner, "Only owner can set fee");
    treasuryFee = _fee;
}

function updateDeadline(uint256 marketId, uint128 deadline) public {
    require(msg.sender == owner, "Only owner can update deadline");
    FPMMStructs.FPMMMarket storage market = markets[marketId];
    require(market.isActive, "Market is not active");
    require(!market.isSettled, "Market is already settled");
    require(deadline > block.timestamp, "Deadline must be in the future");
    
    market.deadline = deadline;
}

}