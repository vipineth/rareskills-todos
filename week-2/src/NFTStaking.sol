// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {RewardToken} from "./RewardToken.sol";

contract NFTStaking is IERC721Receiver {
    uint256 public constant REWARD_DURATION = 24 hours;
    uint256 public constant REWARD_AMOUNT = 10 ether;

    struct Deposit {
        address depositor;
        uint256 depositedAt;
    }

    IERC721 public nftContract;
    RewardToken public rewardToken;
    mapping(uint256 => Deposit) public deposits;

    error OnlyNFTContractCanDeposit();
    error OnlyDepositorCanWithdraw();
    error RewardDurationHasNotPassed();

    event NFTStaked(
        uint256 indexed tokenId,
        address depositor,
        uint256 depositedAt
    );
    event NFTWithdrawn(
        uint256 indexed tokenId,
        address depositor,
        uint256 depositedAt
    );
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
        uint256 daysPassed = _getDaysPassed(tokenId);

        require(daysPassed > 0, RewardDurationHasNotPassed());

        uint256 totalRewardAmount = REWARD_AMOUNT * daysPassed;
        Deposit memory deposit = deposits[tokenId];
        rewardToken.mint(deposit.depositor, totalRewardAmount);
        emit RewardDistributed(tokenId, deposit.depositor, totalRewardAmount);
    }

    function withdrawNFT(uint256 tokenId) external {
        Deposit memory deposit = deposits[tokenId];
        require(deposit.depositor == msg.sender, OnlyDepositorCanWithdraw());
        delete deposits[tokenId];
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NFTWithdrawn(tokenId, msg.sender, deposits[tokenId].depositedAt);

        handleReward(tokenId);
    }

    function _getDaysPassed(uint256 tokenId) internal view returns (uint256) {
        Deposit memory deposit = deposits[tokenId];
        return (block.timestamp - deposit.depositedAt) / 1 days;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        require(
            msg.sender == address(nftContract),
            OnlyNFTContractCanDeposit()
        );
        deposits[tokenId] = Deposit({
            depositor: from,
            depositedAt: block.timestamp
        });
        return this.onERC721Received.selector;
    }
}
