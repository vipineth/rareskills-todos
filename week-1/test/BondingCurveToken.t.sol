// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {BondingCurveToken} from "../src/BondingCurveToken.sol";

contract BondingCurveTokenTest is Test {
    BondingCurveToken public bondingCurveToken;
    address deployer;

    function setUp() public {
        deployer = address(this);
        bondingCurveToken = new BondingCurveToken();
    }

    function testMint() public {
        uint256 mintAmount = 1 ether;
        uint256 expectedPrice = bondingCurveToken.priceToMint(mintAmount);
        vm.deal(deployer, expectedPrice);
        bondingCurveToken.mint{value: expectedPrice}(mintAmount);
        assertEq(
            bondingCurveToken.balanceOf(deployer),
            2 ether,
            "Deployer should have 2 ether of tokens after minting"
        );
        assertEq(
            bondingCurveToken.reserveTokenBalance(),
            expectedPrice,
            "Reserve balance should match the mint price"
        );
    }

    function testFailMintWithInsufficientFunds() public {
        uint256 mintAmount = 1 ether;
        uint256 insufficientFunds = bondingCurveToken.priceToMint(mintAmount) -
            1;
        vm.expectRevert(BondingCurveToken.InsufficientFunds.selector);
        bondingCurveToken.mint{value: insufficientFunds}(mintAmount);
    }

    function testRedeem() public {
        uint256 mintAmount = 2 ether;
        uint256 redeemAmount = 0.5 ether;
        uint256 mintPrice = bondingCurveToken.priceToMint(mintAmount);
        vm.deal(deployer, mintPrice);
        bondingCurveToken.mint{value: mintPrice}(mintAmount);

        // uint256 redeemPrice = bondingCurveToken.priceToRedeem(redeemAmount);
        // console.log(
        //     "%s:%s:%s",
        //     bondingCurveToken.totalSupply(),
        //     bondingCurveToken.reserveTokenBalance(),
        //     redeemPrice
        // );

        // console.log(
        //     "%s:%s",
        //     bondingCurveToken.balanceOf(deployer),
        //     redeemAmount
        // );
        bondingCurveToken.redeem(redeemAmount);

        assertEq(
            bondingCurveToken.balanceOf(deployer),
            2.5 ether,
            "Deployer should have 2.5 ether of tokens after redeeming"
        );
    }
}
