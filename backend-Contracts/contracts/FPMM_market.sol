// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./struct.sol";
import "./events.sol";
import "./FPMMInternal.sol";


contract FPMMMarket {
     using FPMMInternal for *;
     uint256 public constant ETH_TO_USDC_RATE = 2569; // 1 ETH = 2569 USDC
    uint256 public constant DECIMALS = 6; // Both ETH and USDC will use 6 decimals
    uint256 public constant SCALING_FACTOR = 10**DECIMALS;
     address public collateralToken;
    uint256 public numMarkets;
    uint32 public fee;
    uint256 public liquidityPool;
    uint256 public feesAccrued;
    address public owner;
    address public treasuryWallet;
    uint32 public treasuryFee;
    mapping(uint256 => FPMMStructs.FPMMMarket) public markets;
    mapping(address => uint256) public liquidityBalance; // this is the liquidity added in pool by each account
    mapping(uint256 => mapping(address => mapping(uint32 => uint256))) public balances;
    mapping(uint256 => mapping(uint32 => FPMMStructs.Outcome)) public outcomes;

    constructor(  // check this for the collateral token how to assign it 
        uint32 _fee

    ) {
        fee = _fee;
        owner = msg.sender;
    }
    function normalizeEthAmount(uint256 ethAmount) internal pure returns (uint256) {
        return ethAmount / (10**12); 
    }

    
    function convertEthToUsdc(uint256 ethAmount) public pure returns (uint256) {
        uint256 normalizedEth = normalizeEthAmount(ethAmount);
        return normalizedEth * ETH_TO_USDC_RATE;
    }

    
    function convertUsdcToEth(uint256 usdcAmount) public pure returns (uint256) {
        return (usdcAmount * SCALING_FACTOR) / ETH_TO_USDC_RATE;
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

    function currentLiquidity() public view returns (uint256) {
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

   function addFunding() public payable {
    require(msg.value > 0, "Added funds must be positive");
   uint256 usdcEquivalent = convertEthToUsdc(msg.value);
        
        liquidityBalance[msg.sender] += usdcEquivalent;
        liquidityPool += usdcEquivalent;
        
        emit FPMMEvents.FPMMFundingAdded(msg.sender, usdcEquivalent);
}

function removeFunding(uint128 fundsToRemove) public payable {
    require(fundsToRemove > 0, "Funds must be positive");
        require(fundsToRemove <= liquidityPool, "Cannot remove more than pool");
        require(liquidityBalance[msg.sender] >= fundsToRemove, "Insufficient funds");
        
        uint256 amount = (feesAccrued * fundsToRemove) / liquidityPool;
        uint256 withdrawableAmount = feesWithdrawableBy(msg.sender);
        require(withdrawableAmount > 0, "Require non-zero balances");
        
        uint256 ethToSend = convertUsdcToEth(withdrawableAmount);
        require(address(this).balance >= ethToSend * 10**12, "Insufficient contract balance"); // Scale back to 18 decimals
        
        payable(msg.sender).transfer(ethToSend * 10**12); // Scale back to 18 decimals for ETH transfer
        
        feesAccrued -= amount;
        liquidityBalance[msg.sender] -= fundsToRemove;
        
        emit FPMMEvents.FPMMFundingRemoved(msg.sender, fundsToRemove, amount);
}

    function calcBuyAmount(uint256 marketId, uint128 investmentAmount, uint32 outcomeIndex) public view returns (uint128) {
        require(investmentAmount > 0, "Investment must be positive");
        require(marketId <= numMarkets, "Invalid market ID");
        
        // Convert ETH investment to USDC equivalent (6 decimals)
        uint256 usdcEquivalent = convertEthToUsdc(investmentAmount);
        
        FPMMStructs.FPMMMarket storage market = markets[marketId];
        require(outcomeIndex < market.numOutcomes, "Invalid outcome index");
        require(market.isActive, "Market is not active");
        require(!market.isSettled, "Market is already settled");

        uint128[] memory poolBalances = FPMMInternal.getPoolBalances(markets, outcomes, marketId);
        uint128 investmentAmountMinusFees = uint128(usdcEquivalent) - 
            (uint128(usdcEquivalent) * fee / 100) - 
            (uint128(usdcEquivalent) * treasuryFee / 100);

        uint128 newOutcomeBalance = poolBalances[outcomeIndex];
        for (uint32 i = 0; i < poolBalances.length; i++) {
            if (i != outcomeIndex) {
                newOutcomeBalance = newOutcomeBalance * poolBalances[i] / 
                    (poolBalances[i] + investmentAmountMinusFees);
            }
        }

        require(newOutcomeBalance > 0, "Must have non-zero balances");
        return uint128(poolBalances[outcomeIndex] + investmentAmountMinusFees - newOutcomeBalance);
    }

    function calcSellAmount(uint256 marketId, uint128 returnAmount, uint32 outcomeIndex) public view returns (uint128) {
    require(returnAmount > 0, "Must be positive");
    require(marketId <= numMarkets, "Invalid market ID");
    
    FPMMStructs.FPMMMarket storage market = markets[marketId];
    require(outcomeIndex < market.numOutcomes, "Invalid outcome index");
    require(market.isActive, "Market is not active");
    require(!market.isSettled, "Market is already settled");

    uint256 usdcReturnAmount = convertEthToUsdc(returnAmount);

    uint128[] memory poolBalances = FPMMInternal.getPoolBalances(markets, outcomes, marketId);
    uint128 returnAmountMinusFees = uint128(usdcReturnAmount - (usdcReturnAmount * fee / 100));

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
        uint32 outcomeIndex,
        uint128 minOutcomeTokensToBuy
    ) public payable {
        uint256 usdcEquivalent = convertEthToUsdc(msg.value);
        
        uint128 outcomeTokensToBuy = calcBuyAmount(marketId, uint128(msg.value), outcomeIndex);
        require(outcomeTokensToBuy >= minOutcomeTokensToBuy, "Receiving less than expected");

        feesAccrued += (usdcEquivalent * fee) / 100;

        uint256 treasuryEthAmount = convertUsdcToEth((usdcEquivalent * treasuryFee) / 100);
        payable(treasuryWallet).transfer(treasuryEthAmount * 10**12); // Scale back to 18 decimals for transfer

        uint128 investmentAmountMinusFees = uint128(usdcEquivalent) - 
            uint128((usdcEquivalent * fee / 100)) - 
            uint128((usdcEquivalent * treasuryFee / 100));

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
            uint128(usdcEquivalent),
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
        uint256 usdcEquivalent = convertEthToUsdc(returnAmount); // Scale up before conversion
        
        uint128 outcomeTokensToSell = calcSellAmount(marketId, returnAmount, outcomeIndex);
        require(outcomeTokensToSell <= maxOutcomeTokensToSell, "Selling more than expected");
        require(
            outcomeTokensToSell <= balances[marketId][msg.sender][outcomeIndex],
            "Insufficient balance"
        );

        balances[marketId][msg.sender][outcomeIndex] -= outcomeTokensToSell;

        feesAccrued += (usdcEquivalent * fee) / 100;

        uint128 returnAmountMinusFees = uint128(usdcEquivalent - (usdcEquivalent * fee / 100));

        FPMMInternal.calcNewPoolBalances(
            markets,
            outcomes,
            marketId,
            returnAmountMinusFees,
            outcomeIndex,
            outcomeTokensToSell,
            false
        );

        uint256 ethToReturn = convertUsdcToEth(returnAmount);
        payable(msg.sender).transfer(ethToReturn); // Scale back to 18 decimals for ETH transfer

        emit FPMMEvents.FPMMSell(
            msg.sender,
            uint128(usdcEquivalent),
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
function getAllUserBets(address user) public view returns (FPMMStructs.UserMarketBets[] memory) {
        FPMMStructs.UserMarketBets[] memory allBets = new FPMMStructs.UserMarketBets[](numMarkets);

        for (uint256 i = 1; i <= numMarkets; i++) {
            FPMMStructs.FPMMMarket storage market = markets[i];
            uint256[] memory marketBets = new uint256[](market.numOutcomes);

            for (uint32 j = 0; j < market.numOutcomes; j++) {
                marketBets[j] = balances[i][user][j];
            }

            allBets[i - 1] = FPMMStructs.UserMarketBets({
                marketId: i,
                bets: marketBets,
                isActive: market.isActive,
                isSettled: market.isSettled
            });
        }

        return allBets;
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
        
        uint128 outcomeTokens = uint128(currentFunding / numOutcomes/10);
        
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
    
    // Transfer the winnings to the user
    (bool success, ) = payable(msg.sender).call{value: winnings}("");
    require(success, "Transfer failed");

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