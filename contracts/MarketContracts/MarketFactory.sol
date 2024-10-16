// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs.sol";
import "./Events.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketFactory is Ownable, Events {
    uint256 public marketIndex;
    mapping(uint256 => Market) public markets;
    mapping(address => mapping(uint256 => UserBet)) public userBets;

    // Platform fee and treasury
    uint256 public platformFee;
    address public treasuryWallet;

    // Constructor to set initial owner and treasury wallet
    constructor(address _treasuryWallet) {
        treasuryWallet = _treasuryWallet;
        marketIndex = 0;
    }

    // Create a new market
    function createMarket(
        string memory _name,
        string memory _description,
        string memory _outcome1,
        string memory _outcome2,
        uint256 _category,
        string memory _image,
        uint256 _deadline
    ) public onlyOwner {
        Outcome[2] memory outcomes = [
            Outcome(_outcome1, 0),
            Outcome(_outcome2, 0)
        ];

        markets[marketIndex] = Market({
            name: _name,
            marketId: marketIndex,
            description: _description,
            outcomes: outcomes,
            category: _category,
            image: _image,
            isSettled: false,
            isActive: true,
            deadline: _deadline,
            moneyInPool: 0,
            winningOutcome: Outcome("", 0),
            conditions: 0,
            priceKey: "",
            amount: 0,
            apiEventId: 0,
            isHome: false
        });

        emit MarketCreated(marketIndex, _name, _category);
        marketIndex++;
    }

    // Buy shares for a specific outcome
    function buyShares(
        uint256 _marketId,
        uint8 _outcomeIndex,
        uint256 _amount
    ) public payable {
        require(markets[_marketId].isActive, "Market is not active");
        require(_outcomeIndex < 2, "Invalid outcome index");
        require(msg.value >= _amount, "Insufficient payment");

        markets[_marketId].outcomes[_outcomeIndex].boughtShares += _amount;
        markets[_marketId].moneyInPool += _amount;

        userBets[msg.sender][_marketId] = UserBet({
            outcome: markets[_marketId].outcomes[_outcomeIndex],
            position: UserPosition({
                amount: _amount,
                hasClaimed: false
            })
        });

        emit ShareBought(msg.sender, _marketId, markets[_marketId].outcomes[_outcomeIndex].name, _amount);
    }

    // Settle the market with a winning outcome
    function settleMarket(uint256 _marketId, uint8 _winningOutcomeIndex) public onlyOwner {
        require(!markets[_marketId].isSettled, "Market already settled");
        require(_winningOutcomeIndex < 2, "Invalid outcome index");

        markets[_marketId].isSettled = true;
        markets[_marketId].winningOutcome = markets[_marketId].outcomes[_winningOutcomeIndex];

        emit MarketSettled(_marketId, markets[_marketId].outcomes[_winningOutcomeIndex].name);
    }

    // Toggle market between active and inactive states
    function toggleMarket(uint256 _marketId) public onlyOwner {
        markets[_marketId].isActive = !markets[_marketId].isActive;
        emit MarketToggled(_marketId, markets[_marketId].isActive);
    }

    // Claim winnings by the user after the market is settled
    function claimWinnings(uint256 _marketId) public {
        require(markets[_marketId].isSettled, "Market not settled");
        UserBet memory userBet = userBets[msg.sender][_marketId];
        require(!userBet.position.hasClaimed, "Winnings already claimed");
        require(userBet.outcome.name == markets[_marketId].winningOutcome.name, "Not a winning bet");

        uint256 winnings = (userBet.position.amount * markets[_marketId].moneyInPool) / markets[_marketId].winningOutcome.boughtShares;
        userBet.position.hasClaimed = true;

        payable(msg.sender).transfer(winnings);
        emit WinningsClaimed(msg.sender, _marketId, userBet.outcome.name, winnings);
    }

    // Set platform fee
    function setPlatformFee(uint256 _fee) public onlyOwner {
        platformFee = _fee;
    }

    // Set treasury wallet
    function setTreasuryWallet(address _wallet) public onlyOwner {
        treasuryWallet = _wallet;
    }

    // Function to withdraw platform fees
    function withdrawFees() public onlyOwner {
        payable(treasuryWallet).transfer(address(this).balance);
    }
}
