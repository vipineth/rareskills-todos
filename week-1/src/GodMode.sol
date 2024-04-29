// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GodMode Token Contract
/// @notice Implements ERC20 token with special owner privileges
contract GodMode is ERC20, Ownable {
    /// @dev Initializes contract with token name and symbol, and mints initial supply to owner
    constructor() ERC20("GodMode", "GOD") Ownable(msg.sender) {
        _mint(msg.sender, 1000 ether);
    }

    /// @dev Overrides the internal _spendAllowance function to allow owner unrestricted transfers
    /// @param from Address from which tokens are deducted
    /// @param to Address to which tokens are sent
    /// @param amount Number of tokens to transfer
    function _spendAllowance(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (msg.sender == owner()) {
            return;
        }
        super._spendAllowance(from, to, amount);
    }
}
