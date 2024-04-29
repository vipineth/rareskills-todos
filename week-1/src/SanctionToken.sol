// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SanctionToken
/// @dev Extends ERC20 token with sanctioning capabilities, allowing the owner to ban addresses from transacting.
contract SanctionToken is ERC20, Ownable {
    /// @notice Tracks whether an address is banned.
    mapping(address => bool) public blocklist;

    /// @notice Emitted when an address is banned.
    /// @param account The address that was banned.
    event UserBanned(address account);

    /// @notice Error thrown when a banned sender attempts to initiate a transaction.
    /// @param from The address attempting to send tokens.
    error SenderBanned(address from);

    /// @notice Error thrown when a banned recipient attempts to receive tokens.
    /// @param to The address attempting to receive tokens.
    error RecipientBanned(address to);

    /// @notice Constructor that sets the name, symbol and the owner of the contract.
    constructor() ERC20("SanctionToken", "SNT") Ownable(msg.sender) {
        _mint(msg.sender, 1000 ether);
    }

    /// @notice Bans an address from participating in transactions.
    /// @dev Only the owner can call this function.
    /// @param _account The address to ban.
    function ban(address _account) external onlyOwner {
        blocklist[_account] = true;
        emit UserBanned(_account);
    }

    /// @notice Overrides the internal _update function to include sanction checks.
    /// @dev Reverts if `from` or `to` are banned.
    /// @param from The sender's address.
    /// @param to The recipient's address.
    /// @param value The amount of tokens being transferred.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        if (blocklist[from]) {
            revert SenderBanned(from);
        }
        if (blocklist[to]) {
            revert RecipientBanned(to);
        }
        super._update(from, to, value);
    }
}
