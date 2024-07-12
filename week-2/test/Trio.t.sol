// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Trio} from "../src/Trio.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract TrioTest is Test {
    Trio public trio;
    NFTStaking public nftStaking;
    RewardToken public rewardToken;

    function setUp() public {
        trio = new Trio();
        rewardToken = new RewardToken(address(trio));
        nftStaking = new NFTStaking(address(trio), address(rewardToken));
    }

    function testMint() public {
        uint256 initialBalance = address(this).balance;
        uint256 mintPrice = trio.MINT_PRICE();

        trio.mint{value: mintPrice}();

        assertEq(trio.balanceOf(address(this)), 1);
        assertEq(address(this).balance, initialBalance - mintPrice);
    }
}
