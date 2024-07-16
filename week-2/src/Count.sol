// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Count {
    IERC721Enumerable public nftContract;

    constructor(address _nftContract) {
        nftContract = IERC721Enumerable(_nftContract);
    }

    function count(address user) public view returns (uint256) {
        uint256 balance = nftContract.balanceOf(user);
        uint256[] memory primeTokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            if (_isPrime(nftContract.tokenOfOwnerByIndex(user, i))) {
                primeTokenIds[i] = nftContract.tokenOfOwnerByIndex(user, i);
            }
        }
        return primeTokenIds.length;
    }

    function _isPrime(uint256 number) public pure returns (bool) {
        if (number <= 1) return false;
        if (number <= 3) return true;
        if (number % 2 == 0 || number % 3 == 0) return false;

        for (uint256 i = 5; i * i <= number; i += 6) {
            if (number % i == 0 || number % (i + 2) == 0) return false;
        }

        return true;
    }
}
