// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {TrioNFTStaking} from "../src/TrioNFTStaking.sol";
import {TrioNFT} from "../src/TrioNFT.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {Merkle} from "@murky/Merkle.sol";

contract TrioTest is Test {
    TrioNFT public trio;
    TrioNFTStaking public nftStaking;
    RewardToken public rewardToken;

    bytes32 public merkleRoot;

    address internal deployer;
    address internal user1;
    address internal user2;
    address internal user3;
    address internal user4;
    address internal user5;

    bytes32[] internal leaves;

    Merkle public merkleTree;

    function setUp() public {
        deployer = address(this);
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        user3 = vm.addr(3);
        user4 = vm.addr(4);
        user5 = vm.addr(5);

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
        vm.deal(user5, 100 ether);

        merkleTree = new Merkle();

        leaves = [
            keccak256(abi.encode(user1, 0)),
            keccak256(abi.encode(user2, 1)),
            keccak256(abi.encode(user3, 2)),
            keccak256(abi.encode(user4, 3))
        ];

        bytes32 root = merkleTree.getRoot(leaves);

        trio = new TrioNFT(root);
        rewardToken = new RewardToken();
        nftStaking = new TrioNFTStaking(address(trio), address(rewardToken));
        rewardToken.setNFTContract(address(nftStaking));
    }

    function testMint() public {
        uint256 initialBalance = address(this).balance;
        uint256 mintPrice = trio.MINT_PRICE();

        trio.mint{value: mintPrice}();

        assertEq(trio.balanceOf(address(this)), 1);
        assertEq(address(this).balance, initialBalance - mintPrice);
    }

    function testMint_InsufficientBalance() public {
        uint256 mintPrice = trio.MINT_PRICE();

        vm.expectRevert(TrioNFT.InsufficientBalance.selector);
        trio.mint{value: mintPrice - 1}();
    }

    function test_MintWithDiscount() public {
        assertEq(trio.isNftClaimed(1), false);
        bytes32[] memory proofs = merkleTree.getProof(leaves, 1);
        vm.startPrank(user2);
        trio.mintWithDiscount{value: 0.007 ether}(proofs, 1);

        assertEq(trio.balanceOf(user2), 1);
        vm.stopPrank();
    }

    function test_MintWithDiscount_InvalidUser() public {
        bytes32[] memory proofs = merkleTree.getProof(leaves, 1);
        vm.startPrank(user5);
        vm.expectRevert(TrioNFT.InvalidProof.selector);
        trio.mintWithDiscount{value: 0.007 ether}(proofs, 1);
        vm.stopPrank();
    }

    function test_MintWithDiscount_MultipleMint() public {
        bytes32[] memory proofs = merkleTree.getProof(leaves, 1);
        vm.startPrank(user2);
        trio.mintWithDiscount{value: 0.007 ether}(proofs, 1);
        vm.expectRevert(TrioNFT.AlreadyMintedWithDiscountPrice.selector);
        trio.mintWithDiscount{value: 0.007 ether}(proofs, 1);
        vm.stopPrank();
    }

    function test_MintWithDiscountInsufficientBalance() public {
        bytes32[] memory proofs = merkleTree.getProof(leaves, 1);
        vm.startPrank(user2);
        vm.expectRevert(TrioNFT.InsufficientBalance.selector);
        trio.mintWithDiscount{value: 0.005 ether}(proofs, 1);
        vm.stopPrank();
    }

    function test_StakingDeposit() public {
        uint256 tokenId = 1;
        uint256 mintPrice = trio.MINT_PRICE();
        vm.startPrank(user1);
        trio.mint{value: mintPrice}();
        trio.safeTransferFrom(user1, address(nftStaking), tokenId);
        (address depositor,) = nftStaking.deposits(tokenId);
        assertEq(depositor, user1);
        vm.stopPrank();
    }

    function test_StakingWithdraw() public {
        uint256 tokenId = 1;
        vm.startPrank(user1);
        trio.mint{value: trio.MINT_PRICE()}();
        trio.safeTransferFrom(user1, address(nftStaking), tokenId);
        nftStaking.withdrawNFT(tokenId);
        (address depositor,) = nftStaking.deposits(tokenId);
        assertEq(depositor, address(0));
        vm.stopPrank();
    }

    function test_RewardDistribution() public {
        vm.startPrank(user1);
        trio.mint{value: trio.MINT_PRICE()}();
        trio.safeTransferFrom(user1, address(nftStaking), 1);
        vm.warp(block.timestamp + 1 days);
        nftStaking.claimReward(1);
        (address user, uint256 timestamp) = nftStaking.deposits(1);
        assertEq(rewardToken.balanceOf(user1), 10 ether);
        assertEq(timestamp, block.timestamp);
        assertEq(user, user1);
        vm.warp(block.timestamp + 2 days);
        nftStaking.claimReward(1);
        assertEq(rewardToken.balanceOf(user1), 30 ether);
        vm.stopPrank();
    }

    function test_RewardTokenOwnershipTransfer() public {
        address newOwner = address(0x123);

        assertEq(rewardToken.owner(), address(this));

        rewardToken.transferOwnership(newOwner);

        assertEq(rewardToken.pendingOwner(), newOwner);

        vm.startPrank(newOwner);
        rewardToken.acceptOwnership();

        assertEq(rewardToken.owner(), newOwner);

        TrioNFTStaking newNftStaking = new TrioNFTStaking(address(trio), address(rewardToken));

        rewardToken.setNFTContract(address(newNftStaking));
        assertEq(address(rewardToken.nftContract()), address(newNftStaking));
    }
}
