// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract RewardToken is ERC20, Ownable2Step {
    IERC721 public nftContract;

    error OnlyNFTContractCanMint();

    constructor() ERC20("Reward Token", "RWT") Ownable(msg.sender) {}

    function setNFTContract(address nftAddress) external onlyOwner {
        nftContract = IERC721(nftAddress);
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != address(nftContract)) {
            revert OnlyNFTContractCanMint();
        }

        _mint(to, amount);
    }
}
