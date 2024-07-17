// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFTEnumerable is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 100;

    constructor() ERC721("NFTEnumerable", "NTE") Ownable(msg.sender) {}

    error MaxSupplyReached();

    function mint(address to, uint256 tokenId) public {
        if (totalSupply() >= MAX_SUPPLY) revert MaxSupplyReached();
        _mint(to, tokenId);
    }
}
