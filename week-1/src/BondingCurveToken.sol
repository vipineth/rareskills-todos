// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract BondingCurveToken is ERC20 {
    uint256 public reserveTokenBalance;

    error InsufficientFunds();
    error ZeroAmountNotAllowed();
    error FailedToSendEther();
    error InsufficientAmount();

    constructor() ERC20("BondingCurveToken", "BCT") {
        _mint(msg.sender, 1 ether);
    }

    function priceToMint(uint256 amount) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 price = (totalSupply + amount) ** 2 - totalSupply ** 2;
        return price;
    }

    function priceToRedeem(uint256 amount) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (amount > totalSupply) revert InsufficientAmount();
        uint256 price = totalSupply ** 2 - (totalSupply - amount) ** 2;
        return price;
    }

    function mint(uint256 amount) public payable {
        if (amount == 0) revert ZeroAmountNotAllowed();

        uint256 price = priceToMint(amount);

        if (msg.value < price) revert InsufficientFunds();
        reserveTokenBalance += msg.value;
        _mint(msg.sender, amount);
    }

    function redeem(uint256 amount) public {
        if (amount == 0) revert ZeroAmountNotAllowed();
        if (balanceOf(msg.sender) < amount) revert InsufficientAmount();

        uint256 price = priceToRedeem(amount);
        console.log("%s:%s:%s", reserveTokenBalance, price, amount);
        if (reserveTokenBalance < price) revert InsufficientFunds();
        _burn(msg.sender, amount);
        // (bool sent, ) = payable(msg.sender).call{value: price}("");
        // if (!sent) revert FailedToSendEther();
        reserveTokenBalance -= price;
    }
}
