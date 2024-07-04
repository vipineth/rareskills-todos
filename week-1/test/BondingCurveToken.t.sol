// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurveToken} from "../src/BondingCurveToken.sol";
import {CappedGasFee} from "../src/CappedGasFee.sol";

contract BondingCurveTokenTest is Test {
    BondingCurveToken public bondingCurveToken;
    CappedGasFee public cappedGasFee;
    address deployer;
    address user1;
    address user2;

    function setUp() public {
        deployer = address(this);
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        bondingCurveToken = new BondingCurveToken();
        cappedGasFee = new CappedGasFee();
    }

    function testMint() public {
        uint256 mintAmount = 4.5 ether;
        uint256 expectedPrice = bondingCurveToken.priceToMint(mintAmount);
        vm.deal(deployer, expectedPrice);
        bondingCurveToken.mint{value: expectedPrice}(mintAmount);
        assertEq(
            bondingCurveToken.balanceOf(deployer), 4.5 ether, "Deployer should have 2 ether of tokens after minting"
        );
        assertEq(bondingCurveToken.reserveTokenBalance(), expectedPrice, "Reserve balance should match the mint price");
    }

    function testRedeem() public {
        uint256 mintAmount = 4.5 ether;
        uint256 mintPrice = bondingCurveToken.priceToMint(mintAmount);
        vm.deal(user1, mintPrice);
        vm.startPrank(user1);
        bondingCurveToken.mint{value: mintPrice}(mintAmount);
        uint256 redeemAmount = 2 ether;
        bondingCurveToken.redeem(redeemAmount);
        assertEq(bondingCurveToken.balanceOf(user1), 2.5 ether, "User1 should have 2.5 ether of tokens after redeeming");
        vm.stopPrank();
    }

    function testMintInsufficientFunds() public {
        uint256 mintAmount = 10 ether;
        vm.deal(user1, 10000);
        vm.startPrank(user1);
        vm.expectRevert(BondingCurveToken.InsufficientFunds.selector);
        bondingCurveToken.mint{value: 100}(mintAmount);
        vm.stopPrank();
    }

    function testRedeemZero() public {
        vm.expectRevert(BondingCurveToken.ZeroAmountNotAllowed.selector);
        vm.startPrank(user1);
        bondingCurveToken.redeem(0);
        vm.stopPrank();
    }

    function testCappedGasFee() public {
        uint256 mintAmount = 10 ether;
        uint256 mintPrice = bondingCurveToken.priceToMint(mintAmount);
        vm.deal(user1, mintPrice);
        vm.startPrank(user1);
        vm.txGasPrice(32000000000); // 32 gwai
        vm.expectRevert(CappedGasFee.MaxGasFeeExceeded.selector);
        bondingCurveToken.mint{value: mintPrice}(mintAmount);
        vm.stopPrank();
    }

    function testMintWithZeroAmount() public {
        vm.expectRevert(BondingCurveToken.ZeroAmountNotAllowed.selector);
        bondingCurveToken.mint{value: 0}(0);
    }

    function testRedeemWithInsufficientBalance() public {
        uint256 mintAmount = 2 ether;
        uint256 mintPrice = bondingCurveToken.priceToMint(mintAmount);
        vm.deal(user1, mintPrice);
        vm.startPrank(user1);
        bondingCurveToken.mint{value: mintPrice}(mintAmount);
        vm.expectRevert(BondingCurveToken.InsufficientBalance.selector);
        bondingCurveToken.redeem(3 ether);
        vm.stopPrank();
    }

    function testMintWithExcessEther() public {
        uint256 mintAmount = 2 ether;
        uint256 mintPrice = bondingCurveToken.priceToMint(mintAmount);
        uint256 excessEther = 1 ether;
        vm.deal(user1, mintPrice + excessEther);
        vm.startPrank(user1);
        bondingCurveToken.mint{value: mintPrice + excessEther}(mintAmount);
        assertEq(bondingCurveToken.balanceOf(user1), mintAmount, "User1 should have the minted amount of tokens");
        assertEq(bondingCurveToken.reserveTokenBalance(), mintPrice, "Reserve balance should match the mint price");
        vm.stopPrank();
    }
}
