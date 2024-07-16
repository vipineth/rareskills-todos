// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTEnumerable is ERC721Enumerable {
    uint256 public constant MAX_SUPPLY = 100;

    constructor() ERC721Enumerable("NFTEnumerable", "NTE") {}

    error MaxSupplyReached();

    function mint(address to, uint256 tokenId) public {
        if (totalSupply() >= MAX_SUPPLY) revert MaxSupplyReached();
        _mint(to, tokenId);
    }
}
