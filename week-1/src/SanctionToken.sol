// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SanctionToken is ERC20, Ownable {
    mapping(address => bool) public blocklist;

    event UserBanned(address account);

    error SenderBanned(address from);
    error RecipientBanned(address to);

    constructor() ERC20("SanctionToken", "SNT") Ownable(msg.sender) {
        _mint(msg.sender, 1000 ether);
    }

    function ban(address _account) external onlyOwner {
        blocklist[_account] = true;
        emit UserBanned(_account);
    }

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
