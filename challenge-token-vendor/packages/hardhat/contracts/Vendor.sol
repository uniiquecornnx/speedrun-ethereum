// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    
    YourToken public yourToken;

    
    uint256 public constant tokensPerEth = 100;

    error InvalidTokenAmount();
    error InsufficientVendorEthBalance(uint256 available, uint256 required);

    error EthTransferFailed(address to, uint256 amount);
    error InvalidEthAmount();
    error InsufficientVendorTokenBalance(uint256 available, uint256 required);

    event SellTokens(address indexed seller, uint256 amountOfTokens, uint256 amountOfETH);
    event BuyTokens(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    
    function buyTokens() public payable {
        if (msg.value == 0) {
            revert InvalidEthAmount();
        }

        
        uint256 amountOfTokens = msg.value * tokensPerEth;

       
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        if (vendorBalance < amountOfTokens) {
            revert InsufficientVendorTokenBalance(vendorBalance, amountOfTokens);
        }

       
        bool sent = yourToken.transfer(msg.sender, amountOfTokens);
        require(sent, "Token transfer failed");

     
        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

    function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    
    (bool sent, ) = owner().call{value: balance}("");
    
    if (!sent) {
        revert EthTransferFailed(owner(), balance);
    }
    }

    function sellTokens(uint256 amount) public {
    // 1. Reject 0 token sales
    if (amount == 0) {
        revert InvalidTokenAmount();
    }

    // 2. Calculate ETH to return
    // If 100 tokens = 1 ETH, then amount tokens = amount/100 ETH
    uint256 ethToReturn = amount / tokensPerEth;

    // 3. Check vendor has enough ETH
    uint256 vendorEthBalance = address(this).balance;
    if (vendorEthBalance < ethToReturn) {
        revert InsufficientVendorEthBalance(vendorEthBalance, ethToReturn);
    }

    // 4. Pull tokens from seller (requires prior approval!)
    bool received = yourToken.transferFrom(msg.sender, address(this), amount);
    require(received, "Token transfer failed");

    // 5. Send ETH back to seller
    (bool sent, ) = msg.sender.call{value: ethToReturn}("");
    require(sent, "ETH transfer failed");

    // 6. Emit event
    emit SellTokens(msg.sender, amount, ethToReturn);
}
}