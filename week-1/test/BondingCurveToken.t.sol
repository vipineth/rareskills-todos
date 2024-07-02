// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurveToken} from "../src/BondingCurveToken.sol";

contract BondingCurveTokenTest is Test {
    BondingCurveToken public bondingCurveToken;
    address deployer;
    address user1;
    address user2;

    function setUp() public {
        deployer = address(this);
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        bondingCurveToken = new BondingCurveToken();
    }

    function testMint() public {
        uint256 mintAmount = 4.5 ether;
        uint256 expectedPrice = bondingCurveToken.priceToMint(mintAmount);
        vm.deal(deployer, expectedPrice);
        bondingCurveToken.mint{value: expectedPrice}(mintAmount);
        assertEq(
            bondingCurveToken.balanceOf(deployer),
            4.5 ether,
            "Deployer should have 2 ether of tokens after minting"
        );
        assertEq(
            bondingCurveToken.reserveTokenBalance(),
            expectedPrice,
            "Reserve balance should match the mint price"
        );
    }

    function testRedeem() public {
        uint256 mintAmount = 4.5 ether;
        uint256 mintPrice = bondingCurveToken.priceToMint(mintAmount);
        vm.deal(user1, mintPrice);
        vm.startPrank(user1);
        bondingCurveToken.mint{value: mintPrice}(mintAmount);
        uint256 redeemAmount = 2 ether;
        bondingCurveToken.redeem(redeemAmount);
        assertEq(
            bondingCurveToken.balanceOf(user1),
            2.5 ether,
            "User1 should have 2.5 ether of tokens after redeeming"
        );
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
}
