// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title RewardToken Contract
/// @notice This contract implements an ERC20 token that can be minted by a specific NFT contract.
/// @dev The contract owner can set the NFT contract address that is allowed to mint tokens.
contract RewardToken is ERC20, Ownable2Step {
    IERC721 public nftContract;

    error OnlyNFTContractCanMint();

    /// @notice Constructor to initialize the RewardToken contract.
    constructor() ERC20("Reward Token", "RWT") Ownable(msg.sender) {}

    /// @notice Set the NFT contract address that is allowed to mint tokens.
    /// @param nftAddress The address of the NFT contract.
    /// @dev Only the contract owner can call this function.
    function setNFTContract(address nftAddress) external onlyOwner {
        nftContract = IERC721(nftAddress);
    }

    /// @notice Mint new tokens.
    /// @param to The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    /// @dev Only the NFT contract can call this function.
    function mint(address to, uint256 amount) external {
        if (msg.sender != address(nftContract)) {
            revert OnlyNFTContractCanMint();
        }

        _mint(to, amount);
    }
}
