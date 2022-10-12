// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MysteryBoxAuction {
    address contractOwner;
    uint auctionStartTime;
    bool auctionInProgress;
    address topBidder;
    uint topBid;

    address[] authorizedBidders;
    mapping (address => uint16) winnings; 

    event topBidIncreased(address bidder, uint bidAmount);
    event auctionStarted(uint timestamp); 
    event auctionResult(address winner, uint bidAmount);

    function addAuthorizedBidder(address _authUser) private {
        authorizedBidders.push(_authUser);
    }
    
    function getPrizePool() public view {
        return address(this).balance;
    }
    
    function mysteryPrize() private view returns (uint) {
    //using block.timestamp and block.difficulty to generate randomness is not secure
        uint randomHash = uint(keccak256(abi.encode(block.difficulty, block.timestamp)));
        return (randomHash % address(this).balance) + 100000000000000000;
    } 

    function startAuction() public {
        require(!auctionInProgress, "Auction is in progress already!");
        require(address(this).balance >= 1000000000000000000, "Prize pool must equal or exceed 1 ETH before an auction can start.");
        auctionStartTime = block.timestamp;
        emit auctionStarted(auctionStartTime);
    }

    function endAuction() public {
    // block.number can be manipulated.
        require(block.number > auctionStartTime + 7 days, "Auction has not completed.");
        winnings[topBidder] = mysteryPrize();
        emit auctionResult(topBidder, topBid);
    }

    function bid() payable external {
    // dod due to the bool
        require(auctionInProgress, "There is no auction in progress!");
        // Using the variable(tx.origin) for authorization could make a contract vulnerable if an authorized account calls into a malicious contract.
        topBidder = tx.origin; //could lead to an attack on the contract
        topBid = msg.value;
    }
    
    //this function does not check to see if the withdrawer has already withrawn
    // did not check to see if its the winner that wants to withdraw
    function withdrawWinnings(address _receive) payable external {
        uint totalWinnings = winnings[tx.origin]; //could lead to an attack on the contract
        payable(_receive).send(totalWinnings);
        winnings[tx.origin] -= totalWinnings;
    }
}
