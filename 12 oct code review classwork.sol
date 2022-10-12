// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MysteryBoxAuction {
    address contractOwner;
    uint256 auctionStartTime;
    bool auctionInProgress;
    address topBidder;
    uint256 topBid;

    address[] authorizedBidders;
    mapping(address => uint16) winnings;

    event topBidIncreased(address bidder, uint256 bidAmount);
    event auctionStarted(uint256 timestamp);
    event auctionResult(address winner, uint256 bidAmount);

    function addAuthorizedBidder(address _authUser) private {
        authorizedBidders.push(_authUser);
    }

    function getPrizePool() public view {
        return address(this).balance;
    }

    function mysteryPrize() private view returns (uint256) {
        //using block.timestamp and block.difficulty to generate randomness is not secure
        uint256 randomHash = uint256(
            keccak256(abi.encode(block.difficulty, block.timestamp))
        );
        return (randomHash % address(this).balance) + 100000000000000000;
    }

    function startAuction() public {
        require(!auctionInProgress, "Auction is in progress already!");
        require(
            address(this).balance >= 1000000000000000000,
            "Prize pool must equal or exceed 1 ETH before an auction can start."
        );
        auctionStartTime = block.timestamp;
        emit auctionStarted(auctionStartTime);
    }

    function endAuction() public {
        // block.number can be manipulated.
        require(
            block.number > auctionStartTime + 7 days,
            "Auction has not completed."
        );
        winnings[topBidder] = mysteryPrize();
        emit auctionResult(topBidder, topBid);
    }

    function bid() external payable {
        // dod due to the bool
        require(auctionInProgress, "There is no auction in progress!");
        // Using the variable(tx.origin) for authorization could make a contract vulnerable if an authorized account calls into a malicious contract.
        topBidder = tx.origin; //could lead to an attack on the contract
        topBid = msg.value;
    }

    //this function does not check to see if the withdrawer has already withrawn
    // did not check to see if its the winner that wants to withdraw
    function withdrawWinnings(address _receive) external payable {
        uint256 totalWinnings = winnings[tx.origin]; //could lead to an attack on the contract
        payable(_receive).send(totalWinnings);
        winnings[tx.origin] -= totalWinnings;
    }
}

///////////////////////////////////////Bug Findings and review/////////////////////////////////////////

//through out the contract, the auctionInProgress boolean isn't being set to true, even in the startAuction() function.
//-Therefore, any checks that require it to be true will fail.

//there's an array for authorized bidders, but this array isn't being used in the bid() function, to check if the function caller has been authorized,
//-hence the purpose of this logic and the authorizedBidders() function is irrelevant.

//there's no check that the bid amount is greater than 0.

//there's no check to verify that the next bidder's amount is higher than the previous bidder's amount.

//in the startAuction(), it is never advisable to use onchain source of randomness for randomness, instead use oracle services

//there's actually no top bid, because every bid gets overriden, so any user's amount can be the top bid.

//also when a bidder is outbidded, the previous highestBidder's amount isn't being sent back to them, but stays inside the contract and they can't take
//-take back their funds

//in end() function, block.number should be block.timestamp, because timestamp and number can't work together, both are in number and seconds
//-respectively

//in the withdrawWinnings() function, there's no check that the msg.sender is the topBidder and the mysteryPrize isn't being sent to the topBidder,
//-and also it uses tx.origin. A malicious contract could exploit the tx.origin, by getting an address that has a balance in the winnings mapping to
//-interact with their contract and the contract makes external call to the auction contract while passing its address as the _receive address parameter,
//-here the tx.origin is still the address that might have a balance in the auction contract and funds could be sent to the malicious contract while
//-affecting the balance of the tx.origin address.

//in the withdrawWinnings(), this function is prone to reentrancy because an external call is made before contract state is being is mutated,
//-i.e., setting the balance of function caller to zero or reducing it's balance.
