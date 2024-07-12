// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {RewardToken} from "./RewardToken.sol";

contract NFTStaking is IERC721Receiver {
    uint256 public constant REWARD_DURATION = 24 hours;
    uint256 public constant REWARD_AMOUNT = 10 ether;

    struct DepositEntry {
        address user;
        uint256 timestamp;
    }

    IERC721 public nftContract;
    RewardToken public rewardToken;
    mapping(uint256 => DepositEntry) public deposits;

    error OnlyNFTContractCanDeposit();
    error OnlyDepositorCanWithdraw();
    error RewardDurationHasNotPassed();

    event NFTStaked(uint256 indexed tokenId, address user);
    event NFTWithdrawn(uint256 indexed tokenId, address user);

    event RewardDistributed(
        uint256 indexed tokenId,
        address depositor,
        uint256 amount
    );

    constructor(address _nftContract, address _rewardToken) {
        nftContract = IERC721(_nftContract);
        rewardToken = RewardToken(_rewardToken);
    }

    function handleReward(uint256 tokenId) internal {
        DepositEntry memory deposit = deposits[tokenId];

        if (deposit.timestamp == 0) {
            revert RewardDurationHasNotPassed();
        }

        uint256 rewardsAmount = ((block.timestamp - deposit.timestamp) *
            REWARD_AMOUNT) / REWARD_DURATION;

        deposit.timestamp = block.timestamp;
        rewardToken.mint(deposit.user, rewardsAmount);

        emit RewardDistributed(tokenId, deposit.user, rewardsAmount);
    }

    function withdrawNFT(uint256 tokenId) external {
        DepositEntry memory deposit = deposits[tokenId];
        if (deposit.user != msg.sender) {
            revert OnlyDepositorCanWithdraw();
        }
        delete deposits[tokenId];
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NFTWithdrawn(tokenId, msg.sender);

        if (deposit.timestamp > 0) {
            uint256 rewardsAmount = ((block.timestamp - deposit.timestamp) *
                REWARD_AMOUNT) / REWARD_DURATION;
            if (rewardsAmount > 0) {
                rewardToken.mint(deposit.user, rewardsAmount);
                emit RewardDistributed(tokenId, deposit.user, rewardsAmount);
            }
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        if (msg.sender != address(nftContract)) {
            revert OnlyNFTContractCanDeposit();
        }

        deposits[tokenId] = DepositEntry({
            user: from,
            timestamp: block.timestamp
        });

        return this.onERC721Received.selector;
    }
}
