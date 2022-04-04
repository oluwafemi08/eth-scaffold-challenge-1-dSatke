pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(
        address seller,
        uint256 amountOfEth,
        uint256 amountOfTokens
    );

    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    // ToDo: create a payable buyTokens() function:
    function buyTokens() public payable {
        uint256 amount = msg.value * tokensPerEth;
        require(msg.value > 0, "Insufficient fund");
        require(
            yourToken.balanceOf(address(this)) >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        bool sent = yourToken.transfer(msg.sender, amount);
        require(sent, "Transaction failed");
        emit BuyTokens(msg.sender, msg.value, amount);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public onlyOwner {
        uint256 _vendorBalance = address(this).balance;
        require(_vendorBalance >= 0, "ETH is currently not available");
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed transaction, unable to send ETH");
    }

    // ToDo: create a sellTokens() function:

    function sellTokens(uint256 amount) public {
        require(amount > 0, "You gotta have some tokens");
        uint256 allowance = yourToken.allowance(msg.sender, address(this));
        yourToken.approve(address(this), amount);
        yourToken.transferFrom(msg.sender, address(this), amount);
        uint256 theAmount = amount / tokensPerEth;
        (bool sent, ) = payable(msg.sender).call{value: theAmount}("");
        require(sent, "Unable to complete transaction");

        emit SellTokens(msg.sender, theAmount, amount);
    }
}
