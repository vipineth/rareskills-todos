// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {RewardToken} from "./RewardToken.sol";

/// @title NFT Staking Contract
/// @notice This contract allows users to stake their NFTs and earn rewards over time.
contract NFTStaking is IERC721Receiver {
    uint256 public constant REWARD_DURATION = 24 hours;
    uint256 public constant REWARD_AMOUNT = 10 ether;

    struct DepositEntry {
        address user;
        uint256 timestamp;
    }

    IERC721 public nftContract;
    RewardToken public rewardTokenContract;
    mapping(uint256 => DepositEntry) public deposits;

    error OnlyNFTContractCanDeposit();
    error OnlyDepositorCanWithdraw();
    error RewardDurationHasNotPassed();

    event NFTStaked(uint256 indexed tokenId, address user);
    event NFTWithdrawn(uint256 indexed tokenId, address user);
    event RewardDistributed(uint256 indexed tokenId, address depositor, uint256 amount);

    /// @notice Constructor to initialize the NFT staking contract.
    /// @param _nftContract The address of the NFT contract.
    /// @param _rewardToken The address of the reward token contract.
    constructor(address _nftContract, address _rewardToken) {
        nftContract = IERC721(_nftContract);
        rewardTokenContract = RewardToken(_rewardToken);
    }

    /// @notice Claim rewards for a staked NFT.
    /// @param tokenId The ID of the staked NFT.
    /// @dev Reverts if the reward duration has not passed or if the caller is not the depositor.
    function claimReward(uint256 tokenId) external {
        DepositEntry memory deposit = deposits[tokenId];

        if (deposit.timestamp == 0) {
            revert RewardDurationHasNotPassed();
        }

        if (deposit.user != msg.sender) {
            revert OnlyDepositorCanWithdraw();
        }

        uint256 rewardsAmount = ((block.timestamp - deposit.timestamp) * REWARD_AMOUNT) / REWARD_DURATION;

        deposits[tokenId].timestamp = block.timestamp;
        rewardTokenContract.mint(msg.sender, rewardsAmount);

        emit RewardDistributed(tokenId, deposit.user, rewardsAmount);
    }

    /// @notice Withdraw a staked NFT.
    /// @param tokenId The ID of the staked NFT.
    /// @dev Reverts if the caller is not the depositor. Distributes any pending rewards.
    function withdrawNFT(uint256 tokenId) external {
        DepositEntry memory deposit = deposits[tokenId];
        if (deposit.user != msg.sender) {
            revert OnlyDepositorCanWithdraw();
        }
        delete deposits[tokenId];
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NFTWithdrawn(tokenId, msg.sender);

        if (deposit.timestamp > 0) {
            uint256 rewardsAmount = ((block.timestamp - deposit.timestamp) * REWARD_AMOUNT) / REWARD_DURATION;
            if (rewardsAmount > 0) {
                rewardTokenContract.mint(deposit.user, rewardsAmount);
                emit RewardDistributed(tokenId, deposit.user, rewardsAmount);
            }
        }
    }

    /// @notice Handle the receipt of an NFT.
    /// @param from The address which previously owned the token.
    /// @param tokenId The ID of the token being transferred.
    /// @return The selector of this function.
    /// @dev Reverts if the sender is not the NFT contract.
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external returns (bytes4) {
        if (msg.sender != address(nftContract)) {
            revert OnlyNFTContractCanDeposit();
        }

        deposits[tokenId] = DepositEntry({user: from, timestamp: block.timestamp});

        return this.onERC721Received.selector;
    }
}
