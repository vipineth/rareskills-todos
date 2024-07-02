// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Bonding Curve Token
/// @notice A token that follows a bonding curve for minting and redeeming
/// @dev Implements a bonding curve with a square root function for pricing
contract BondingCurveToken is ERC20 {
    uint256 public reserveTokenBalance;
    uint256 constant slope = 10 ** 7;

    event Mint(address indexed to, uint256 amount);
    event Redeem(address indexed from, uint256 amount);

    error InsufficientFunds();
    error ZeroAmountNotAllowed();
    error FailedToSendEther();
    error InsufficientAmount();

    constructor() ERC20("BondingCurveToken", "BCT") {}

    /// @notice Calculates the square root of a given number
    /// @param x The number to calculate the square root of
    /// @return y The square root of the given number
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Calculates the price to mint a given amount of tokens
    /// @param amount The amount of tokens to mint
    /// @return The price in ether to mint the given amount of tokens
    function priceToMint(uint256 amount) public view returns (uint256) {
        uint256 newTotal = totalSupply() + amount;
        uint256 newPrice = newTotal ** 2 / (slope);
        return sqrt(newPrice) - reserveTokenBalance;
    }

    /// @notice Calculates the price to redeem a given amount of tokens
    /// @param amount The amount of tokens to redeem
    /// @return The price in ether to redeem the given amount of tokens
    function priceToRedeem(uint256 amount) public view returns (uint256) {
        uint256 newTotal = totalSupply() - amount;
        uint256 newPrice = newTotal ** 2 / (slope);
        return reserveTokenBalance - sqrt(newPrice);
    }

    /// @notice Mints new tokens by paying the calculated price
    /// @dev Emits a Mint event
    /// @param amount The amount of tokens to mint
    function mint(uint256 amount) public payable {
        if (amount == 0) {
            revert ZeroAmountNotAllowed();
        }

        uint256 price = priceToMint(amount);

        if (msg.value < price) {
            revert InsufficientFunds();
        }

        reserveTokenBalance += price;
        _mint(msg.sender, amount);
        emit Mint(msg.sender, amount);
        uint256 leftover = msg.value - price;

        if (leftover > 0) {
            (bool sent, ) = msg.sender.call{value: leftover}("");
            if (!sent) {
                revert FailedToSendEther();
            }
        }
    }

    /// @notice Redeems tokens for the calculated price
    /// @dev Emits a Redeem event
    /// @param amount The amount of tokens to redeem
    function redeem(uint256 amount) public {
        if (amount == 0) {
            revert ZeroAmountNotAllowed();
        }

        uint256 returnAmount = priceToRedeem(amount);

        if (returnAmount > 0) {
            reserveTokenBalance -= returnAmount;
            _burn(msg.sender, amount);
            emit Redeem(msg.sender, amount);
            (bool sent, ) = msg.sender.call{value: returnAmount}("");
            if (!sent) {
                revert FailedToSendEther();
            }
        }
    }
}
